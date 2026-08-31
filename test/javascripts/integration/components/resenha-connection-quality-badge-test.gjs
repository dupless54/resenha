import { render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ResenhaConnectionQualityBadge from "discourse/plugins/resenha/discourse/components/resenha/connection-quality-badge";
import { meshConnectionQuality } from "discourse/plugins/resenha/discourse/lib/resenha/connection-quality";

module(
  "Integration | Component | resenha-connection-quality-badge",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.afterEach(function () {
      meshConnectionQuality.resetForTesting();
    });

    test("renders an accessible non-color-only status and hides when the peer leaves", async function (assert) {
      const room = { id: 42 };

      await render(
        <template><ResenhaConnectionQualityBadge @room={{room}} /></template>
      );

      assert.dom(".resenha-connection-quality").doesNotExist();

      const peer = { connectionState: "disconnected" };
      meshConnectionQuality.registerPeer(room.id, 9, peer);
      await settled();

      assert.dom(".resenha-connection-quality.--poor").exists();
      assert.dom(".resenha-connection-quality").hasText("Poor");
      assert
        .dom(".resenha-connection-quality")
        .hasAttribute("aria-label", "Connection quality: Poor");
      assert.dom(".resenha-connection-quality .d-icon-waveform").exists();

      meshConnectionQuality.unregisterPeer(room.id, 9, peer);
      await settled();

      assert.dom(".resenha-connection-quality").doesNotExist();
    });
  }
);
