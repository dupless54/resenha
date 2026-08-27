---
name: project-ci-repair
description: Repair a failing latest-head CI check with bounded, minimum-scope remediation.
---
# CI repair
Inspect the failing job and identify the first actionable root cause. Classify code, test/fixture, dependency, or infrastructure/transient failure. Make only the smallest justified repair and run targeted validation. Push a new exact head and require CI again for that new SHA; old CI evidence is invalid after any change. Never weaken tests or broaden architecture/product scope just to get green. Maximum automatic repair rounds: 3. After 3 unresolved rounds, or when a material architecture/security/schema/product decision is required, return `NEEDS_HUMAN` with concise evidence.
