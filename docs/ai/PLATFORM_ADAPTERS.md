# Platform Adapters

`AGENTS.md` and `docs/ai/EFFORT_ROUTER.md` are canonical policy. Platform adapters contain runtime mechanics only.

| Tier | Purpose | Model class | Effort |
|---|---|---|---|
| T0 | Mechanical | cheapest capable | low |
| T1 | Routine implementation | balanced coding | medium |
| T2 | High-risk | strong reasoning | high |
| T3 | Exceptional | strongest available | highest justified |

Do not duplicate repo business invariants or volatile PR/CI state in adapters. If native model switching is unavailable, preserve tier classification and apply it at the session/orchestrator layer. If native effort control is unavailable, preserve narrow reads, bounded turns, targeted checks, and explicit escalation.
