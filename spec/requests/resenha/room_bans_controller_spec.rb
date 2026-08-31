# frozen_string_literal: true

require "rails_helper"
require_relative "../../../db/migrate/20241107000000_create_resenha_rooms"
require_relative "../../../db/migrate/20260831080000_create_resenha_room_bans"

RSpec.describe Resenha::RoomBansController do
  fab!(:owner) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:other_user) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:room) { Fabricate(:resenha_room, creator: owner, public: true) }

  before do
    ActiveRecord::Migration.suppress_messages do
      unless ActiveRecord::Base.connection.table_exists?(:resenha_rooms)
        CreateResenhaRooms.new.change
      end
      unless ActiveRecord::Base.connection.table_exists?(:resenha_room_bans)
        CreateResenhaRoomBans.new.change
      end
    end
    Resenha::Room.reset_column_information
    Resenha::RoomBan.reset_column_information

    SiteSetting.resenha_enabled = true
    SiteSetting.resenha_allowed_groups = Group::AUTO_GROUPS[:everyone]
  end

  def establish_presence!(target_room, target_user)
    Resenha::ParticipantTracker.add(target_room.id, target_user.id)
    Resenha::ParticipantTracker.create_participant_session!(target_room.id, target_user.id)
  end

  describe "POST /resenha/rooms/:room_id/bans" do
    it "lets a room manager ban and evict an active participant" do
      participant_session_id = establish_presence!(room, user)
      sign_in(owner)

      post "/resenha/rooms/#{room.id}/bans.json", params: { user_id: user.id }

      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("ban", "user", "id")).to eq(user.id)
      expect(room.room_bans.exists?(user_id: user.id)).to eq(true)

      participant_ids = Resenha::ParticipantTracker.user_ids(room.id)
      expect(participant_ids).not_to include(user.id)

      sign_in(user)
      post "/resenha/rooms/#{room.id}/heartbeat.json",
           params: {
             participant_session_id: participant_session_id,
           }
      expect(response.status).to eq(403)

      post "/resenha/rooms/#{room.id}/join.json"
      expect(response.status).to eq(403)
      expect(response.parsed_body.to_s).to include(I18n.t("resenha.errors.room_banned"))
    end

    it "is idempotent for the same room and user" do
      sign_in(owner)

      2.times { post "/resenha/rooms/#{room.id}/bans.json", params: { user_id: user.id } }

      expect(response.status).to eq(200)
      expect(room.room_bans.where(user_id: user.id).count).to eq(1)
    end

    it "does not delete private-room membership" do
      room.update!(public: false)
      room.room_memberships.create!(
        user: user,
        role: Resenha::RoomMembership::ROLE_PARTICIPANT,
      )
      sign_in(owner)

      post "/resenha/rooms/#{room.id}/bans.json", params: { user_id: user.id }

      expect(response.status).to eq(200)
      expect(room.room_memberships.exists?(user_id: user.id)).to eq(true)
      expect(user.guardian.can_join_resenha_room?(room)).to eq(false)
    end

    it "rejects users who cannot manage the room" do
      sign_in(other_user)

      post "/resenha/rooms/#{room.id}/bans.json", params: { user_id: user.id }

      expect(response.status).to eq(403)
      expect(room.room_bans.exists?(user_id: user.id)).to eq(false)
    end

    it "rejects self, creator, staff, and room managers" do
      moderator = Fabricate(:user, trust_level: TrustLevel[2])
      room.room_memberships.create!(
        user: moderator,
        role: Resenha::RoomMembership::ROLE_MODERATOR,
      )
      admin = Fabricate(:admin)
      sign_in(owner)

      [owner, moderator, admin].each do |target|
        post "/resenha/rooms/#{room.id}/bans.json", params: { user_id: target.id }
        expect(response.status).to eq(400)
      end

      expect(room.room_bans.count).to eq(0)
    end

    it "rejects persistent bans in ephemeral call rooms" do
      ephemeral = Fabricate(:resenha_ephemeral_room, creator: owner, public: true)
      sign_in(owner)

      post "/resenha/rooms/#{ephemeral.id}/bans.json", params: { user_id: user.id }

      expect(response.status).to eq(400)
      expect(ephemeral.room_bans.exists?(user_id: user.id)).to eq(false)
    end
  end

  describe "GET /resenha/rooms/:room_id/bans" do
    it "lists bans only for room managers" do
      ban = room.room_bans.create!(user: user, banned_by: owner)
      sign_in(owner)

      get "/resenha/rooms/#{room.id}/bans.json"

      body = response.parsed_body
      expect(response.status).to eq(200)
      expect(body.dig("bans", 0, "id")).to eq(ban.id)
      expect(body.dig("bans", 0, "user", "username")).to eq(user.username)
      expect(body.dig("bans", 0, "banned_by", "username")).to eq(owner.username)

      sign_in(other_user)
      get "/resenha/rooms/#{room.id}/bans.json"
      expect(response.status).to eq(403)
    end
  end

  describe "DELETE /resenha/rooms/:room_id/bans/:id" do
    it "restores ordinary room admission without changing membership" do
      room.update!(public: false)
      room.room_memberships.create!(
        user: user,
        role: Resenha::RoomMembership::ROLE_PARTICIPANT,
      )
      ban = room.room_bans.create!(user: user, banned_by: owner)
      sign_in(owner)

      delete "/resenha/rooms/#{room.id}/bans/#{ban.id}.json"

      expect(response.status).to eq(204)
      expect(room.room_bans.exists?(id: ban.id)).to eq(false)
      expect(room.room_memberships.exists?(user_id: user.id)).to eq(true)

      sign_in(user)
      post "/resenha/rooms/#{room.id}/join.json"
      expect(response.status).to eq(200)
    end
  end
end
