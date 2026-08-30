# frozen_string_literal: true

RSpec.describe Resenha::Room do
  fab!(:room, :resenha_room)

  before { SiteSetting.resenha_mesh_max_participants = 4 }

  describe "#participant_limit_for" do
    it "uses the site-wide mesh ceiling when the room has no lower limit" do
      expect(room.participant_limit_for("mesh")).to eq(4)
    end

    it "uses a lower room-specific limit for mesh" do
      room.update!(max_participants: 3)

      expect(room.participant_limit_for("mesh")).to eq(3)
    end

    it "does not apply the mesh ceiling to LiveKit" do
      expect(room.participant_limit_for("livekit")).to be_nil
    end

    it "keeps room-specific limits on LiveKit" do
      room.update!(max_participants: 6)

      expect(room.participant_limit_for("livekit")).to eq(6)
    end
  end
end
