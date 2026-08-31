import Component from "@glimmer/component";
import { service } from "@ember/service";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class ResenhaConnectionQualityBadge extends Component {
  @service("resenha-connection-quality") connectionQuality;

  get quality() {
    return this.connectionQuality.qualityFor(this.args.room?.id);
  }

  get label() {
    return this.quality
      ? i18n(`resenha.connection_quality.${this.quality}`)
      : null;
  }

  get title() {
    return this.quality
      ? i18n(`resenha.connection_quality.title_${this.quality}`)
      : null;
  }

  <template>
    {{#if this.quality}}
      <span
        class={{dConcatClass
          "resenha-connection-quality"
          (concat "--" this.quality)
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
