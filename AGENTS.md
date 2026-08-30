# Resenha Agent Router

Canonical instructions for ChatGPT/Codex, Claude, and Gemini.

## Context routing
Current source/tests > `docs/ai/CURRENT_STATE.md` > nearest local `AGENTS.md` > stable docs > plans/history. Read minimum context only:
- rooms/calls/models/controllers/jobs -> `app/AGENTS.md`
- Guardian/LiveKit/services/integration -> `lib/AGENTS.md`
- admin dashboard -> `admin/AGENTS.md`
- Discourse/Glimmer voice-room UI -> `docs/ai/scopes/frontend/AGENTS.md`
- schema/fixtures -> `db/AGENTS.md`
- tests -> `spec/AGENTS.md`
Use the minimal three-file `docs/ai/work/<feature>/` packet for real multi-session work.

## Fast task path
For non-trivial work, use `.agents/skills/task-packet/SKILL.md` before broad reads. Use `docs/ai/REPO_MAP.md` to locate code, `COMMANDS.md` only for validation, and `DECISIONS.md` only for room/privacy/LiveKit/architecture choices. Skip the formal packet for trivial one-file edits.

## Voice/privacy/security invariants
Resenha provides WebRTC voice rooms/direct calls inside Discourse, with optional LiveKit transport, room membership/access, moderation/reviewables, recordings/admin surfaces, hashtags/chat integration, and presence/status behavior.

- Guardian/server policy is authoritative for room access, join/call permissions, moderation, and recording/admin actions. Client visibility is UX only.
- Direct calls must continue to respect target mute/ignore/personal-message/callability policy and must not allow self/bot/unauthorized calls.
- LiveKit API key/secret, server credentials, tokens, signing material, webhook/internal credentials, and transport secrets never reach ordinary client payloads/logs.
- LiveKit tokens are short-lived/scoped capabilities created only after authorization; do not trust room/user identity from client input.
- Recording metadata/media access and retention are privacy-sensitive and require explicit authorization/audit behavior.
- External LiveKit/network calls use bounded timeouts/error handling and sanitized logs.
- User deletion cleanup/ownership transfer must preserve room invariants and avoid dangling private roster/contact data while retaining intentionally historical analytics only as defined by current code.
- Hashtag/chat integration must not break Discourse source ordering/context priority or expose inaccessible rooms.
- Plugin enable/disable and setting changes must leave statuses/LiveKit probes/default-room behavior consistent and idempotent.

## Implementation/tests/safety
Use current Discourse Chat/Guardian/Reviewable/Hashtag/admin/plugin APIs and LiveKit interfaces verified from source/current docs when version-sensitive. Make smallest maintainable changes, preserve server authority, use locale-backed copy, and avoid unrelated refactors. Voice/network/security/schema work should read matching skills. Never claim unrun tests passed.

Stop for unresolved room-access, recording/privacy, LiveKit/security, schema/migration, retention, or product semantics. Preserve unrelated work and `.claude/settings.local.json`; no force-push/reset/clean/branch deletion/deploy/destructive DB actions. Non-merge remote writes require explicit task authorization. Prefer targeted symbols/diffs over broad scans.

## CI-only merge gate
Claude/Gemini/Codex reviewer or verifier approval is not required and must never block merge. Do not request or wait for AI approvals as a merge condition.

For a normal scoped PR, the merge gate is CI only:
- validate exact changed paths still match the task;
- use only the latest exact PR head SHA;
- require the official `Discourse Plugin` CI workflow on that exact head to conclude GREEN;
- a new commit invalidates all older CI evidence;
- `NO_CI`, missing, skipped, pending, cancelled, neutral, stale-head, or failed checks are not GREEN.

When the latest exact head is GREEN and no unresolved security/schema/product/architecture blocker remains, the agent is pre-authorized to merge without another user confirmation. Prefer squash merge with `expected_head_sha` when supported. Never weaken tests or broaden scope just to obtain GREEN.

Reusable procedures live under `.agents/skills/` and load on demand; use `task-packet` for non-trivial work.

## Adaptive model / effort routing
Classify execution risk with `docs/ai/EFFORT_ROUTER.md` before broad reads. Start at the lowest sufficient tier: T0 mechanical, T1 routine, T2 high-risk, T3 exceptional. Escalate for risk/ambiguity rather than task size, and de-escalate when the risky phase ends. Use platform-native workers under `.claude/agents/` or `.codex/agents/` when supported; never trade away correctness, privacy, LiveKit security, or validation to save tokens.
