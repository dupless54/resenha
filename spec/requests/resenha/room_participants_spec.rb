# frozen_string_literal: true

require "rails_helper"
require_relative "../../../db/migrate/20241107000000_create_resenha_rooms"

RSpec.describe "Resenha room participants" do
  fab!(:viewer) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:participant) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:staff, :admin)
  fab!(:room) { Fabricate(:resenha_room, creator: viewer, public: true) }

  before do
    ActiveRecord::Migration.suppress_messages do
      unless ActiveRecord::Base.connection.table_exists?(:resenha_rooms)
        CreateResenhaRooms.new.change
      end
    end
    Resenha::Room.reset_column_information

    SiteSetting.resenha_enabled = true
    SiteSetting.resenha_allowed_groups = Group::AUTO_GROUPS[:everyone]
  end

  it "preserves staff authority in participant refresh payloads" do
    Resenha::ParticipantTracker.add(room.id, participant.id)
    Resenha::ParticipantTracker.add(room.id, staff.id)
    sign_in(viewer)

    get "/resenha/rooms/#{room.id}/participants.json"

    expect(response.status).to eq(200)
    participants = response.parsed_body["participants"].index_by { |entry| entry["id"] }
    expect(participants[participant.id]["staff"]).to eq(false)
    expect(participants[staff.id]["staff"]).to eq(true)
  end
end
