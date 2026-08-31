# frozen_string_literal: true

require "rails_helper"
require_relative "../../../db/migrate/20241107000000_create_resenha_rooms"
require_relative "../../../db/migrate/20260612135211_add_video_enabled_to_resenha_rooms"
require_relative "../../../db/migrate/20260630183841_add_chat_settings_to_resenha_rooms"

RSpec.describe Resenha::IceController do
  before do
    ActiveRecord::Migration.suppress_messages do
      unless ActiveRecord::Base.connection.table_exists?(:resenha_rooms)
        CreateResenhaRooms.new.change
      end
      unless ActiveRecord::Base.connection.column_exists?(:resenha_rooms, :video_enabled)
        AddVideoEnabledToResenhaRooms.new.change
      end
      unless ActiveRecord::Base.connection.column_exists?(:resenha_rooms, :chat_channel_id)
        AddChatSettingsToResenhaRooms.new.change
      end
    end
    Resenha::Room.reset_column_information

    SiteSetting.resenha_enabled = true
    SiteSetting.resenha_allowed_groups = Group::AUTO_GROUPS[:everyone]
  end

  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:room) { Fabricate(:resenha_room, public: true) }

  def create_participant_grant!(transport: "mesh")
    session_id = Resenha::ParticipantTracker.create_participant_session!(room.id, user.id)
    Resenha::ParticipantTracker.pin_transport!(room.id, transport)
    session_id
  end

  it "returns fresh ICE for an authorized mesh participant without recreating presence" do
    sign_in(user)
    create_participant_grant!
    fresh_ice = {
      servers: [{ urls: "turn:relay.example.test", username: "fresh", credential: "secret" }],
      transport_policy: "all",
    }
    allow(Resenha::IceConfig).to receive(:payload).with(user).and_return(fresh_ice)

    post "/resenha/rooms/#{room.id}/ice.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["ice"]).to eq(fresh_ice.as_json)
    expect(Resenha::ParticipantTracker.participant_session?(room.id, user.id)).to eq(true)
    expect(Resenha::ParticipantTracker.user_ids(room.id)).not_to include(user.id)
  end

  it "rejects a user without a live participant grant" do
    sign_in(user)
    Resenha::ParticipantTracker.pin_transport!(room.id, "mesh")

    post "/resenha/rooms/#{room.id}/ice.json"

    expect(response.status).to eq(403)
  end

  it "returns conflict when the live room instance is pinned to LiveKit" do
    sign_in(user)
    create_participant_grant!(transport: "livekit")

    post "/resenha/rooms/#{room.id}/ice.json"

    expect(response.status).to eq(409)
  end

  it "returns gone when the room instance no longer has a transport pin" do
    sign_in(user)
    Resenha::ParticipantTracker.create_participant_session!(room.id, user.id)

    post "/resenha/rooms/#{room.id}/ice.json"

    expect(response.status).to eq(410)
  end
end
