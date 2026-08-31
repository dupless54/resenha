export const CONNECTION_QUALITY_UNKNOWN = "unknown";
export const CONNECTION_QUALITY_GOOD = "good";
export const CONNECTION_QUALITY_FAIR = "fair";
export const CONNECTION_QUALITY_POOR = "poor";
export const CONNECTION_STATUS_RECONNECTING = "reconnecting";

const DEFAULT_INTERVAL_MS = 5000;

const FAIR_THRESHOLDS = {
  packetLossPercent: 2,
  jitterMs: 30,
  roundTripTimeMs: 250,
};

const POOR_THRESHOLDS = {
  packetLossPercent: 5,
  jitterMs: 50,
  roundTripTimeMs: 500,
};

const QUALITY_RANK = {
  [CONNECTION_QUALITY_GOOD]: 0,
  [CONNECTION_QUALITY_FAIR]: 1,
  [CONNECTION_QUALITY_POOR]: 2,
};

function finiteNumber(value) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function mediaKind(report) {
  return report?.kind ?? report?.mediaType;
}

function maxDefined(values) {
  const defined = values.filter((value) => value !== null);
  return defined.length ? Math.max(...defined) : null;
}

function reportsFrom(stats) {
  const reports = [];
  stats?.forEach?.((report) => reports.push(report));
  return reports;
}

function selectedRoundTripTimeMs(reports) {
  const byId = new Map(reports.map((report) => [report.id, report]));
  const transport = reports.find(
    (report) => report.type === "transport" && report.selectedCandidatePairId
  );
  const selectedPair = transport
    ? byId.get(transport.selectedCandidatePairId)
    : (reports.find(
        (report) =>
          report.type === "candidate-pair" &&
          report.state === "succeeded" &&
          (report.nominated === true || report.selected === true)
      ) ??
      reports.find(
        (report) =>
          report.type === "candidate-pair" && report.state === "succeeded"
      ));

  const candidateRtt = finiteNumber(selectedPair?.currentRoundTripTime);
  const remoteAudioRtts = reports
    .filter(
      (report) =>
        report.type === "remote-inbound-rtp" && mediaKind(report) === "audio"
    )
    .map((report) => finiteNumber(report.roundTripTime));

  const roundTripTimeSeconds = maxDefined([candidateRtt, ...remoteAudioRtts]);
  return roundTripTimeSeconds === null ? null : roundTripTimeSeconds * 1000;
}

export function audioConnectionMetrics(stats, previousInbound = new Map()) {
  const reports = reportsFrom(stats);
  const jitterValues = [];
  const lossPercentages = [];

  for (const report of reports) {
    if (report.type !== "inbound-rtp" || mediaKind(report) !== "audio") {
      continue;
    }

    const jitter = finiteNumber(report.jitter);
    if (jitter !== null) {
      jitterValues.push(jitter * 1000);
    }

    const packetsReceived = finiteNumber(report.packetsReceived);
    const packetsLost = finiteNumber(report.packetsLost);
    const previous = previousInbound.get(report.id);

    if (packetsReceived !== null && packetsLost !== null) {
      if (previous) {
        const receivedDelta = Math.max(
          0,
          packetsReceived - previous.packetsReceived
        );
        // packetsLost is cumulative and may legally be negative. Only new
        // losses between two samples contribute to the interval percentage.
        const lostDelta = Math.max(0, packetsLost - previous.packetsLost);
        const expectedDelta = receivedDelta + lostDelta;
        if (expectedDelta > 0) {
          lossPercentages.push((lostDelta / expectedDelta) * 100);
        }
      }

      previousInbound.set(report.id, { packetsReceived, packetsLost });
    }
  }

  return {
    packetLossPercent: maxDefined(lossPercentages),
    jitterMs: maxDefined(jitterValues),
    roundTripTimeMs: selectedRoundTripTimeMs(reports),
  };
}

export function classifyConnectionQuality({
  connectionState,
  packetLossPercent = null,
  jitterMs = null,
  roundTripTimeMs = null,
}) {
  if (connectionState === "failed" || connectionState === "disconnected") {
    return CONNECTION_QUALITY_POOR;
  }

  if (connectionState !== "connected") {
    return CONNECTION_QUALITY_UNKNOWN;
  }

  const metrics = { packetLossPercent, jitterMs, roundTripTimeMs };
  if (Object.values(metrics).every((value) => value === null)) {
    return CONNECTION_QUALITY_UNKNOWN;
  }

  if (
    (packetLossPercent !== null &&
      packetLossPercent >= POOR_THRESHOLDS.packetLossPercent) ||
    (jitterMs !== null && jitterMs >= POOR_THRESHOLDS.jitterMs) ||
    (roundTripTimeMs !== null &&
      roundTripTimeMs >= POOR_THRESHOLDS.roundTripTimeMs)
  ) {
    return CONNECTION_QUALITY_POOR;
  }

  if (
    (packetLossPercent !== null &&
      packetLossPercent >= FAIR_THRESHOLDS.packetLossPercent) ||
    (jitterMs !== null && jitterMs >= FAIR_THRESHOLDS.jitterMs) ||
    (roundTripTimeMs !== null &&
      roundTripTimeMs >= FAIR_THRESHOLDS.roundTripTimeMs)
  ) {
    return CONNECTION_QUALITY_FAIR;
  }

  return CONNECTION_QUALITY_GOOD;
}

export function aggregateConnectionQuality(qualities) {
  const known = qualities.filter(
    (quality) => quality !== CONNECTION_QUALITY_UNKNOWN
  );
  if (!known.length) {
    return CONNECTION_QUALITY_UNKNOWN;
  }

  return known.reduce((worst, quality) =>
    QUALITY_RANK[quality] > QUALITY_RANK[worst] ? quality : worst
  );
}

