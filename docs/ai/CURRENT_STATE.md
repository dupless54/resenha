# Current state

Compatibility baseline prepared on `sync/discourse-upstream-2026-08-28`: official `discourse/resenha` head `b87ca4e20d649ba6b7bdc4615b289c414854889e` (2026-08-28), plus this fork's local agent/minimum-token framework.

Current official runtime includes the post-fork upstream hardening and UX work: participant-session-bound signaling authority; bounded/rate-limited signaling; atomic Redis room admission with the upstream room-capacity ceiling; hardened LiveKit destinations and mesh receive-side media permissions; TURN quota plus join/broadcast/invite hardening; microphone failure UX; current transcript/sidebar behavior; and the current video default/spec baseline.

Do not reintroduce the superseded local `ParticipantTracker` capacity implementation from PR #12. The site's desired small-community policy remains a default of 4 participants for peer-to-peer use, but implement that only as a narrow policy/configuration layer on top of the current upstream capacity contract after the upstream sync is merged.

Before new runtime work, inspect current branch/PR/source/tests. Durable high-risk boundaries: Guardian/server authorization controls rooms/calls/recordings; participant-session identity and server admission are authoritative; LiveKit/TURN credentials and tokens stay server-side and scoped; direct calls respect user privacy preferences; mesh media permissions remain server-attested; user-deletion and recording retention semantics stay explicit.

CI note: this fork currently exposes the official workflow file but GitHub Actions has produced no workflow runs for new fork PR heads. Treat missing CI as NOT GREEN; do not merge runtime or documentation PRs under the CI-only policy until Actions is enabled/producing exact-head results.
