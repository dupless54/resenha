import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";
import { meshConnectionQuality } from "../../lib/resenha/connection-quality";

export default class ResenhaConnectionQualityService extends Service {
  @tracked revision = 0;

  #unsubscribe;

  constructor() {
    super(...arguments);
    this.#unsubscribe = meshConnectionQuality.subscribe(() => this.revision++);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#unsubscribe?.();
  }

  qualityFor(roomId) {
    this.revision;
    return meshConnectionQuality.qualityFor(roomId);
  }
}