export async function samplePeerConnectionQuality(
  peerConnection,
  previousInbound = new Map()
) {
  const connectionState = peerConnection?.connectionState;
  if (connectionState === "failed" || connectionState === "disconnected") {
    return CONNECTION_QUALITY_POOR;
  }
  if (connectionState !== "connected" || !peerConnection?.getStats) {
    return CONNECTION_QUALITY_UNKNOWN;
  }

  const stats = await peerConnection.getStats();
  return classifyConnectionQuality({
    connectionState,
    ...audioConnectionMetrics(stats, previousInbound),
  });
}

export class MeshConnectionQualityRegistry {
  #intervalMs;
  #peers = new Map();
  #qualities = new Map();
  #reconnectingPeers = new Map();
  #timers = new Map();
  #sampleTokens = new Map();
  #previousInbound = new WeakMap();
  #listeners = new Set();

  constructor({ intervalMs = DEFAULT_INTERVAL_MS } = {}) {
    this.#intervalMs = intervalMs;
  }

  subscribe(listener) {
    this.#listeners.add(listener);
    return () => this.#listeners.delete(listener);
  }

  qualityFor(roomId) {
    return this.#qualities.get(Number(roomId)) ?? null;
  }

  stateFor(roomId) {
    const id = Number(roomId);
    if (this.#reconnectingPeers.get(id)?.size) {
      return CONNECTION_STATUS_RECONNECTING;
    }
    return this.qualityFor(id);
  }

  markReconnecting(roomId, remoteUserId) {
    const id = Number(roomId);
    const userId = Number(remoteUserId);
    if (!id || !userId) {
      return;
    }

    let peers = this.#reconnectingPeers.get(id);
    if (!peers) {
      peers = new Set();
      this.#reconnectingPeers.set(id, peers);
    }
    if (peers.has(userId)) {
      return;
    }

    peers.add(userId);
    this.#notify(id);
  }

  clearReconnecting(roomId, remoteUserId) {
    const id = Number(roomId);
    const peers = this.#reconnectingPeers.get(id);
    if (!peers?.delete(Number(remoteUserId))) {
      return;
    }

    if (!peers.size) {
      this.#reconnectingPeers.delete(id);
    }
    this.#notify(id);
  }

  registerPeer(roomId, remoteUserId, peerConnection) {
    const id = Number(roomId);
    if (!id || !peerConnection) {
      return;
    }

    this.#invalidateSamples(id);
    let peers = this.#peers.get(id);
    if (!peers) {
      peers = new Map();
      this.#peers.set(id, peers);
    }
    peers.set(Number(remoteUserId), peerConnection);

    if (!this.#timers.has(id)) {
      this.#timers.set(
        id,
        setInterval(() => void this.sample(id), this.#intervalMs)
      );
    }
    void this.sample(id);
  }

  unregisterPeer(roomId, remoteUserId, peerConnection = null) {
    const id = Number(roomId);
    const peers = this.#peers.get(id);
    const userId = Number(remoteUserId);
    const registered = peers?.get(userId);

    if (!registered || (peerConnection && registered !== peerConnection)) {
      return;
    }

    this.#invalidateSamples(id);
    peers.delete(userId);
    if (peers.size) {
      void this.sample(id);
      return;
    }

    this.#peers.delete(id);
    const timer = this.#timers.get(id);
    if (timer) {
      clearInterval(timer);
      this.#timers.delete(id);
    }
    this.#setQuality(id, null);
  }

  async sample(roomId) {
    const id = Number(roomId);
    const peers = this.#peers.get(id);
    if (!peers?.size) {
      this.#setQuality(id, null);
      return null;
    }

    const sampleToken = this.#nextSampleToken(id);
    const qualities = [];
    for (const pc of peers.values()) {
      let previousInbound = this.#previousInbound.get(pc);
      if (!previousInbound) {
        previousInbound = new Map();
        this.#previousInbound.set(pc, previousInbound);
      }

      try {
        qualities.push(await samplePeerConnectionQuality(pc, previousInbound));
      } catch {
        qualities.push(CONNECTION_QUALITY_UNKNOWN);
      }
    }

    if (this.#sampleTokens.get(id) !== sampleToken) {
      return this.qualityFor(id);
    }

    const quality = aggregateConnectionQuality(qualities);
    this.#setQuality(id, quality);
    return quality;
  }

  resetForTesting() {
    for (const timer of this.#timers.values()) {
      clearInterval(timer);
    }
    this.#timers.clear();
    this.#peers.clear();
    this.#qualities.clear();
    this.#reconnectingPeers.clear();
    this.#sampleTokens.clear();
    this.#previousInbound = new WeakMap();
  }

  #invalidateSamples(roomId) {
    this.#nextSampleToken(roomId);
  }

  #nextSampleToken(roomId) {
    const token = (this.#sampleTokens.get(roomId) ?? 0) + 1;
    this.#sampleTokens.set(roomId, token);
    return token;
  }

  #setQuality(roomId, quality) {
    const previous = this.#qualities.get(roomId) ?? null;
    if (previous === quality) {
      return;
    }

    if (quality === null) {
      this.#qualities.delete(roomId);
    } else {
      this.#qualities.set(roomId, quality);
    }

    this.#notify(roomId);
  }

  #notify(roomId) {
    const state = this.stateFor(roomId);
    for (const listener of this.#listeners) {
      listener(roomId, state);
    }
  }
}

export const meshConnectionQuality = new MeshConnectionQualityRegistry();
