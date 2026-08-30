# frozen_string_literal: true

# The upstream rooms controller request suite contains deliberate 50-person
# signaling stress cases. Keep those fixtures independent from this fork's
# smaller production default. Stubbing the getter is intentional: Discourse's
# per-example SiteSetting reset can run after global before hooks, while RSpec's
# mock lifecycle still restores this override automatically after the example.
RSpec.configure do |config|
  config.before(:each) do |example|
    next if example.full_description.exclude?("Resenha::RoomsController#signal rate limits")

    allow(SiteSetting).to receive(:resenha_max_room_participants).and_return(50)
  end
end
