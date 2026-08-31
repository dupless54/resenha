# frozen_string_literal: true

require "rails_helper"
require_relative "../../../db/migrate/20241107000000_create_resenha_rooms"

RSpec.describe Resenha::RoomKicksController do
  fab!(:owner) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:other_user) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:room) { Fabricate(:resenha_room, creator: owner, public: true) }

  before do
    ActiveRecord::Migration.suppress_messages do
      unless ActiveRecord::Base.connection.table_exists?(:resenha_rooms)
        CreateResenhaRooms.new.change
      end
    end
    Resenha::Room.reset_column_information
    Resenha::RoomMembership.reset_column_information

    SiteSetting.resenha_enabled = true
    SiteSetting.resenha_allowed_groups = Group::AUTO_GROUPS[:everyone]
  end

  def establish_presence!(target_user)
    Resenha::ParticipantTracker.add(room.id, target_user.id)
    Resenha::ParticipantTracker.create_participant_session!(room.id, target_user.id)
  end

  it "lets a room manager kick an ordinary active participant" do
    establish_presence!(user)
    sign_in(owner)

    delete "/resenha/rooms/#{room.id}/kick.json", params: { user_id: user.id }

    expect(response.status).to eq(204)
    expect(Resenha::ParticipantTracker.user_ids(room.id)).not_to include(user.id)
    expect(Resenha::ParticipantTracker.recently_left?(room.id, user.id)).to eq(true)
  end

  it "rejects users who cannot manage the room" do
    establish_presence!(user)
    sign_in(other_user)

    delete "/resenha/rooms/#{room.id}/kick.json", params: { user_id: user.id }

    expect(response.status).to eq(403)
    expect(Resenha::ParticipantTracker.user_ids(room.id)).to include(user.id)
  end

  it "protects room moderators from being kicked" do
    moderator = Fabricate(:user, trust_level: TrustLevel[2])
    room.room_memberships.create!(user: moderator, role: Resenha::RoomMembership::ROLE_MODERATOR)
    establish_presence!(moderator)
    sign_in(owner)

    delete "/resenha/rooms/#{room.id}/kick.json", params: { user_id: moderator.id }

    expect(response.status).to eq(400)
    expect(response.parsed_body.to_s).to include(I18n.t("resenha.errors.cannot_kick_manager"))
    expect(Resenha::ParticipantTracker.user_ids(room.id)).to include(moderator.id)
  end

  it "protects site staff from being kicked" do
    admin = Fabricate(:admin)
    establish_presence!(admin)
    sign_in(owner)

    delete "/resenha/rooms/#{room.id}/kick.json", params: { user_id: admin.id }

    expect(response.status).to eq(400)
    expect(response.parsed_body.to_s).to include(I18n.t("resenha.errors.cannot_kick_manager"))
    expect(Resenha::ParticipantTracker.user_ids(room.id)).to include(admin.id)
  end

  it "keeps self and room-creator kick protections" do
    manager = Fabricate(:user, trust_level: TrustLevel[2])
    room.room_memberships.create!(user: manager, role: Resenha::RoomMembership::ROLE_MODERATOR)
    sign_in(manager)

    delete "/resenha/rooms/#{room.id}/kick.json", params: { user_id: manager.id }
    expect(response.status).to eq(400)
    expect(response.parsed_body.to_s).to include(I18n.t("resenha.errors.cannot_kick_self"))

    delete "/resenha/rooms/#{room.id}/kick.json", params: { user_id: owner.id }
    expect(response.status).to eq(400)
    expect(response.parsed_body.to_s).to include(I18n.t("resenha.errors.cannot_kick_creator"))
  end
end
