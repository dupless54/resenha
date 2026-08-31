# frozen_string_literal: true

RSpec.describe Resenha::RoomSerializer do
  fab!(:viewer) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:owner) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:staff, :admin)
  fab!(:room) { Fabricate(:resenha_room, creator: owner, public: true) }
  fab!(:participant_1) { Fabricate(:user) }
  fab!(:participant_2) { Fabricate(:user) }
  fab!(:participant_3) { Fabricate(:user) }
  fab!(:participant_4) { Fabricate(:user) }

  before do
    SiteSetting.resenha_enabled = true
    SiteSetting.resenha_allowed_groups = Group::AUTO_GROUPS[:everyone]
    SiteSetting.resenha_max_room_participants = 4
    allow(Resenha::ParticipantTracker).to receive(:get_all_metadata).with(room.id).and_return({})
  end

  def serialize(participants)
    allow(Resenha::ParticipantTracker).to receive(:list).with(room.id).and_return(participants)

    described_class.new(room, scope: viewer.guardian, root: false).as_json
  end

  it "serializes the effective site capacity and available admission state" do
    json = serialize([participant_1, participant_2, participant_3])

    expect(json[:effective_max_participants]).to eq(4)
    expect(json[:full]).to eq(false)
  end

  it "marks the room full when tracked presence reaches effective capacity" do
    json = serialize([participant_1, participant_2, participant_3, participant_4])

    expect(json[:effective_max_participants]).to eq(4)
    expect(json[:full]).to eq(true)
  end

  it "uses a lower room-level limit for both capacity and full state" do
    room.update!(max_participants: 3)

    json = serialize([participant_1, participant_2, participant_3])

    expect(json[:effective_max_participants]).to eq(3)
    expect(json[:full]).to eq(true)
  end

  it "serializes staff authority with active participant snapshots" do
    json = serialize([participant_1, staff])
    participants = json[:active_participants].index_by { |participant| participant[:id] }

    expect(participants[participant_1.id][:staff]).to eq(false)
    expect(participants[staff.id][:staff]).to eq(true)
  end
end
