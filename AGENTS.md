# Resenha Agent Router

Canonical instructions for ChatGPT/Codex, Claude, and Gemini.

## Authority and context routing

When information conflicts: current source/tests > `docs/ai/CURRENT_STATE.md` or active work `state.md` > nearest local `AGENTS.md` > stable architecture/docs > plans/history.

Always read this file, then only the nearest local rules for areas actually inspected or changed:
- rooms/calls/models/controllers/jobs -> `app/AGENTS.md`
- Guardian/LiveKit/services/integration -> `lib/AGENTS.md`
- admin dashboard -> `admin/AGENTS.md`
- Discourse/Glimmer voice-room UI -> `docs/ai/scopes/frontend/AGENTS.md`
- schema/fixtures -> `db/AGENTS.md`
- tests -> `spec/AGENTS.md`

For multi-session work, read the active `docs/ai/work/<feature>/state.md` first and only the relevant implementation-plan section. Use the minimal three-file work packet; do not preload completed phases or unrelated docs.

## Current Discourse upstream baseline

For any Discourse API, UI, routing, responsive, testing, serialization, autoloading, compatibility, admin, Chat, hashtag, profile, or plugin-extension decision, apply `docs/ai/DISCOURSE_DEVELOPER_BASELINE.md` and read only the task-relevant section. Current Discourse core and current official developer docs outrank remembered syntax and old tutorial examples.

Default architecture direction:
- modern Glimmer `.gjs`/`.gts` + injected services;
- Discourse UI-kit (`DModal`, `DButton`, etc.) and FormKit before custom equivalents;
- supported Plugin API / Transformers / Plugin Outlets before `modifyClass`; core template override is an exceptional last resort;
- `lib/viewport` and `lib/container` for responsive work; touch/hover are capabilities and hover is never the only interaction path;
- BEM-style scoped CSS, locale-backed UI copy, QUnit/system-spec coverage for meaningful UI behavior;
- thin controllers + service objects, explicit serializers/presenters, and Rails/Zeitwerk autoloading conventions on the backend;
- official exact-head Discourse CI and `d-compat` when old-release pinning is actually required.

If an upstream API may have changed, verify current Discourse core or the current official guide before coding. Do not introduce a deprecated pattern just because an older plugin still uses it.

## Fast task path

For non-trivial work, use `.agents/skills/task-packet/SKILL.md` before broad reads. Use `docs/ai/REPO_MAP.md` to locate code, `COMMANDS.md` only when validation is needed, and `DECISIONS.md` only for room/privacy/LiveKit/architecture choices. Skip the formal packet for trivial one-file edits.

## Voice/privacy/security invariants

Resenha provides WebRTC voice rooms/direct calls inside Discourse, with optional LiveKit transport, room membership/access, moderation/reviewables, recordings/admin surfaces, hashtags/chat integration, presence/status behavior, analytics, and transport-independent room state.

- Guardian/server policy is authoritative for room access, join/call permissions, moderation, membership, recording/admin actions, and transport eligibility. Client visibility is UX only.
- Direct calls must continue to respect target mute/ignore/personal-message/callability policy and must not allow self/bot/unauthorized calls.
- Mesh signaling may relay SDP/ICE metadata, but media must remain on the documented peer-to-peer path unless the room is explicitly using the authorized LiveKit transport.
- LiveKit API key/secret, server credentials, tokens, signing material, webhook/internal credentials, TURN secrets, and transport secrets never reach ordinary client payloads/logs.
- LiveKit tokens are short-lived/scoped capabilities created only after authorization; do not trust room/user identity from client input.
- Recording metadata/media access and retention are privacy-sensitive and require explicit authorization/audit behavior.
- External LiveKit/TURN/network calls use bounded timeouts/error handling, bounded work, and sanitized logs.
- User deletion cleanup/ownership transfer must preserve room invariants and avoid dangling private roster/contact data while retaining intentionally historical analytics only as defined by current code.
- Hashtag/chat integration must not break Discourse source ordering/context priority or expose inaccessible rooms.
- Plugin enable/disable and setting changes must leave statuses, transport probes, default-room behavior, and presence cleanup consistent and idempotent.
- Reconnect/fallback behavior must never silently bypass authorization, privacy warnings, room capacity, or transport policy.

