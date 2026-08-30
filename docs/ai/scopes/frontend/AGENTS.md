# Resenha frontend

Apply `docs/ai/DISCOURSE_DEVELOPER_BASELINE.md` for the task-relevant current Discourse frontend rules; do not rely on remembered Ember/Discourse syntax when an API may have changed.

- Client renders voice/call/room state but does not decide authorization, membership, room capacity, moderation, recording rights, or transport eligibility.
- Treat transport/access tokens and ICE credentials as sensitive ephemeral capabilities; do not persist/log/share them unnecessarily.
- Handle connecting, reconnecting, join failure, permission denial, room-full state, mute/deafen/device changes, ICE restart, and transport failure/fallback explicitly.
- Never expose or execute a room/call action merely by assuming client presence means permission; use server-provided authorized state and let the server reject stale state.
- Prefer current Glimmer `.gjs`/`.gts`, injected services, Discourse UI-kit primitives, FormKit, Plugin API/Transformers/Plugin Outlets, and locale-backed copy before custom equivalents or invasive core hooks.
- Prefer `lib/viewport` / `lib/container`, Discourse breakpoint vocabulary, theme variables, scoped BEM-style CSS, and native responsive behavior. Do not use hover as the only path to any voice control.
- Voice controls must remain keyboard/touch accessible, have usable focus/pressed/disabled states, support narrow phones/safe areas, and not communicate connection/speaking/error state by color alone.
- Escape room/user/chat text and follow current Discourse Chat/hashtag/profile/Glimmer conventions.
- Preserve the persistent-call experience across normal Discourse navigation without introducing standalone full-screen shells or broad core template overrides.
- Add targeted QUnit/acceptance coverage for meaningful interaction/state regressions; use system specs when browser integration/layout behavior is the thing being protected.
- Large room/admin components should be inspected by exact symbol/section rather than whole-file reads by default.
