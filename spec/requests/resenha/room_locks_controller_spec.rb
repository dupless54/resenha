# frozen_string_literal: true

require "rails_helper"
require_relative "../../../db/migrate/20241107000000_create_resenha_rooms"
require_relative "../../../db/migrate/20260831061000_add_locked_to_resenha_rooms"

RSpec.describe Resenha::RoomLocksController do
  fab!(:owner) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:room) { Fabricate(:resenha_room, creator: owner, public: true) }

  before do
    ActiveRecord::Migration.suppress_messages do
      unless ActiveRecord::Base.connection.table_exists?(:resenha_rooms)
        CreateResenhaRooms.new.change
      end
      unless ActiveRecord::Base.connection.column_exists?(:resenha_rooms, :locked)
        AddLockedToResenhaRooms.new.change
      end
    end
    Resenha::Room.reset_column_information

    SiteSetting.resenha_enabled = true
    SiteSetting.resenha_allowed_groups = Group::AUTO_GROUPS[:everyone]
  end

  def establish_presence!(target_room, target_user)
    Resenha::ParticipantTracker.add(target_room.id, target_user.id)
    Resenha::ParticipantTracker.create_participant_session!(target_room.id, target_user.id)
  end

  describe "PUT /resenha/rooms/:room_id/lock" do
    it "lets a room manager lock the room and serializes the state" do
      sign_in(owner)

      put "/resenha/rooms/#{room.id}/lock.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("room", "locked")).to eq(true)
      expect(room.reload).to be_locked
    end

    it "rejects a user who cannot manage the room" do
      sign_in(user)

      put "/resenha/rooms/#{room.id}/lock.json"

      expect(response.status).to eq(403)
      expect(room.reload).not_to be_locked
    end

    it "rejects locking an ephemeral call room even for its manager" do
      ephemeral = Fabricate(:resenha_ephemeral_room, creator: owner, public: true)
      sign_in(owner)

      put "/resenha/rooms/#{ephemeral.id}/lock.json"

      expect(response.status).to eq(400)
      expect(ephemeral.reload).not_to be_locked
    end
  end

  describe "locked room admission" do
    before { room.update!(locked: true) }

    it "keeps a public room visible but rejects a fresh participant" do
      sign_in(user)

      get "/resenha/rooms/#{room.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("room", "locked")).to eq(true)
      expect(response.parsed_body.dig("room", "can_invite")).to eq(false)

      post "/resenha/rooms/#{room.id}/join.json"

      expect(response.status).to eq(403)
      expect(response.parsed_body.to_s).to include(I18n.t("resenha.errors.room_locked"))
      expect(Resenha::ParticipantTracker.user_ids(room.id)).not_to include(user.id)
    end

    it "lets an already-present participant take over or refresh their join" do
      establish_presence!(room, user)
      sign_in(user)

      post "/resenha/rooms/#{room.id}/join.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["participant_session_id"]).to be_present
      expect(Resenha::ParticipantTracker.user_ids(room.id)).to include(user.id)
    end

    it "does not break heartbeat or leave for a participant who was present before the lock" do
      participant_session_id = establish_presence!(room, user)
      sign_in(user)

      post "/resenha/rooms/#{room.id}/heartbeat.json",
           params: {
             participant_session_id: participant_session_id,
           }
      expect(response.status).to eq(204)

      delete "/resenha/rooms/#{room.id}/leave.json",
             params: {
               participant_session_id: participant_session_id,
             }
      expect(response.status).to eq(204)
      expect(Resenha::ParticipantTracker.user_ids(room.id)).not_to include(user.id)
    end

    it "lets a room manager join and invite while locked" do
      sign_in(owner)

      get "/resenha/rooms/#{room.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("room", "can_invite")).to eq(true)

      post "/resenha/rooms/#{room.id}/join.json"
      expect(response.status).to eq(200)
    end
  end

  describe "DELETE /resenha/rooms/:room_id/lock" do
    it "unlocks the room and restores ordinary admission" do
      room.update!(locked: true)
      sign_in(owner)

      delete "/resenha/rooms/#{room.id}/lock.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("room", "locked")).to eq(false)
      expect(room.reload).not_to be_locked

      sign_in(user)
      post "/resenha/rooms/#{room.id}/join.json"
      expect(response.status).to eq(200)
    end
  end
end
