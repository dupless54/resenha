import { extractError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

function responsePayload(error) {
  const xhr = error?.jqXHR ?? error;

  if (xhr?.responseJSON) {
    return xhr.responseJSON;
  }

  if (xhr?.responseText) {
    try {
      return JSON.parse(xhr.responseText);
    } catch {
      return null;
    }
  }

  return null;
}

function hasServerReason(payload) {
  return Boolean(
    (Array.isArray(payload?.errors) && payload.errors.length > 0) ||
    payload?.error ||
    payload?.message ||
    payload?.failed ||
    payload?.error_key
  );
}

export function joinErrorMessage(error) {
  if (hasServerReason(responsePayload(error))) {
    return extractError(error);
  }

  return i18n("resenha.room.join_failed");
}
