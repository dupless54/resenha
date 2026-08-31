# Current state

Baseline: this fork was reconciled against official `discourse/resenha` head `b87ca4e20d649ba6b7bdc4615b289c414854889e` (2026-08-28), then continued with local hardening, UX, moderation, and small-community policy work. As of 2026-09-01, `main` includes the locked-room invite admission fix merged at `d533d00acf225318804d53312fc5f44d718dbcba`.

Current runtime includes participant-session-bound signaling authority; bounded/rate-limited signaling; atomic Redis admission/capacity enforcement; hardened TURN/LiveKit credential boundaries; mesh receive-side media permissions; direct-call privacy checks; microphone failure UX; current transcript/sidebar behavior; and transport-independent room/session state.

Small-community mesh policy is now implemented on top of the authoritative admission contract: `resenha_max_room_participants` defaults to 4, the server enforces capacity, and the client/sidebar surface current capacity/full state. Do not reintroduce the superseded local `ParticipantTracker` capacity implementation from PR #12 or bypass the admission endpoint with client-only capacity logic.

Room moderation now includes manager kick, lock/unlock, and persistent per-room bans. A lock blocks genuinely new arrivals while preserving existing participants and managers. For locked rooms, a pending manager-issued invite is a one-use server-side admission grant for that room/user; the successful join consumes it server-side, so an old invite cannot become a permanent lock bypass. Durable bans remain authoritative over lock/invite state and evict active users through the shared participant cleanup contract.

Mesh resilience/UX includes local connection-quality status, explicit reconnecting state, and ICE credential refresh during reconnect. Join failures and authoritative capacity state are surfaced to users instead of failing silently.

Video/screen sharing is allowed by default at the site-setting layer (`resenha_video_enabled: true`), while individual rooms can still opt out. Mesh remains the default transport; LiveKit is optional and selected by the server's pinned transport policy.

Server-side recording exists only for calls pinned to LiveKit and only when `resenha_livekit_recording_enabled` is enabled. Recording uses LiveKit egress, broadcasts active recording state to the room, persists recording rows, finalizes through webhook/reconciliation paths, and delivers completed output through the requester/admin flow. Mesh calls are never server-side recorded.

Before new runtime work, inspect current branch/PR/source/tests. Durable high-risk boundaries: Guardian/server authorization controls rooms, calls, locks, bans, invites, and recordings; participant-session identity and server admission are authoritative; LiveKit/TURN credentials and tokens stay server-side and scoped; direct calls respect user privacy preferences; mesh media permissions remain server-attested; user-deletion and recording-retention semantics stay explicit.

Merge gate: use the official `Discourse Plugin` GitHub Actions result for the latest exact PR head. Missing, stale, skipped, cancelled, pending, neutral, or failed evidence is NOT GREEN; any new commit invalidates prior CI evidence.
