import Service from "@ember/service";
import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { logIn } from "discourse/tests/helpers/qunit-helpers";
import ResenhaParticipantSidebarContextMenu from "discourse/plugins/resenha/discourse/components/resenha-participant-sidebar-context-menu";

class DialogStub extends Service {
  lastConfirmation = null;

  yesNoConfirm(options) {
    this.lastConfirmation = options;
  }
}

class ResenhaWebrtcStub extends Service {
  getParticipantVolume() {
    return 1;
  }

  isParticipantMuted() {
    return false;
  }
}

module(
  "Integration | Component | ResenhaParticipantSidebarContextMenu",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      logIn(this.owner);
      this.owner.unregister("service:dialog");
      this.owner.register("service:dialog", DialogStub);
      this.owner.unregister("service:resenha-webrtc");
      this.owner.register("service:resenha-webrtc", ResenhaWebrtcStub);

      this.dialog = this.owner.lookup("service:dialog");
      this.selectedParticipantId = null;
      this.closed = false;
      this.menuData = {
        room: {
          id: 1,
          room_type: "open",
          ephemeral: false,
          creator_id: 99,
        },
        participant: { id: 2, username: "bob", role: "participant" },
        isCurrentUser: false,
        canManageRoom: false,
        onSpotlight: (participantId) => {
          this.selectedParticipantId = participantId;
        },
      };
      this.closeMenu = () => {
        this.closed = true;
      };
    });

    test("spotlights the participant for the viewer", async function (assert) {
      await render(
        <template>
          <ResenhaParticipantSidebarContextMenu
            @data={{this.menuData}}
            @close={{this.closeMenu}}
          />
        </template>
      );

      assert
        .dom(".resenha-participant-sidebar-context-menu__spotlight-btn")
        .hasText("Spotlight for me", "offers the local spotlight action");

      await click(".resenha-participant-sidebar-context-menu__spotlight-btn");

      assert.strictEqual(
        this.selectedParticipantId,
        2,
        "selects the menu's participant"
      );
      assert.true(this.closed, "closes the participant menu");
    });

    test("shows when the participant is already spotlighted", async function (assert) {
      this.menuData.isSpotlighted = true;

      await render(
        <template>
          <ResenhaParticipantSidebarContextMenu
            @data={{this.menuData}}
            @close={{this.closeMenu}}
          />
        </template>
      );

      assert
        .dom(".resenha-participant-sidebar-context-menu__spotlight-btn")
        .hasText("Remove from spotlight", "offers to remove the spotlight")
        .hasAttribute("aria-pressed", "true", "exposes the active state");
    });

    test("offers destructive quick ban confirmation to room managers", async function (assert) {
      this.menuData.canManageRoom = true;

      await render(
        <template>
          <ResenhaParticipantSidebarContextMenu
            @data={{this.menuData}}
            @close={{this.closeMenu}}
          />
        </template>
      );

      assert
        .dom(".resenha-participant-sidebar-context-menu__ban-btn")
        .hasText("Ban", "offers the persistent ban action");
      assert
        .dom(".resenha-participant-sidebar-context-menu__kick-btn")
        .exists("keeps the separate kick action available");

      await click(".resenha-participant-sidebar-context-menu__ban-btn");

      assert.strictEqual(
        this.dialog.lastConfirmation?.confirmButtonClass,
        "btn-danger",
        "marks ban confirmation as destructive"
      );
      assert.strictEqual(
        typeof this.dialog.lastConfirmation?.didConfirm,
        "function",
        "defers the ban until explicit confirmation"
      );
    });

    test("requires destructive confirmation before kicking a participant", async function (assert) {
      this.menuData.canManageRoom = true;

      await render(
        <template>
          <ResenhaParticipantSidebarContextMenu
            @data={{this.menuData}}
            @close={{this.closeMenu}}
          />
        </template>
      );

      await click(".resenha-participant-sidebar-context-menu__kick-btn");

      assert.true(this.closed, "closes the participant menu before confirming");
      assert.strictEqual(
        this.dialog.lastConfirmation?.message,
        "Kick @bob from this room? They can rejoin unless you ban them.",
        "explains that kick is temporary"
      );
      assert.strictEqual(
        this.dialog.lastConfirmation?.confirmButtonClass,
        "btn-danger",
        "marks kick confirmation as destructive"
      );
      assert.strictEqual(
        typeof this.dialog.lastConfirmation?.didConfirm,
        "function",
        "defers the destructive request until explicit confirmation"
      );
    });

    test("hides quick ban in ephemeral rooms", async function (assert) {
      this.menuData.canManageRoom = true;
      this.menuData.room.ephemeral = true;

      await render(
        <template>
          <ResenhaParticipantSidebarContextMenu
            @data={{this.menuData}}
            @close={{this.closeMenu}}
          />
        </template>
      );

      assert
        .dom(".resenha-participant-sidebar-context-menu__ban-btn")
        .doesNotExist("does not offer persistent bans for ephemeral calls");
      assert
        .dom(".resenha-participant-sidebar-context-menu__kick-btn")
        .exists("still allows a temporary kick");
    });

    test("hides destructive moderation for protected room targets", async function (assert) {
      this.menuData.canManageRoom = true;
      this.menuData.participant.role = "moderator";

      await render(
        <template>
          <ResenhaParticipantSidebarContextMenu
            @data={{this.menuData}}
            @close={{this.closeMenu}}
          />
        </template>
      );

      assert
        .dom(".resenha-participant-sidebar-context-menu__ban-btn")
        .doesNotExist("does not offer ban for a room moderator");
      assert
        .dom(".resenha-participant-sidebar-context-menu__kick-btn")
        .doesNotExist("does not offer kick for a room moderator");
    });
  }
);
