# frozen_string_literal: true

module Resenha
  class RoomBanEvictor
    def self.evict!(room:, user:)
      Resenha::RoomParticipantEvictor.evict!(room: room, user: user)
    end
  end
end
