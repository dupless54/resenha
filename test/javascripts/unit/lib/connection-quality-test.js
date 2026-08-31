import { module, test } from "qunit";
import ConnectionQualityMonitor, {
  aggregateConnectionQuality,
  audioConnectionMetrics,
  classifyConnectionQuality,
  CONNECTION_QUALITY_FAIR,
  CONNECTION_QUALITY_GOOD,
  CONNECTION_QUALITY_POOR,
  CONNECTION_QUALITY_UNKNOWN,
  samplePeerConnectionQuality,
} from "discourse/plugins/resenha/discourse/lib/resenha/connection-quality";

function statsReport(entries) {
  return new Map(entries.map((entry) => [entry.id, entry]));
}

module("Resenha | Unit | Lib | connection-quality", function () {
  test("computes packet loss from deltas and converts jitter and RTT to milliseconds", function (assert) {
    const previous = new Map();
    const first = statsReport([
      {
        id: "audio-1",
        type: "inbound-rtp",
        kind: "audio",
        packetsReceived: 100,
        packetsLost: -1,
        jitter: 0.012,
      },
      {
        id: "transport-1",
        type: "transport",
        selectedCandidatePairId: "pair-1",
      },
      {
        id: "pair-1",
        type: "candidate-pair",
        state: "succeeded",
        nominated: true,
        currentRoundTripTime: 0.14,
      },
    ]);

    assert.deepEqual(audioConnectionMetrics(first, previous), {
      packetLossPercent: null,
      jitterMs: 12,
      roundTripTimeMs: 140,
    });

    const second = statsReport([
      {
        id: "audio-1",
        type: "inbound-rtp",
        kind: "audio",
        packetsReceived: 119,
        packetsLost: 0,
        jitter: 0.018,
      },
      {
        id: "transport-1",
        type: "transport",
        selectedCandidatePairId: "pair-1",
      },
      {
        id: "pair-1",
        type: "candidate-pair",
        state: "succeeded",
        nominated: true,
        currentRoundTripTime: 0.22,
      },
    ]);

    assert.deepEqual(audioConnectionMetrics(second, previous), {
      packetLossPercent: 5,
      jitterMs: 18,
      roundTripTimeMs: 220,
    });
  });

  test("classifies connected peers with conservative thresholds", function (assert) {
    assert.strictEqual(
      classifyConnectionQuality({
        connectionState: "connected",
        packetLossPercent: 0.5,
        jitterMs: 12,
        roundTripTimeMs: 110,
      }),
      CONNECTION_QUALITY_GOOD
    );
    assert.strictEqual(
      classifyConnectionQuality({
        connectionState: "connected",
        packetLossPercent: 2,
        jitterMs: 12,
        roundTripTimeMs: 110,
      }),
      CONNECTION_QUALITY_FAIR
    );
    assert.strictEqual(
      classifyConnectionQuality({
        connectionState: "connected",
        packetLossPercent: 1,
        jitterMs: 50,
        roundTripTimeMs: 110,
      }),
      CONNECTION_QUALITY_POOR
    );
    assert.strictEqual(
      classifyConnectionQuality({ connectionState: "connected" }),
      CONNECTION_QUALITY_UNKNOWN,
      "does not claim a healthy connection without metrics"
    );
    assert.strictEqual(
      classifyConnectionQuality({ connectionState: "disconnected" }),
      CONNECTION_QUALITY_POOR,
      "a disconnected peer is poor even before stats are available"
    );
  });

  test("aggregates the worst known peer without letting unsupported stats mask useful peers", function (assert) {
    assert.strictEqual(
      aggregateConnectionQuality([
        CONNECTION_QUALITY_GOOD,
        CONNECTION_QUALITY_UNKNOWN,
        CONNECTION_QUALITY_FAIR,
      ]),
      CONNECTION_QUALITY_FAIR
    );
    assert.strictEqual(
      aggregateConnectionQuality([
        CONNECTION_QUALITY_GOOD,
        CONNECTION_QUALITY_POOR,
      ]),
      CONNECTION_QUALITY_POOR
    );
    assert.strictEqual(
      aggregateConnectionQuality([CONNECTION_QUALITY_UNKNOWN]),
      CONNECTION_QUALITY_UNKNOWN
    );
  });

  test("falls back to remote inbound audio RTT when candidate-pair RTT is unavailable", async function (assert) {
    const pc = {
      connectionState: "connected",
      async getStats() {
        return statsReport([
          {
            id: "remote-audio",
            type: "remote-inbound-rtp",
            kind: "audio",
            roundTripTime: 0.3,
          },
        ]);
      },
    };

    assert.strictEqual(
      await samplePeerConnectionQuality(pc),
      CONNECTION_QUALITY_FAIR
    );
  });

  test("monitor is local-only, hides when alone, and reports the worst peer", async function (assert) {
    const peers = new Map();
    const changes = [];
    const monitor = new ConnectionQualityMonitor({
      peerManager: { getRoomPeers: () => peers },
      onChange: (roomId, quality) => changes.push([roomId, quality]),
    });

    assert.strictEqual(await monitor.sample(7), null, "no badge while alone");

    peers.set(2, {
      connectionState: "connected",
      async getStats() {
        return statsReport([
          {
            id: "audio-good",
            type: "inbound-rtp",
            kind: "audio",
            packetsReceived: 10,
            packetsLost: 0,
            jitter: 0.01,
          },
          {
            id: "pair-good",
            type: "candidate-pair",
            state: "succeeded",
            nominated: true,
            currentRoundTripTime: 0.1,
          },
        ]);
      },
    });
    peers.set(3, { connectionState: "disconnected" });

    assert.strictEqual(await monitor.sample(7), CONNECTION_QUALITY_POOR);
    assert.strictEqual(monitor.qualityFor(7), CONNECTION_QUALITY_POOR);
    assert.deepEqual(changes.at(-1), [7, CONNECTION_QUALITY_POOR]);

    monitor.stop(7);
    assert.strictEqual(monitor.qualityFor(7), null);
  });
});
