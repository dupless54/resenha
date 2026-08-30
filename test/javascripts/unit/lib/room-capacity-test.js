import { module, test } from "qunit";
import {
  activeParticipantCount,
  currentUserHasRoomSlot,
  effectiveRoomCapacity,
  participantLimitForRoomType,
  participantValidation,
  roomCapacityBlocksJoin,
  roomCapacityLabel,
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

  test("formats server capacity with the live participant count", function (assert) {
    const room = {
      effective_max_participants: 4,
      active_participants: [{ id: 1 }, { id: 2 }, { id: 3 }],
    };

    assert.strictEqual(activeParticipantCount(room), 3);
    assert.strictEqual(effectiveRoomCapacity(room), 4);
    assert.strictEqual(roomCapacityLabel(room), "3/4");
  });

  test("returns no capacity label when the server did not provide a valid effective cap", function (assert) {
    assert.strictEqual(roomCapacityLabel({ active_participants: [] }), null);
    assert.strictEqual(
      roomCapacityLabel({ effective_max_participants: "invalid" }),
      null
    );
  });

  test("blocks a new user from a full room but preserves reconnect for a participant holding a slot", function (assert) {
    const room = {
      full: true,
      effective_max_participants: 4,
      active_participants: [{ id: 10 }, { id: 20 }, { id: 30 }, { id: 40 }],
    };

    assert.true(currentUserHasRoomSlot(room, 20));
    assert.false(roomCapacityBlocksJoin(room, 20));
    assert.true(roomCapacityBlocksJoin(room, 99));
    assert.true(roomCapacityBlocksJoin(room, null));
  });

  test("does not client-block admission from a non-full snapshot", function (assert) {
    const room = {
      full: false,
      effective_max_participants: 4,
      active_participants: [{ id: 10 }, { id: 20 }, { id: 30 }],
    };

    assert.false(roomCapacityBlocksJoin(room, 99));
  });
});
