import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import { service } from "@ember/service";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class ResenhaConnectionQualityBadge extends Component {
  @service("resenha-connection-quality") connectionQuality;

  get state() {
    return this.connectionQuality.stateFor(this.args.room?.id);
  }

  get label() {
    return this.state ? i18n(`resenha.connection_quality.${this.state}`) : null;
  }

  get title() {
    return this.state
      ? i18n(`resenha.connection_quality.title_${this.state}`)
      : null;
  }

  <template>
    {{#if this.state}}
      <span
        class={{dConcatClass
          "resenha-connection-quality"
          (concat "--" this.state)
        }}
        title={{this.title}}
        aria-label={{this.title}}
      >
        {{dIcon "waveform"}}
        <span>{{this.label}}</span>
      </span>
    {{/if}}
  </template>
}
