import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn, hash } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import UserChooser from "discourse/select-kit/components/user-chooser";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import { i18n } from "discourse-i18n";

export default class ResenhaManageBansModal extends Component {
  @service dialog;
  @service toasts;

  @tracked bans = [];
  @tracked loading = true;
  @tracked selectedUsernames = [];
  @tracked saving = false;

  constructor() {
    super(...arguments);
    this.loadBans();
  }

  get room() {
    return this.args.model.room;
  }

  get banDisabled() {
    return this.saving || this.selectedUsernames.length === 0;
  }

  async loadBans() {
    try {
      const result = await ajax(`/resenha/rooms/${this.room.id}/bans`);
      this.bans = result.bans || [];
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  setSelectedUsernames(usernames) {
    this.selectedUsernames = usernames;
  }

  @action
  banSelected() {
    const username = this.selectedUsernames[0];
    if (!username) {
      return;
    }

    this.dialog.yesNoConfirm({
      message: i18n("resenha.bans.confirm_ban", { username }),
      didConfirm: () => this.#ban(username),
    });
  }

  @action
  unban(ban) {
    const username = ban.user.username;
    this.dialog.yesNoConfirm({
      message: i18n("resenha.bans.confirm_unban", { username }),
      didConfirm: () => this.#unban(ban),
    });
  }

  async #ban(username) {
    this.saving = true;
    try {
      const result = await ajax(`/resenha/rooms/${this.room.id}/bans`, {
        type: "POST",
        data: { username },
      });
      this.bans = [result.ban, ...this.bans.filter((ban) => ban.id !== result.ban.id)];
      this.selectedUsernames = [];
      this.toasts.success({
        duration: "short",
        data: { message: i18n("resenha.bans.banned", { username }) },
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  async #unban(ban) {
    this.saving = true;
    try {
      await ajax(`/resenha/rooms/${this.room.id}/bans/${ban.id}`, {
        type: "DELETE",
      });
      this.bans = this.bans.filter((entry) => entry.id !== ban.id);
      this.toasts.success({
        duration: "short",
        data: {
          message: i18n("resenha.bans.unbanned", {
            username: ban.user.username,
          }),
        },
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <DModal
      @closeModal={{@closeModal}}
      @title={{i18n "resenha.bans.title" room_name=this.room.name}}
      class="resenha-manage-bans-modal"
    >
      <:body>
        <div class="resenha-manage-bans-modal__add">
          <label class="resenha-manage-bans-modal__label">
            {{i18n "resenha.bans.search_label"}}
          </label>
          <div class="resenha-manage-bans-modal__add-row">
            <UserChooser
              @value={{this.selectedUsernames}}
              @onChange={{this.setSelectedUsernames}}
              @options={{hash
                excludeCurrentUser=true
                maximum=1
                filterPlaceholder="resenha.bans.search_placeholder"
              }}
              class="resenha-manage-bans-modal__user-chooser"
            />
            <DButton
              @action={{this.banSelected}}
              @icon="ban"
              @label="resenha.bans.ban"
              @disabled={{this.banDisabled}}
              class="btn-danger resenha-manage-bans-modal__ban"
            />
          </div>
        </div>

        {{#if this.loading}}
          <div class="resenha-manage-bans-modal__loading">
            <div class="spinner small"></div>
            {{i18n "loading"}}
          </div>
        {{else if this.bans.length}}
          <div class="resenha-manage-bans-modal__list">
            {{#each this.bans as |ban|}}
              <div class="resenha-manage-bans-modal__row">
                <div class="resenha-manage-bans-modal__avatar">
                  {{dAvatar ban.user imageSize="medium"}}
                </div>
                <div class="resenha-manage-bans-modal__details">
                  <strong class="resenha-manage-bans-modal__username">
                    {{ban.user.username}}
                  </strong>
                  {{#if ban.banned_by}}
                    <span class="resenha-manage-bans-modal__byline">
                      {{i18n
                        "resenha.bans.banned_by"
                        username=ban.banned_by.username
                      }}
                    </span>
                  {{/if}}
                </div>
                <DButton
                  @action={{fn this.unban ban}}
                  @icon="rotate-left"
                  @label="resenha.bans.unban"
                  @disabled={{this.saving}}
                  class="btn-small resenha-manage-bans-modal__unban"
                />
              </div>
            {{/each}}
          </div>
        {{else}}
          <p class="resenha-manage-bans-modal__empty">
            {{i18n "resenha.bans.empty"}}
          </p>
        {{/if}}
      </:body>
    </DModal>
  </template>
}
