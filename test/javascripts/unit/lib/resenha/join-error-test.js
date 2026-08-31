import { module, test } from "qunit";
import { i18n } from "discourse-i18n";
import { joinErrorMessage } from "discourse/plugins/resenha/discourse/lib/resenha/join-error";

module("Resenha | Unit | join error", function () {
  test("surfaces a structured server rejection", function (assert) {
    const message = joinErrorMessage({
      status: 422,
      responseJSON: { errors: ["This room is full."] },
    });

    assert.true(
      message.includes("This room is full."),
      "keeps the server-provided admission reason visible"
    );
  });

  test("surfaces a structured reason from a jqXHR wrapper", function (assert) {
    const message = joinErrorMessage({
      jqXHR: {
        status: 403,
        responseJSON: {
          errors: ["You are not allowed to perform that action for this room."],
        },
      },
    });

    assert.true(
      message.includes("You are not allowed"),
      "keeps the server-provided authorization reason visible"
    );
  });

  test("uses friendly fallback copy without a structured server reason", function (assert) {
    const message = joinErrorMessage({
      status: 500,
      statusText: "Internal Server Error",
    });

    assert.strictEqual(message, i18n("resenha.room.join_failed"));
    assert.notStrictEqual(message, "500 Internal Server Error");
  });
});
