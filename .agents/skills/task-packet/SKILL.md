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
Effort tier:
Escalation trigger:

Rules:
- Target 12 lines or fewer, but exceed that target whenever correctness, privacy/security, LiveKit/recording semantics, or acceptance detail would otherwise be lost.
- Resolve locations from `docs/ai/REPO_MAP.md` first; it is a navigation hint, never authority. If stale or inconsistent with current source/tests, use targeted search and trust current source/tests.
- Read `DECISIONS.md` only for room/privacy/LiveKit/architecture behavior; read `COMMANDS.md` only for validation.
- Prefer symbol/search -> targeted range -> dependency.
- Minimum context is adaptive, not fixed: if a change crosses room/call authorization, LiveKit tokens/network, recording/privacy, schema/persistence, public API/integration, cleanup, or another subsystem boundary, load the relevant local `AGENTS.md`, source, contract/integration code, and tests.
- Select T0/T1/T2/T3 from `docs/ai/EFFORT_ROUTER.md` before broad reads. Use a platform-native worker when supported and useful; do not spawn parallel workers unless tasks are genuinely independent.
- Do not carry history or long reasoning into the packet.
- Reuse equivalent user-supplied scope/acceptance; skip the packet for trivial one-file, low-risk edits.
- Absence of CI is never GREEN. When no required workflow/check exists, use targeted validation plus exact diff/scope validation and report `NO_CI`/`NOT_RUN` honestly.
- Correctness, privacy, and safety outrank token savings; expand context when evidence is insufficient.
