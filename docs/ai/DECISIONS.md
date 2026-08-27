# Durable decisions

Load only when room access, privacy, LiveKit, recording, or architecture behavior is relevant.

- Guardian/server policy is authoritative for room access, direct calls, moderation, recording, and admin actions.
- Direct calls preserve current mute/ignore/personal-message/callability rules and reject self/bot/unauthorized targets.
- LiveKit credentials/signing material never reach ordinary client payloads/logs; tokens are short-lived/scoped and issued only after authorization.
- Recording metadata/media access and retention are privacy-sensitive and remain explicitly authorized/auditable.
- External LiveKit/network calls are bounded by timeouts/error handling and sanitized logging.
- User deletion, hashtag/chat integration, and plugin setting changes preserve access boundaries and idempotent room/status invariants.

Do not record temporary room outages or PR/CI state here; use `CURRENT_STATE.md` for volatile facts.
