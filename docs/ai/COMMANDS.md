# Validation commands

Run from a Discourse checkout with this repository installed under `plugins/resenha`.

- One Ruby spec: `LOAD_PLUGINS=1 bin/rspec plugins/resenha/spec/path/to/example_spec.rb`
- Plugin Ruby specs: `bundle exec rake "plugin:spec[resenha]"`
- Plugin QUnit, when frontend tests are relevant: `CI=1 bundle exec rake "plugin:qunit[resenha]"`
- After plugin migration changes: `LOAD_PLUGINS=1 bundle exec rake db:migrate`

## CI source
`.github/workflows/discourse-plugin.yml` delegates to the reusable Discourse plugin CI workflow. Treat only the workflow result for the latest exact head SHA as CI evidence.

For LiveKit/room/security changes, start with the narrowest Guardian/service/request specs covering unauthorized/failure behavior before broader plugin tests.
