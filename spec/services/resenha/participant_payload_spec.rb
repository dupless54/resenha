# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resenha::ParticipantPayload do
  fab!(:participant, :user)
  fab!(:staff, :admin)

  it "merges participant metadata while keeping staff authority server-owned" do
    guardian = Guardian.new(nil)

    participant_payload =
      described_class.build(
        participant,
        scope: guardian,
        metadata: { role: "speaker", is_muted: true, staff: true },
      )
    staff_payload = described_class.build(staff, scope: guardian, metadata: { staff: false })

    expect(participant_payload[:id]).to eq(participant.id)
    expect(participant_payload[:role]).to eq("speaker")
    expect(participant_payload[:is_muted]).to eq(true)
    expect(participant_payload[:staff]).to eq(false)
    expect(staff_payload[:staff]).to eq(true)
  end
end
