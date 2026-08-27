---
name: project-security-review
description: Review room/call authorization, LiveKit tokens/secrets, privacy, external interfaces, replay, and recording access.
---
# Security review
Inspect exact diff. Check Guardian/IDOR, participant identity, direct-call preference bypass, LiveKit token scope/expiry/identity, secret leakage, webhook/external-state trust, network URL/TLS/timeouts, replay/races, rate limits, recording access/privacy, XSS/chat text, and logs. Report concrete evidence, not speculative blockers.
