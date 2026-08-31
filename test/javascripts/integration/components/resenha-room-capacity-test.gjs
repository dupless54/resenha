import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";
import { click, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { logIn } from "discourse/tests/helpers/qunit-helpers";
import ResenhaRoomPage from "discourse/plugins/resenha/discourse/components/resenha/room-page";

class ResenhaRoomsStub extends Service {
  @tracked rooms = [];

  roomById(id) {
    return this.rooms.find((room) => Number(room.id) === Number(id));
  }

  isParticipantSpeaking() {
    return false;
  }
}

class ResenhaWebrtcStub extends Service {
  @tracked connectionState = "disconnected";
  @tracked localVideoKind = null;

  joinCalls = [];

  connectionStateFor() {
    return this.connectionState;
  }

  isActiveRoom() {
    return false;
  }

  isTranscribingRoom() {
    return false;
  }

  setWatching() {}

  join(room) {
    this.joinCalls.push(room.id);
  }

  leave() {}

  videoAllowedIn() {
    return false;
  }

  canPublishVideo() {
    return false;
  }

  attachVideoStream() {}

  remoteStreamFor() {
    return null;
  }

  getParticipantVolume() {
    return 1;
  }

  isParticipantMuted() {
    return false;
  }
}

class RouterStub extends Service {
  transitionCalls = [];

  transitionTo(...args) {
    this.transitionCalls.push(args);
  }
}

class ModalStub extends Service {
  show() {}
}

class CapabilitiesStub extends Service {
  viewport = { md: true };
  touch = false;
}

function participant(id, username) {
  return {
    id,
    username,
    avatar_template: `/letter_avatar_proxy/v4/letter/${username[0]}/{size}.png`,
  };
}

module("Integration | Component | Resenha | Room capacity", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.currentUser = logIn(this.owner);

    this.owner.unregister("service:capabilities");
    this.owner.register("service:capabilities", CapabilitiesStub);
    this.owner.unregister("service:resenha-rooms");
    this.owner.register("service:resenha-rooms", ResenhaRoomsStub);
    this.owner.unregister("service:resenha-webrtc");
    this.owner.register("service:resenha-webrtc", ResenhaWebrtcStub);
    this.owner.unregister("service:router");
    this.owner.register("service:router", RouterStub);
    this.owner.unregister("service:modal");
    this.owner.register("service:modal", ModalStub);

    this.resenhaRooms = this.owner.lookup("service:resenha-rooms");
    this.resenhaWebrtc = this.owner.lookup("service:resenha-webrtc");

    this.room = {
      id: 1,
      slug: "capacity-room",
      name: "Capacity Room",
      chat_available: false,
      video_enabled: false,
      effective_max_participants: 4,
      full: false,
      active_participants: [
        participant(2, "bob"),
        participant(3, "cara"),
        participant(4, "dan"),
      ],
    };

    this.resenhaRooms.rooms = [this.room];
  });

  test(
    "shows server-provided capacity in the room header",
    async function (assert) {
      await render(
        <template><ResenhaRoomPage @room={{this.room}} /></template>
      );

      assert.dom(".resenha-room-page__capacity").hasText("3/4");
      assert
        .dom(".resenha-room-page__capacity")
        .hasAttribute("aria-label", "Voice room capacity: 3 of 4");
      assert.dom(".resenha-room-page__join").isNotDisabled();
    }
  );

  test("blocks a new user from a full room", async function (assert) {
    this.room.full = true;
    this.room.active_participants.push(participant(5, "erin"));

    await render(<template><ResenhaRoomPage @room={{this.room}} /></template>);

    assert.dom(".resenha-room-page__capacity").hasText("4/4");
    assert.dom(".resenha-room-page__capacity").hasClass("--full");
    assert
      .dom(".resenha-room-page__capacity")
      .hasAttribute("aria-label", "Room full — 4 of 4");
    assert.dom(".resenha-room-page__join").isDisabled();
    assert.dom(".resenha-room-page__join").hasText("Room full");
    assert.deepEqual(this.resenhaWebrtc.joinCalls, []);
  });

  test(
    "keeps reconnect available for a participant who already holds a full-room slot",
    async function (assert) {
      this.room.full = true;
      this.room.active_participants.push(
        participant(this.currentUser.id, this.currentUser.username)
      );

      await render(
        <template><ResenhaRoomPage @room={{this.room}} /></template>
      );

      assert.dom(".resenha-room-page__capacity").hasText("4/4");
      assert.dom(".resenha-room-page__join").isNotDisabled();
      assert.dom(".resenha-room-page__join").hasText("Join voice room");

      await click(".resenha-room-page__join");

      assert.deepEqual(this.resenhaWebrtc.joinCalls, [1]);
    }
  );

  test(
    "auto join does not bypass the full-room presentation guard",
    async function (assert) {
      this.room.full = true;
      this.room.active_participants.push(participant(5, "erin"));

      await render(
        <template>
          <ResenhaRoomPage @room={{this.room}} @autoJoin={{true}} />
        </template>
      );
      await settled();

      assert.deepEqual(this.resenhaWebrtc.joinCalls, []);
      assert.dom(".resenha-room-page__join").isDisabled();
    }
  );
});
