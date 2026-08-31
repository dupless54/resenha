# frozen_string_literal: true

module Resenha
  class IceController < ApplicationController
    before_action :load_room

    def refresh
      guardian.ensure_can_join_resenha_room!(@room)
      RateLimiter.new(current_user, "resenha-ice-refresh", 30, 1.minute).performed!
      ensure_participant_session!

      # `pin_transport!` is the same first-writer-wins authority used by join.
      # If a briefly lapsed mesh pin has no successor, the still-live participant
      # grant can safely restore it; if a new LiveKit instance already won the
      # race, this request observes that pin and must not start a parallel mesh.
      transport = Resenha::ParticipantTracker.pin_transport!(@room.id, "mesh")
      return head :conflict unless transport == "mesh"

      # Keep the server-attested grant alive while a reconnect is in flight,
      # but do not recreate roster presence here. Heartbeat remains the only
      # self-healing presence path, so delayed refreshes cannot resurrect a
      # participant after leave (leave revokes the grant this action requires).
      Resenha::ParticipantTracker.refresh_participant_session(@room.id, current_user.id)

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
