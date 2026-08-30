import { module, test } from "qunit";
import {
  participantLimitForRoomType,
  participantValidation,
} from "discourse/plugins/resenha/discourse/lib/resenha/room-capacity";

module("Resenha | Unit | Lib | room-capacity", function () {
  test("uses the site ceiling when it is lower than the room type cap", function (assert) {
    assert.strictEqual(participantLimitForRoomType(4, "open"), 4);
    assert.strictEqual(participantLimitForRoomType(4, "stage"), 4);
    assert.strictEqual(participantValidation(4, "open"), "integer|number:2,4");
  });

  test("never raises the built-in room type caps", function (assert) {
    assert.strictEqual(participantLimitForRoomType(100, "open"), 50);
    assert.strictEqual(participantLimitForRoomType(100, "stage"), 100);
    assert.strictEqual(participantLimitForRoomType(500, "stage"), 200);
  });

  test("falls back to the room type cap for an invalid site value", function (assert) {
    assert.strictEqual(participantLimitForRoomType(null, "open"), 50);
    assert.strictEqual(participantLimitForRoomType("invalid", "stage"), 200);
  });
});
