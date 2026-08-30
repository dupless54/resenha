# Current Discourse Developer Baseline

This is the canonical upstream-development baseline for AI agents working in Resenha. Keep local `AGENTS.md` files short and task-scoped; they point here for detailed cross-cutting Discourse rules.

## Authority order

1. Current Resenha source/tests and explicit project invariants.
2. Current Discourse core source and current official Discourse developer documentation.
3. Current official Meta Discourse developer guides.
4. Older tutorial posts only for concepts when they do not conflict with current core/docs.

Discourse changes quickly. Before introducing or refactoring an API integration, verify the API against current Discourse core or the current official guide instead of relying on remembered syntax. Do not copy deprecated patterns from old plugins merely because they still compile.

## Frontend architecture

- Prefer modern Glimmer components in `.gjs`; use `.gts`/TypeScript where type safety materially helps complex state or payload contracts.
- Use Ember service injection (`@service`) in components/routes/controllers. Do not introduce deprecated ownership helpers when normal injection is available.
- Use Discourse UI-kit primitives before custom equivalents. In particular, use `DModal` for modal/dialog behavior and `Form`/FormKit for forms and validation where applicable.
- Modal code must let `DModal` own focus trapping, backdrop, Escape behavior, keyboard/mobile viewport handling, safe areas, and core accessibility semantics unless a documented requirement proves otherwise.
- FormKit fields should use the supported `field.Control` API, built-in validation where suitable, and explicit submit/error states.
- Prefer locale-backed user-visible copy. Do not spread new hard-coded UI strings when the surface is meant for production.
- Keep authorization, room/call eligibility, moderation, recording rights, and transport capability decisions server-authoritative; client state is presentation and interaction state only.

## Extending Discourse without fighting core

Use the least invasive supported extension point that solves the problem:

1. existing Discourse/plugin API or UI-kit primitive;
2. value/behavior Transformer;
3. Plugin Outlet / connector;
4. narrowly scoped `modifyClass` only when no supported API exists;
5. core template override only as an exceptional, documented last resort.

Do not override an entire core template for ordinary customization. `modifyClass` is not a default technique; it couples the plugin to core implementation details. When a Transformer or outlet exists, prefer it.

Use AppEvents for genuinely decoupled cross-tree events, not as a substitute for normal component arguments/actions/services.

## Responsive and interaction design

- Use Discourse responsive helpers from `lib/viewport` for viewport-level behavior.
- Use `lib/container` / container queries when a component should respond to its own available width rather than the whole browser viewport.
- Prefer the Discourse breakpoint vocabulary (`xs`, `sm`, `md`, `lg`, `xl`, `2xl`) over new one-off pixel breakpoints. A raw breakpoint is acceptable only when the component has a documented non-standard physical constraint.
- Do not use `.mobile-view` / `.desktop-view` as the primary responsive design system. Design from width/capability first.
- Touch/hover are capabilities, not device identities. Hover may enhance UX but must never be the only way to reveal or execute an action. Every hover interaction needs a usable tap/click/focus path.
- Keep interactive targets usable on touch screens and keyboard-accessible.
- Use Discourse/core CSS variables and BEM-style project classes. Avoid global selectors and broad overrides that leak outside the plugin.
- Support narrow phones, tablets, compact desktop windows, large text, light/dark themes, safe areas, and reduced-motion behavior relevant to the changed surface.
- For drag/resize/gesture features, prefer Discourse gesture primitives and provide a keyboard-accessible alternative.
- Voice controls must remain operable without hover and must expose meaningful focus/pressed/disabled states.

## Testing and performance

- Add QUnit component/acceptance coverage for meaningful frontend behavior and regression-prone interactions.
- Run the plugin QUnit suite through Discourse (`bin/rake "plugin:qunit[resenha]"`) when frontend tests exist.
- Use end-to-end system specs for workflows where browser layout/interaction integration matters. Prefer assertions that wait on observable DOM state; do not add arbitrary sleeps.
- Keep backend RSpec coverage for authorization, service/business behavior, retries/idempotency, privacy/security boundaries, and failure paths.
- WebRTC/transport changes should cover reconnect/failure/permission-denied state and should not silently downgrade security or authorization behavior.
- For a claimed JS performance improvement, measure it with a reproducible benchmark; Discourse guidance uses Tachometer for comparative JS performance work.
- CI evidence is valid only for the exact PR head. A new commit invalidates earlier GREEN evidence.

## Backend architecture

