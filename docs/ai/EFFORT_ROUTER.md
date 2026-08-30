# Adaptive Model / Effort Router

Use the lowest-cost capability sufficient for the current risk.

## T0 — Mechanical
Exact lookup, rename/move, locale/string edits, formatting, metadata, generated annotations, obvious syntax repair, bounded CI-log classification.
Default: cheapest capable model, low effort, short tool/turn budget, no architecture exploration.

## T1 — Routine implementation
Ordinary bounded controller/service/frontend/spec work and normal bug fixes.
Default: balanced coding model, medium effort.

## T2 — High-risk reasoning
Authorization/IDOR, schema/migrations, persistence constraints, concurrency/idempotency, payments/refunds/balances, SSRF/network boundaries, privacy/non-enumeration, public APIs/contracts, cross-plugin integration, destructive operations.
Default: strongest practical reasoning model, high effort; expand context only around the risky boundary.

## T3 — Exceptional
Use only when targeted T2 investigation is insufficient, such as unresolved security/data-integrity defects or difficult multi-subsystem architecture conflicts.
Default: strongest available model, max/xhigh only when supported and justified.

## Routing rules
- Start at the lowest sufficient tier.
- Escalate for risk or ambiguity, not merely because a task is large.
- Escalate only the risky phase where practical.
- De-escalate after the risky phase is complete.
- Never use T2/T3 for bulk mechanical work.
- Avoid parallel agents unless independent work materially benefits from parallelism; subagents also consume tokens.
- Cost optimization must never weaken authorization, tests, persistence integrity, public contracts, CI evidence, security review, privacy, or destructive-operation safeguards.
- `NO_CI != GREEN`. A new commit invalidates old exact-head CI evidence.
