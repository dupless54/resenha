# frozen_string_literal: true

require "rails_helper"
require_relative "../../../db/migrate/20241107000000_create_resenha_rooms"
require_relative "../../../db/migrate/20260813160047_create_resenha_invites"
require_relative "../../../db/migrate/20260831061000_add_locked_to_resenha_rooms"

RSpec.describe "locked room invite admission" do
  fab!(:owner) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:invitee) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:room) { Fabricate(:resenha_room, creator: owner, public: true, locked: true) }

  before do
    ActiveRecord::Migration.suppress_messages do
      unless ActiveRecord::Base.connection.table_exists?(:resenha_rooms)
        CreateResenhaRooms.new.change
      end
      unless ActiveRecord::Base.connection.table_exists?(:resenha_invites)
        CreateResenhaInvites.new.change
      end
      unless ActiveRecord::Base.connection.column_exists?(:resenha_rooms, :locked)
        AddLockedToResenhaRooms.new.change
      end
    end
    Resenha::Room.reset_column_information
    Resenha::Invite.reset_column_information

    SiteSetting.resenha_enabled = true
    SiteSetting.resenha_allowed_groups = Group::AUTO_GROUPS[:everyone]
    SiteSetting.resenha_analytics_enabled = false
  end

  it "admits a pending invite once and redeems the lock grant on join" do
    sign_in(owner)
    post "/resenha/rooms/#{room.id}/invites.json",
         params: {
           usernames: [invitee.username],
         }

    expect(response.status).to eq(200)
    invite = Resenha::Invite.find_by!(room_id: room.id, user_id: invitee.id)
    expect(invite.redeemed_at).to be_nil

    sign_in(invitee)
    post "/resenha/rooms/#{room.id}/join.json"

    expect(response.status).to eq(200)
    participant_session_id = response.parsed_body["participant_session_id"]
    expect(invite.reload.redeemed_at).to be_present

    delete "/resenha/rooms/#{room.id}/leave.json",
           params: {
             participant_session_id: participant_session_id,
           }
    expect(response.status).to eq(204)

    post "/resenha/rooms/#{room.id}/join.json"

    expect(response.status).to eq(403)
    expect(response.parsed_body.to_s).to include(I18n.t("resenha.errors.room_locked"))
  end
end
