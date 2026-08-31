import Service from "@ember/service";
import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ResenhaRoomSidebarContextMenu from "discourse/plugins/resenha/discourse/components/resenha-room-sidebar-context-menu";

class ResenhaWebrtcStub extends Service {
  callWidgetHidden = false;

  connectionStateFor() {
    return "idle";
  }
}

module(
  "Integration | Component | ResenhaRoomSidebarContextMenu | lock",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.owner.unregister("service:resenha-webrtc");
      this.owner.register("service:resenha-webrtc", ResenhaWebrtcStub);
      this.closeMenu = () => {};
    });

    async function renderMenu(context, room) {
      context.menuData = { room };
      await render(
        <template>
          <ResenhaRoomSidebarContextMenu
            @data={{this.menuData}}
            @close={{this.closeMenu}}
          />
        </template>
      );
    }

    test("offers a lock action to a persistent-room manager", async function (assert) {
      await renderMenu(this, {
        id: 1,
        slug: "lounge",
        can_manage: true,
        can_invite: false,
        ephemeral: false,
        locked: false,
      });

      assert
        .dom(".resenha-room-sidebar-context-menu__toggle-lock")
        .hasText("Lock room");
    });

    test("offers an unlock action when the room is locked", async function (assert) {
      await renderMenu(this, {
        id: 1,
        slug: "lounge",
        can_manage: true,
        can_invite: false,
        ephemeral: false,
        locked: true,
      });

      assert
        .dom(".resenha-room-sidebar-context-menu__toggle-lock")
        .hasText("Unlock room");
    });

    test("does not expose the lock action to a non-manager", async function (assert) {
      await renderMenu(this, {
        id: 1,
        slug: "lounge",
        can_manage: false,
        can_invite: false,
        ephemeral: false,
        locked: false,
      });

      assert.dom(".resenha-room-sidebar-context-menu__toggle-lock").doesNotExist();
    });

    test("does not expose the lock action for an ephemeral call room", async function (assert) {
      await renderMenu(this, {
        id: 1,
        slug: "call",
        can_manage: true,
        can_invite: false,
        ephemeral: true,
        locked: false,
      });

      assert.dom(".resenha-room-sidebar-context-menu__toggle-lock").doesNotExist();
    });
  }
);
