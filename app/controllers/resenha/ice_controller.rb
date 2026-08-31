# frozen_string_literal: true

module Resenha
  class IceController < ApplicationController
    before_action :load_room

    def refresh
      guardian.ensure_can_join_resenha_room!(@room)
      RateLimiter.new(current_user, "resenha-ice-refresh", 30, 1.minute).performed!
      ensure_participant_session!

      transport = Resenha::ParticipantTracker.pinned_transport(@room.id)
      return head :gone if transport.blank?
      return head :conflict unless transport == "mesh"

      # Keep the server-attested grant and the transport pin alive while a
      # reconnect is in flight, but do not recreate roster presence here.
      # Heartbeat remains the only self-healing presence path, which prevents
      # a delayed ICE refresh from resurrecting a participant after leave.
      Resenha::ParticipantTracker.refresh_participant_session(@room.id, current_user.id)
      Resenha::ParticipantTracker.refresh_transport_pin(@room.id)

      render json: { ice: Resenha::IceConfig.payload(current_user) }
    end

    private

    def load_room
      @room = Resenha::Room.find(params[:room_id])
    end

    def ensure_participant_session!
      return if Resenha::ParticipantTracker.participant_session?(@room.id, current_user.id)

      RateLimiter.new(current_user, "resenha-session-denied", 30, 1.minute).performed!
      raise Discourse::InvalidAccess.new(
              :resenha_participant_session_required,
              nil,
              custom_message: "resenha.errors.participant_session_required",
            )
    end
  end
end
