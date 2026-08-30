# frozen_string_literal: true

RSpec.describe Resenha::ParticipantTracker do
  fab!(:room, :resenha_room)

  before do
    SiteSetting.resenha_enabled = true
    SiteSetting.resenha_mesh_max_participants = 4
  end

  after { described_class.clear(room.id) }

  describe ".add capacity enforcement" do
    def users(count)
      Array.new(count) { Fabricate(:user) }
    end

    it "caps mesh calls at the site-wide safety limit" do
      participants = users(5)
      described_class.pin_transport!(room.id, "mesh")

      participants.first(4).each { |user| described_class.add(room.id, user.id) }

      expect { described_class.add(room.id, participants.last.id) }.to raise_error(
        Discourse::InvalidParameters,
      )
      expect(described_class.user_ids(room.id)).to contain_exactly(
        *participants.first(4).map(&:id),
      )
    end

    it "lets an existing participant refresh presence while the room is full" do
      participants = users(4)
      described_class.pin_transport!(room.id, "mesh")
      participants.each { |user| described_class.add(room.id, user.id) }

      expect { described_class.add(room.id, participants.first.id) }.not_to raise_error
      expect(described_class.user_ids(room.id).length).to eq(4)
    end

    it "honors a lower room-specific limit" do
      participants = users(4)
      room.update!(max_participants: 3)
      described_class.pin_transport!(room.id, "mesh")
      participants.first(3).each { |user| described_class.add(room.id, user.id) }

      expect { described_class.add(room.id, participants.last.id) }.to raise_error(
        Discourse::InvalidParameters,
      )
    end

    it "does not apply the mesh ceiling to LiveKit calls" do
      participants = users(5)
      described_class.pin_transport!(room.id, "livekit")

      participants.each { |user| described_class.add(room.id, user.id) }

      expect(described_class.user_ids(room.id)).to contain_exactly(*participants.map(&:id))
    end

    it "still honors a room-specific limit on LiveKit calls" do
      participants = users(4)
      room.update!(max_participants: 3)
      described_class.pin_transport!(room.id, "livekit")
      participants.first(3).each { |user| described_class.add(room.id, user.id) }

      expect { described_class.add(room.id, participants.last.id) }.to raise_error(
        Discourse::InvalidParameters,
      )
    end
  end
end
