import { module, test } from "qunit";
import { meshConnectionQuality } from "discourse/plugins/resenha/discourse/lib/resenha/connection-quality";
import PeerManager from "discourse/plugins/resenha/discourse/lib/resenha/peer-manager";

class FakeRTCPeerConnection {
  signalingState = "stable";
  connectionState = "new";
  iceConnectionState = "new";
  iceGatheringState = "new";
  localDescription = null;
  #senders = [];
  #transceivers = [];

  constructor(configuration) {
    this.configuration = configuration;
  }

  addTrack(track) {
    const sender = { track };
    this.#senders.push(sender);
    return sender;
  }

  addTransceiver(kind) {
    const sender = {
      track: null,
      async replaceTrack(newTrack) {
        this.track = newTrack;
      },
    };
    const transceiver = {
      mid: null,
      direction: "sendrecv",
      sender,
      receiver: { track: { kind } },
    };
    this.#transceivers.push(transceiver);
    this.#senders.push(sender);
    return transceiver;
  }

  getTransceivers() {
    return this.#transceivers;
  }

  getSenders() {
    return this.#senders;
  }

  async createOffer() {
    return { type: "offer", sdp: "fake-offer" };
  }

  async setLocalDescription(description) {
    this.localDescription = description;
  }

  close() {
    this.connectionState = "closed";
  }
}

function managerOptions(overrides = {}) {
  return {
    getIceServers: () => [],
    getLocalStream: () => null,
    sendSignal: () => Promise.resolve(),
    flushQueuedSignals: () => Promise.resolve(),
    onTrack: () => {},
    clearSignalQueue: () => {},
    onPeerDestroyed: () => {},
    ...overrides,
  };
}

