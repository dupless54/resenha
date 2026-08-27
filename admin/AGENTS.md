# Resenha admin

- Admin dashboard is UX; server admin endpoints remain authorization authority.
- Never expose full LiveKit secrets/tokens or sensitive recording/access credentials in admin JSON/logs.
- Room management, recordings, diagnostics, and status probes require staff/admin checks appropriate to existing code.
- Destructive recording/room actions need explicit intent and clear failure states; do not optimistic-update authoritative state without server success.
- Follow current Discourse admin plugin routing/Glimmer conventions.
