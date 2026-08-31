import { module, test } from "qunit";
import {
  CONNECTION_STATUS_RECONNECTING,
  meshConnectionQuality,
} from "discourse/plugins/resenha/discourse/lib/resenha/connection-quality";
import PeerManager from "discourse/plugins/resenha/discourse/lib/resenha/peer-manager";

class FakeRTCPeerConnection {
  signalingState = "stable";
  connectionState = "new";
  iceConnectionState = "new";
  iceGatheringState = "new";
  #senders = [];
  #transceivers = [];

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

  close() {
    this.connectionState = "closed";
  }
}

function managerOptions() {
  return {
    getIceServers: () => [],
    getLocalStream: () => null,
    sendSignal: () => Promise.resolve(),
    flushQueuedSignals: () => Promise.resolve(),
    onTrack: () => {},
    clearSignalQueue: () => {},
    onPeerDestroyed: () => {},
  };
}

module("Resenha | Unit | Lib | peer-manager reconnecting", function (hooks) {
  hooks.beforeEach(function () {
    this.originalRTCPeerConnection = globalThis.RTCPeerConnection;
    globalThis.RTCPeerConnection = FakeRTCPeerConnection;
    meshConnectionQuality.resetForTesting();
  });

  hooks.afterEach(function () {
    meshConnectionQuality.resetForTesting();
    globalThis.RTCPeerConnection = this.originalRTCPeerConnection;
  });

  test("tracks only an active peer restart and clears when recovery wins", async function (assert) {
    const manager = new PeerManager(managerOptions());
    const pc = await manager.create(1, 2);

    pc.connectionState = "disconnected";
    pc.onconnectionstatechange();

    assert.strictEqual(
      meshConnectionQuality.stateFor(1),
      CONNECTION_STATUS_RECONNECTING,
      "a scheduled restart is exposed as reconnecting"
    );

    pc.connectionState = "connected";
    pc.onconnectionstatechange();

    assert.notStrictEqual(
      meshConnectionQuality.stateFor(1),
      CONNECTION_STATUS_RECONNECTING,
      "successful recovery clears reconnecting immediately"
    );

    manager.destroyAll();
    assert.strictEqual(
      meshConnectionQuality.stateFor(1),
      null,
      "teardown leaves no stale connection state"
    );
  });
});
