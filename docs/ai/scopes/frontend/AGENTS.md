# Resenha frontend

- Client renders voice/call/room state but does not decide authorization.
- Treat transport/access tokens as sensitive ephemeral capabilities; do not persist/log/share them unnecessarily.
- Handle reconnect, join failure, permission denial, mute/deafen/device changes, and transport fallback explicitly.
- Never expose a room/call action merely by assuming client presence means permission; use server-provided authorized state.
- Escape room/user/chat text and follow current Discourse Chat/hashtag/Glimmer conventions.
- Voice UI must remain accessible and responsive; user-visible strings are localized.
- Large room/admin components should be inspected by exact symbol/section rather than whole-file reads by default.
