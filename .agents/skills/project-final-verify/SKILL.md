---
name: project-final-verify
description: Optionally perform an independent final verification for high-risk, ambiguous, or explicitly requested changes.
---
# Final verification
This skill is optional unless the current task explicitly requires it. Inspect the latest exact diff/source yourself and verify scope, trust/architecture boundaries, test evidence, and unresolved ambiguity. Return APPROVE, REJECT, or NEEDS_HUMAN. Approval never substitutes for required latest-head CI GREEN.
