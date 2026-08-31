import { module, test } from "qunit";
import roomIcon, {
  roomBadge,
} from "discourse/plugins/resenha/discourse/lib/resenha/room-icon";

module("Unit | Lib | resenha | room-icon", function () {
  test("keeps room type icon while showing a lock badge for private or locked rooms", function (assert) {
    assert.strictEqual(roomIcon({ room_type: "open" }), "microphone-lines");
    assert.strictEqual(roomIcon({ room_type: "stage" }), "podcast");

    assert.strictEqual(roomBadge({ public: true, locked: false }), null);
    assert.strictEqual(roomBadge({ public: false, locked: false }), "lock");
    assert.strictEqual(roomBadge({ public: true, locked: true }), "lock");
  });
});