- Keep controllers thin. Coordinate non-trivial business flows through service objects rather than growing controller/model callback orchestration.
- Keep authoritative room access, callability, moderation, recording, membership, and transport decisions on the server.
- Do not accidentally serialize ActiveRecord models. Prefer an explicit serializer/presenter or an intentional field hash. Never expose a model wholesale simply because `render json: model` is convenient.
- Structure Rails code so Zeitwerk/Rails autoloading can load app classes. Avoid expanding `plugin.rb` into a manual `require_relative` registry for application code that can live under conventional engine/app paths.
- New routes and data-loading flows should follow current Discourse plugin routing/controller conventions and retain server-side authorization.
- External network/media-service calls require bounded timeouts, bounded work, sanitized logs, and explicit error handling.

## Compatibility and release discipline

- When supporting older Discourse releases, prefer the current `d-compat/YYYY.M` branch strategy. Treat older compatibility mechanisms as fallback/legacy unless current upstream guidance says otherwise.
- Use the official Discourse GitHub Actions plugin workflow and keep required exact-head checks GREEN before merge.
- Lint/format with the Discourse toolchain; do not hand-wave lint/type/template failures.

## Feature-specific upstream guidance

Use these only when the task touches the area:

- Markdown extensions: follow the current Markdown extension developer guide; avoid ad-hoc cooked-post DOM mutation when an extension hook exists.
- Authentication: follow the current managed-authentication provider API and security model.
- Chat integrations: follow the current discourse-chat-integration provider extension model and current Discourse Chat APIs.
- Topic-list customization: prefer the current topic-list customization APIs/Transformers rather than overriding topic-list templates.
- New locales: follow the plugin locale registration guide and keep locale files lint-clean.
- Admin surfaces: prefer current Discourse admin/plugin APIs and UI-kit patterns rather than standalone admin shells.
- Hashtag/profile/presence integration: verify current core contracts before coupling to internal implementation details.
- Browser media/WebRTC behavior: when browser-version-sensitive, verify the current WebRTC/media-device contract and preserve Resenha's documented privacy/transport invariants.

## Official Discourse references

Canonical live index: https://meta.discourse.org/t/developer-guides-index/308036?tl=en

### Code and internals

- Ember components: https://meta.discourse.org/t/-/48891
- Lint/format before commits: https://meta.discourse.org/t/-/132947
- Acceptance/component tests: https://meta.discourse.org/t/-/49167
- Running core/plugin/theme QUnit suites: https://meta.discourse.org/t/-/66857
- Version compatibility / d-compat: https://meta.discourse.org/t/-/272665
- Ember ownership and service injection: https://meta.discourse.org/t/-/292080
- JS performance / Tachometer: https://meta.discourse.org/t/-/281158
- GitHub Actions CI: https://meta.discourse.org/t/-/240150
- Markdown extensions: https://meta.discourse.org/t/-/66023
- Converting legacy modals: https://meta.discourse.org/t/-/268057
- DModal API: https://meta.discourse.org/t/-/268304
- JS API: https://meta.discourse.org/t/-/41281
- Plugin outlets/connectors: https://meta.discourse.org/t/-/32727
- `modifyClass`: https://meta.discourse.org/t/-/262064
- Routes/data: https://meta.discourse.org/t/-/48827
- Managed authentication methods: https://meta.discourse.org/t/-/106695
- Preventing accidental ActiveRecord serialization: https://meta.discourse.org/t/-/314495
- Core template overrides (not recommended): https://meta.discourse.org/t/-/247487
- Service objects: https://meta.discourse.org/t/-/333641
- UI system specs: https://meta.discourse.org/t/-/325937
- FormKit: https://meta.discourse.org/t/-/326439
- AppEvents reference: https://meta.discourse.org/t/-/338465
- Transformers: https://meta.discourse.org/t/-/349954
- Topic-list customization: https://meta.discourse.org/t/-/350411
- BEM CSS guidance: https://meta.discourse.org/t/-/361851
- JavaScript type checking / TypeScript: https://meta.discourse.org/t/-/395136
- Designing for devices / touch / hover: https://meta.discourse.org/t/-/367810
- Responsive widths / viewport / containers: https://meta.discourse.org/t/-/409279
- Drag/resize/gesture primitives: https://meta.discourse.org/t/-/410549

### Plugin development

- Basic plugin: https://meta.discourse.org/t/-/30515
- Plugin outlet: https://meta.discourse.org/t/-/31001
- Site settings: https://meta.discourse.org/t/-/31115
- Git setup: https://meta.discourse.org/t/-/31272
- Admin interface: https://meta.discourse.org/t/-/31761
- Acceptance tests: https://meta.discourse.org/t/-/32619
- Publishing a plugin: https://meta.discourse.org/t/-/101636
- Adding a locale from a plugin: https://meta.discourse.org/t/-/78962
- Chat integration provider: https://meta.discourse.org/t/-/68156
- Repackaging markdown-it extensions: https://meta.discourse.org/t/-/84614
- Rails autoloading / Zeitwerk: https://meta.discourse.org/t/-/256092

When an old tutorial and current core disagree, current core/current official developer docs win.