import Service from "@ember/service";
import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { logIn } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

class ResenhaRoomsStub extends Service {
  roomById() {
    return null;
  }

  registerRoomHandler() {}
  unregisterRoomHandler() {}
  removeParticipant() {}
  setParticipantSpeaking() {}
  setParticipantVideoState() {}
}

class ToastsStub extends Service {
  errors = [];

  error(payload) {
    this.errors.push(payload);
  }

  success() {}
  default() {}
}

module("Resenha | Unit | Service | join errors", function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    this.currentUser = logIn(this.owner);
    this.siteSettings = this.owner.lookup("service:site-settings");
    this.siteSettings.resenha_auto_status_enabled = true;
    this.siteSettings.resenha_mesh_privacy_warning_enabled = false;

    this.owner.unregister("service:resenha-rooms");
    this.owner.register("service:resenha-rooms", ResenhaRoomsStub);
    this.owner.unregister("service:toasts");
    this.owner.register("service:toasts", ToastsStub);

    this.toasts = this.owner.lookup("service:toasts");
    this.subject = this.owner.lookup("service:resenha-webrtc");
    this.room = {
      id: 1,
      name: "Capacity Room",
      room_type: "open",
      active_participants: [],
    };
  });

  test("shows the server admission reason and unwinds connecting state", async function (assert) {
    pretender.post("/resenha/rooms/1/join", () =>
      response(422, { errors: ["This room is full."] })
    );

    await this.subject.join(this.room);

    assert.strictEqual(this.subject.connectionStateFor(1), "idle");
    assert.strictEqual(this.toasts.errors.length, 1);
    assert.true(
      this.toasts.errors[0].data.message.includes("This room is full."),
      "shows the authoritative server rejection"
    );
  });

  test("uses friendly fallback copy for an unstructured failure", async function (assert) {
    pretender.post("/resenha/rooms/1/join", () => response(500, {}));

    await this.subject.join(this.room);

    assert.strictEqual(this.subject.connectionStateFor(1), "idle");
    assert.strictEqual(this.toasts.errors.length, 1);
    assert.strictEqual(
      this.toasts.errors[0].data.message,
      i18n("resenha.room.join_failed")
    );
  });
});
