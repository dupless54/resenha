import { module, test } from "qunit";
import {
  aggregateConnectionQuality,
  audioConnectionMetrics,
  classifyConnectionQuality,
  CONNECTION_QUALITY_FAIR,
  CONNECTION_QUALITY_GOOD,
  CONNECTION_QUALITY_POOR,
  CONNECTION_QUALITY_UNKNOWN,
  MeshConnectionQualityRegistry,
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

  test("registry follows peer lifecycle and reports the worst peer", async function (assert) {
    const registry = new MeshConnectionQualityRegistry({ intervalMs: 60_000 });
    const changes = [];
    registry.subscribe((roomId, quality) => changes.push([roomId, quality]));

    const goodPeer = {
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
    };
    const poorPeer = { connectionState: "disconnected" };

    registry.registerPeer(7, 2, goodPeer);
    registry.registerPeer(7, 3, poorPeer);
    await registry.sample(7);

    assert.strictEqual(registry.qualityFor(7), CONNECTION_QUALITY_POOR);
    assert.deepEqual(changes.at(-1), [7, CONNECTION_QUALITY_POOR]);

    registry.unregisterPeer(7, 3, poorPeer);
    await registry.sample(7);
    assert.strictEqual(registry.qualityFor(7), CONNECTION_QUALITY_GOOD);

    registry.unregisterPeer(7, 2, goodPeer);
    assert.strictEqual(registry.qualityFor(7), null, "hides when alone");

    registry.resetForTesting();
  });

  test("discarded async samples cannot resurrect quality after the last peer leaves", async function (assert) {
    const registry = new MeshConnectionQualityRegistry({ intervalMs: 60_000 });
    let resolveStats;
    const pendingStats = new Promise((resolve) => {
      resolveStats = resolve;
    });
    const peer = {
      connectionState: "connected",
      getStats() {
        return pendingStats;
      },
    };

    registry.registerPeer(11, 22, peer);
    registry.unregisterPeer(11, 22, peer);

    resolveStats(
      statsReport([
        {
          id: "audio-stale",
          type: "inbound-rtp",
          kind: "audio",
          packetsReceived: 20,
          packetsLost: 0,
          jitter: 0.005,
        },
      ])
    );
    await pendingStats;
    await Promise.resolve();

    assert.strictEqual(
      registry.qualityFor(11),
      null,
      "stale getStats result stays invalid after teardown"
    );

    registry.resetForTesting();
  });
});
