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
  "Integration | Component | ResenhaRoomSidebarContextMenu | room management",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.owner.unregister("service:resenha-webrtc");
      this.owner.register("service:resenha-webrtc", ResenhaWebrtcStub);
      this.closeMenu = () => {};
    });

    test("offers lock and ban management to a persistent-room manager", async function (assert) {
      this.menuData = {
        room: {
          id: 1,
          slug: "lounge",
          can_manage: true,
          can_invite: false,
          ephemeral: false,
          locked: false,
        },
      };

      await render(
        <template>
          <ResenhaRoomSidebarContextMenu
            @data={{this.menuData}}
            @close={{this.closeMenu}}
          />
        </template>
      );

      assert
        .dom(".resenha-room-sidebar-context-menu__toggle-lock")
        .hasText("Lock room");
      assert
        .dom(".resenha-room-sidebar-context-menu__manage-bans")
        .hasText("Manage bans");
    });

    test("offers an unlock action when the room is locked", async function (assert) {
      this.menuData = {
        room: {
          id: 1,
          slug: "lounge",
          can_manage: true,
          can_invite: false,
          ephemeral: false,
          locked: true,
        },
      };

      await render(
        <template>
          <ResenhaRoomSidebarContextMenu
            @data={{this.menuData}}
            @close={{this.closeMenu}}
          />
        </template>
      );

      assert
        .dom(".resenha-room-sidebar-context-menu__toggle-lock")
        .hasText("Unlock room");
      assert.dom(".resenha-room-sidebar-context-menu__manage-bans").exists();
    });

    test("does not expose management actions to a non-manager", async function (assert) {
      this.menuData = {
        room: {
          id: 1,
          slug: "lounge",
          can_manage: false,
          can_invite: false,
          ephemeral: false,
          locked: false,
        },
      };

      await render(
        <template>
          <ResenhaRoomSidebarContextMenu
            @data={{this.menuData}}
            @close={{this.closeMenu}}
          />
        </template>
      );

      assert
        .dom(".resenha-room-sidebar-context-menu__toggle-lock")
        .doesNotExist();
      assert
        .dom(".resenha-room-sidebar-context-menu__manage-bans")
        .doesNotExist();
    });

    test("does not expose persistent management actions for an ephemeral call room", async function (assert) {
      this.menuData = {
        room: {
          id: 1,
          slug: "call",
          can_manage: true,
          can_invite: false,
          ephemeral: true,
          locked: false,
        },
      };

      await render(
        <template>
          <ResenhaRoomSidebarContextMenu
            @data={{this.menuData}}
            @close={{this.closeMenu}}
          />
        </template>
      );

      assert
        .dom(".resenha-room-sidebar-context-menu__toggle-lock")
        .doesNotExist();
      assert
        .dom(".resenha-room-sidebar-context-menu__manage-bans")
        .doesNotExist();
    });
  }
);
