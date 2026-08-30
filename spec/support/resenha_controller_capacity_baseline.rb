# frozen_string_literal: true

# The upstream rooms controller request suite contains deliberate 50-person
# signaling stress cases. Keep that fixture size independent from this fork's
# smaller production default; examples that exercise the site ceiling already
# override the setting explicitly.
RSpec.configure do |config|
  config.before(
    :each,
    file_path: %r{/plugins/resenha/spec/requests/resenha/rooms_controller_spec\.rb\z},
  ) { SiteSetting.resenha_max_room_participants = 50 }
end
