# frozen_string_literal: true

module Resenha
  class RoomKicksController < ApplicationController
    before_action :load_room

    def destroy
      guardian.ensure_can_manage_resenha_room!(@room)
      RateLimiter.new(current_user, "resenha-room-kicks", 30, 1.minute).performed!

      user = User.find_by(id: params.require(:user_id).to_i)
      raise Discourse::InvalidParameters.new(:user_id) if user.blank?

      ensure_kickable!(user)
      Resenha::RoomParticipantEvictor.evict!(room: @room, user: user)
      head :no_content
    end

    private

    def load_room
      @room = Resenha::Room.find(params[:id])
    end

    def ensure_kickable!(user)
      if user.id == current_user.id
        raise Discourse::InvalidParameters.new(I18n.t("resenha.errors.cannot_kick_self"))
      end

      if user.id == @room.creator_id
        raise Discourse::InvalidParameters.new(I18n.t("resenha.errors.cannot_kick_creator"))
      end

      membership = @room.room_memberships.find_by(user_id: user.id)
      if user.staff? || membership&.moderator?
        raise Discourse::InvalidParameters.new(I18n.t("resenha.errors.cannot_kick_manager"))
      end
    end
  end
end
