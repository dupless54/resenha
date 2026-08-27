# Repository map

Use this to choose paths before searching. Source code remains authoritative if the map becomes stale.

- `plugin.rb` — plugin entrypoint/feature registration.
- `app/` — rooms, calls, memberships, controllers/models/jobs; read `app/AGENTS.md`.
- `lib/` — Guardian, LiveKit, service/integration logic; read `lib/AGENTS.md` only when that surface is touched.
- `admin/` — admin dashboard/API; read `admin/AGENTS.md`.
- `assets/javascripts/discourse/` — voice-room/direct-call frontend; read local `AGENTS.md`.
- `db/` — migrations/fixtures/schema; read `db/AGENTS.md`.
- `spec/` — Ruby/integration specs; read `spec/AGENTS.md`.
- `config/` — routes/settings/locales/configuration.
- `.github/workflows/discourse-plugin.yml` — reusable Discourse CI entrypoint.
- `docs/` — AI state/workflow and stable docs; do not preload wholesale.

Fast read order: root `AGENTS.md` -> task packet -> nearest local `AGENTS.md` -> exact symbol/source -> exact test. LiveKit/recording decisions stay on-demand for relevant tasks only.