module("Resenha | Unit | Lib | peer-manager", function (hooks) {
  hooks.beforeEach(function () {
    this.originalRTCPeerConnection = globalThis.RTCPeerConnection;
    globalThis.RTCPeerConnection = FakeRTCPeerConnection;
    meshConnectionQuality.resetForTesting();
  });

  hooks.afterEach(function () {
    meshConnectionQuality.resetForTesting();
    globalThis.RTCPeerConnection = this.originalRTCPeerConnection;
  });

  test("does not keep a restarted peer when the room becomes ineligible mid-restart", async function (assert) {
    let shouldRestart = true;
    let sentSignals = 0;

    const manager = new PeerManager(
      managerOptions({
        sendSignal: () => {
          sentSignals++;
          return Promise.resolve();
        },
        shouldRestartPeer: () => shouldRestart,
        requestIceRefresh: async () => {
          shouldRestart = false;
          return { ice: { servers: [], transport_policy: "all" } };
        },
      })
    );

    await manager.create(1, 2);
    assert.true(manager.has(1, 2), "creates the initial peer");

    await manager.restart(1, 2);

    assert.true(
      manager.has(1, 2),
      "keeps the existing peer when restart becomes ineligible before teardown"
    );
    assert.strictEqual(sentSignals, 0, "does not emit a new offer");
    manager.destroyAll();
  });

  test("refreshes ICE before recreating a peer", async function (assert) {
    const originalServers = [{ urls: "stun:old.example.test" }];
    const freshServers = [
      {
        urls: "turn:relay.example.test",
        username: "fresh",
        credential: "secret",
      },
    ];
    let refreshes = 0;

    const manager = new PeerManager(
      managerOptions({
        getIceServers: () => originalServers,
        getIceTransportPolicy: () => "all",
        requestIceRefresh: async () => {
          refreshes++;
          return {
            ice: { servers: freshServers, transport_policy: "relay" },
          };
        },
      })
    );

    const initial = await manager.create(1, 2);
    assert.deepEqual(initial.configuration.iceServers, originalServers);

    await manager.restart(1, 2);
    const restarted = manager.get(1, 2);

    assert.strictEqual(refreshes, 1, "refreshes exactly once for the restart");
    assert.notStrictEqual(restarted, initial, "rebuilds the peer");
    assert.deepEqual(
      restarted.configuration.iceServers,
      freshServers,
      "uses the refreshed TURN credentials"
    );
    assert.strictEqual(
      restarted.configuration.iceTransportPolicy,
      "relay",
      "uses the refreshed transport policy"
    );
    manager.destroyAll();
  });

  test("does not recreate a peer after a terminal ICE refresh rejection", async function (assert) {
    let refreshes = 0;
    const manager = new PeerManager(
      managerOptions({
        requestIceRefresh: async () => {
          refreshes++;
          const error = new Error("room instance ended");
          error.status = 410;
          throw error;
        },
      })
    );

    const initial = await manager.create(1, 2);
    await manager.restart(1, 2);

    assert.strictEqual(refreshes, 1);
    assert.strictEqual(
      manager.get(1, 2),
      initial,
      "leaves the stale peer in place for the heartbeat teardown path"
    );
    manager.destroyAll();
  });

  test("falls back to cached ICE when refresh fails transiently", async function (assert) {
    const originalServers = [{ urls: "stun:cached.example.test" }];
    const manager = new PeerManager(
      managerOptions({
        getIceServers: () => originalServers,
        requestIceRefresh: async () => {
          const error = new Error("temporary outage");
          error.status = 503;
          throw error;
        },
      })
    );

    const initial = await manager.create(1, 2);
    await manager.restart(1, 2);
    const restarted = manager.get(1, 2);

    assert.notStrictEqual(restarted, initial, "still performs the reconnect");
    assert.deepEqual(
      restarted.configuration.iceServers,
      originalServers,
      "uses the last known ICE configuration"
    );
    manager.destroyAll();
  });

  test("deduplicates concurrent room ICE refreshes", async function (assert) {
    let resolveRefresh;
    let refreshes = 0;
    const refreshPromise = new Promise((resolve) => {
      resolveRefresh = resolve;
    });
    const manager = new PeerManager(
      managerOptions({
        requestIceRefresh: () => {
          refreshes++;
          return refreshPromise;
        },
      })
    );

    await manager.create(1, 2);
    await manager.create(1, 3);

    const firstRestart = manager.restart(1, 2);
    const secondRestart = manager.restart(1, 3);
    await Promise.resolve();

    assert.strictEqual(refreshes, 1, "shares one refresh across room peers");

    resolveRefresh({ ice: { servers: [], transport_policy: "all" } });
    await Promise.all([firstRestart, secondRestart]);

    assert.true(manager.has(1, 2));
    assert.true(manager.has(1, 3));
    manager.destroyAll();
  });

  test("alignVideoTransceiverForAnswer makes the negotiated transceiver sendable and migrates the orphaned track", async function (assert) {
    const makeSender = (track = null) => ({
      track,
      async replaceTrack(newTrack) {
        this.track = newTrack;
      },
    });

    const cameraTrack = { id: "camera", kind: "video" };
    const orphan = {
      mid: null,
      direction: "sendrecv",
      sender: makeSender(cameraTrack),
      receiver: { track: { kind: "video" } },
    };
    const associated = {
      mid: "1",
      direction: "recvonly",
      sender: makeSender(),
      receiver: { track: { kind: "video" } },
    };
    const pc = {
      getTransceivers() {
        return [orphan, associated];
      },
    };

    PeerManager.alignVideoTransceiverForAnswer(pc);
    await Promise.resolve();

    assert.strictEqual(
      associated.direction,
      "sendrecv",
      "flips the negotiated transceiver to sendrecv before the answer"
    );
    assert.strictEqual(
      associated.sender.track,
      cameraTrack,
      "moves the camera track onto the negotiated transceiver"
    );
    assert.strictEqual(
      orphan.sender.track,
      null,
      "detaches the camera track from the orphaned transceiver"
    );
    assert.strictEqual(
      PeerManager.videoTransceiverFor(pc),
      associated,
      "videoTransceiverFor prefers the negotiated transceiver"
    );
  });

  test("alignScreenAudioTransceiverForAnswer adopts the negotiated m-line and migrates the orphaned track", async function (assert) {
    const screenAudioTrack = { id: "screen-audio", kind: "audio" };

    const manager = new PeerManager(
      managerOptions({ getLocalScreenAudioTrack: () => screenAudioTrack })
    );

    const pc = await manager.create(1, 2);
    await Promise.resolve();

    const preAllocated = PeerManager.screenAudioTransceiverFor(pc);
    assert.strictEqual(
      preAllocated.sender.track,
      screenAudioTrack,
      "attaches the local screen audio track at peer setup"
    );

    // Simulate applying a remote offer: fresh recvonly transceivers appear
    // for each m-line the pre-allocated ones couldn't be reused for.
    const makeSender = (track = null) => ({
      track,
      async replaceTrack(newTrack) {
        this.track = newTrack;
      },
    });
    const micTransceiver = {
      mid: "0",
      direction: "recvonly",
      sender: makeSender(),
      receiver: { track: { kind: "audio" } },
    };
    const negotiated = {
      mid: "2",
      direction: "recvonly",
      sender: makeSender(),
      receiver: { track: { kind: "audio" } },
    };
    pc.getTransceivers().push(micTransceiver, negotiated);

    PeerManager.alignScreenAudioTransceiverForAnswer(pc);
    await Promise.resolve();

    assert.strictEqual(
      negotiated.direction,
      "sendrecv",
      "flips the negotiated transceiver to sendrecv before the answer"
    );
    assert.strictEqual(
      negotiated.sender.track,
      screenAudioTrack,
      "moves the screen audio track onto the negotiated transceiver"
    );
    assert.strictEqual(
      preAllocated.sender.track,
      null,
      "detaches the track from the orphaned transceiver"
    );
    assert.strictEqual(
      micTransceiver.direction,
      "recvonly",
      "leaves the mic m-line alone"
    );
    assert.strictEqual(
      PeerManager.screenAudioTransceiverFor(pc),
      negotiated,
      "screenAudioTransceiverFor returns the negotiated transceiver"
    );
    manager.destroyAll();
  });

  test("alignScreenAudioTransceiverForAnswer leaves single-audio offers from older clients alone", async function (assert) {
    const manager = new PeerManager(managerOptions());

    const pc = await manager.create(1, 2);
    const preAllocated = PeerManager.screenAudioTransceiverFor(pc);

    const micTransceiver = {
      mid: "0",
      direction: "recvonly",
      sender: { track: null },
      receiver: { track: { kind: "audio" } },
    };
    pc.getTransceivers().push(micTransceiver);

    PeerManager.alignScreenAudioTransceiverForAnswer(pc);

    assert.strictEqual(
      micTransceiver.direction,
      "recvonly",
      "does not adopt the mic m-line as the screen audio slot"
    );
    assert.strictEqual(
      PeerManager.screenAudioTransceiverFor(pc),
      preAllocated,
      "keeps the pre-allocated transceiver as the screen audio slot"
    );
    manager.destroyAll();
  });
});