## Native Discourse UI invariant

Resenha surfaces must feel like part of Discourse. Use the normal Discourse shell and navigation, core UI primitives where practical, Discourse theme variables, accessible semantics, responsive layout, and current Glimmer/Ember patterns. Do not ship route-specific full-screen resets, hard-coded standalone palettes, hover-only controls, or core template overrides when a supported plugin API/native primitive exists.

Voice/call controls must remain usable on keyboard and touch, survive narrow mobile widths and safe areas, and expose clear connected/connecting/reconnecting/denied/error states instead of relying on color alone.

## Implementation, tests, and safety

Use current Discourse Chat/Guardian/Reviewable/Hashtag/admin/plugin APIs and current browser media/WebRTC interfaces verified from source/current docs when version-sensitive. Make the smallest maintainable changes, preserve server authority, use locale-backed copy, and avoid unrelated refactors.

For changed behavior cover the smallest relevant set: happy path, authorization failure, invalid input/state, reconnect/failure behavior, duplicate/replay/idempotency or concurrency behavior when relevant, and privacy/security boundaries for transport/recording work. Voice/network/security/schema work should read matching on-demand skills. Never claim a test passed unless it actually ran; unavailable checks are `NOT RUN`.

Stop for unresolved room-access, recording/privacy, LiveKit/TURN/security, schema/migration, retention, public-contract, or product semantics. Preserve unrelated work and `.claude/settings.local.json`; never force-push, reset/clean, delete branches, deploy, or make destructive DB changes.

## CI-only merge gate

Claude/Gemini/Codex reviewer or verifier approval is not required and must never block merge. Do not request or wait for AI approvals as a merge condition.

For a normal scoped PR, merge eligibility is determined from the latest exact PR head SHA:
- validate the exact changed paths still match the task;
- require the official `Discourse Plugin` CI workflow on that exact head to exist, run, and conclude GREEN;
- if the repository exposes any additional required Discourse-owned CI/check context, it must also be GREEN;
- a new commit invalidates all older CI evidence;
- `NO_CI`, missing, skipped, pending, cancelled, neutral, stale-head, or failed checks are not GREEN.

When the latest exact head is GREEN and no unresolved privacy/security/schema/product/architecture blocker remains, the agent is pre-authorized to merge without asking for another user confirmation. Prefer squash merge with `expected_head_sha` when supported. Never weaken tests or broaden scope just to obtain GREEN.

## Token discipline

Minimum unnecessary tokens, not minimum reasoning. Prefer exact symbols, paths, targeted source ranges, diffs, failing assertions, and scoped logs over broad scans or repeated whole-file summaries. Read the nearest local rules and target source/tests first; fetch upstream documentation only for the version-sensitive choice currently being made.

## On-demand skills

Reusable procedures live under `.agents/skills/`. Read only the skill matching the task: `task-packet`, `project-plan`, `project-implement`, `project-review`, `project-final-verify`, `project-ci-repair`, `project-schema-review`, `project-security-review`, or `project-update-state`.

## Adaptive model / effort routing

Classify execution risk with `docs/ai/EFFORT_ROUTER.md` before broad reads. Start at the lowest sufficient tier: T0 mechanical, T1 routine, T2 high-risk, T3 exceptional. Escalate for risk/ambiguity rather than task size, and de-escalate when the risky phase ends. Use platform-native workers under `.claude/agents/` or `.codex/agents/` when supported; never trade away correctness, privacy, transport security, or validation to save tokens.

## Live Discourse developer source gate

Canonical live upstream index: https://meta.discourse.org/t/developer-guides-index/308036?tl=en

For any Discourse-version-sensitive implementation, refactor, review, or compatibility decision:
- start at the live Developer Guides Index and open only the task-relevant official topic(s);
- for Resenha plugin work prioritize **Code & Internals + Plugins**; use environment/general guides only when relevant;
- verify version-sensitive APIs and deprecations against current `discourse/discourse` core or the current official plugin skeleton before coding when needed;
- current official docs/core beat remembered examples, old snippets, and copied local guidance unless the repository deliberately targets an older validated release via `.discourse-compatibility` / `d-compat`;
- do not preload the full index: read the nearest local rules and target source/tests first, then fetch only the upstream guide(s) needed for the current choice.
