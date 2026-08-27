---
name: task-packet
description: Compress a non-trivial task into the minimum execution context before broader reads.
---
# Task packet

Goal:
Allowed paths:
Relevant context:
Acceptance:
Validation:
Risk:

Rules:
- Keep the packet at 12 lines or fewer.
- Resolve locations from `docs/ai/REPO_MAP.md`; do not scan the repo first.
- Read `DECISIONS.md` only for room/privacy/LiveKit/architecture behavior; read `COMMANDS.md` only for validation.
- Prefer symbol/search -> targeted range -> dependency.
- Do not carry history or long reasoning into the packet.
- Reuse equivalent user-supplied scope/acceptance; skip the packet for trivial one-file, low-risk edits.
