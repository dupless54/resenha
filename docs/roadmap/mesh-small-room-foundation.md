# Mesh Small-Room Foundation

Resenha's default peer-to-peer transport is optimized for small community voice rooms where avoiding a media-server dependency is more important than supporting large calls.

## Current baseline

- `resenha_mesh_max_participants` defaults to **4** and is the site-wide safety ceiling for mesh calls.
- A room-level `max_participants` value may lower that ceiling but cannot raise it for mesh transport.
- LiveKit-routed calls keep using the room-level capacity and are not constrained by the mesh ceiling.
- Admission is enforced server-side in `ParticipantTracker`, never only in the client.
- New participant admission is serialized with `DistributedMutex` so simultaneous joins cannot overfill the final slot.
- Existing participant heartbeat refreshes stay on the lock-free hot path.
- Serialized rooms expose `effective_max_participants` and `full` for native client UX.

## Next compatibility slice

1. Surface `full` and `effective_max_participants` in the sidebar and room page using existing Discourse UI primitives and locale-backed copy.
2. Surface join failures through Discourse's standard Ajax error UX instead of console-only failure handling.
3. Add connection-health telemetry from `RTCPeerConnection.getStats()` without sending media or private ICE details to the server.
4. Add bounded ICE restart/reconnect behavior for recoverable network changes.
5. Cover the user-facing flow with QUnit/system tests before widening the feature set.

The server remains authoritative throughout; client-side capacity display is informational UX, not an authorization or integrity boundary.
