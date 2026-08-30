# Mesh Small-Room Foundation — State

Status: implementation PR ready for CI.

Implemented:
- transport-aware room capacity;
- site-wide mesh ceiling, default 4;
- server-authoritative, race-safe admission using `DistributedMutex`;
- lock-free existing-member heartbeat refresh;
- effective capacity/full state in room serialization;
- English and Turkish site-setting/error copy;
- service/model regression specs.

Next:
- Discourse-native full-room UX in sidebar/room page;
- standard Ajax error surfacing for join failures;
- WebRTC connection health and bounded reconnect/ICE restart.

Merge gate: exact PR head official `Discourse Plugin` CI must be GREEN. AI reviewer approval is not a gate.
