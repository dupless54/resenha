import { module, test } from "qunit";
import {
  appendSidebarRoomCapacity,
  sidebarRoomCapacity,
} from "discourse/plugins/resenha/discourse/lib/resenha/sidebar-room-capacity";

module("Resenha | Unit | sidebar room capacity", function () {
  test("presents the server-provided room capacity", function (assert) {
    const room = {
      effective_max_participants: 4,
      full: false,
      active_participants: [{ id: 1 }, { id: 2 }, { id: 3 }],
    };

    const capacity = sidebarRoomCapacity(room);

    assert.strictEqual(capacity.text, "3/4");
    assert.false(capacity.full);
    assert.true(capacity.label.includes("3"));
    assert.true(capacity.label.includes("4"));
  });

  test("uses the authoritative full flag instead of inferring it from the count", function (assert) {
    const room = {
      effective_max_participants: 4,
      full: false,
      active_participants: [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }],
    };

    assert.false(sidebarRoomCapacity(room).full);

    room.full = true;

    const capacity = sidebarRoomCapacity(room);
    assert.true(capacity.full);
    assert.strictEqual(capacity.text, "4/4");
  });

  test("omits capacity when the server does not provide an effective maximum", function (assert) {
    const room = { active_participants: [{ id: 1 }] };

    assert.strictEqual(sidebarRoomCapacity(room), null);
    assert.strictEqual(appendSidebarRoomCapacity("Lobby", room), "Lobby");
  });

  test("adds accessible capacity context to an existing title", function (assert) {
    const room = {
      effective_max_participants: 4,
      full: true,
      active_participants: [{}, {}, {}, {}],
    };

    const title = appendSidebarRoomCapacity("Lobby", room);

    assert.true(title.startsWith("Lobby — "));
    assert.true(title.includes("4"));
  });
});
