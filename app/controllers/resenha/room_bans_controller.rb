# frozen_string_literal: true

module Resenha
  class RoomBansController < ApplicationController
    before_action :load_room
    before_action :ensure_manageable_persistent_room!

    def index
      render json: { bans: @room.room_bans.includes(:user, :banned_by).order(created_at: :desc).map { |ban| serialize_ban(ban) } }
    end

    def create
      RateLimiter.new(current_user, "resenha-room-bans", 60, 1.minute).performed!

      user = fetch_user
      ensure_bannable!(user)

      ban = @room.room_bans.find_or_initialize_by(user: user)
      ban.banned_by = current_user
      ban.save!

      Resenha::RoomBanEvictor.evict!(room: @room, user: user)

      render json: { ban: serialize_ban(ban) }
    end

    def destroy
      RateLimiter.new(current_user, "resenha-room-bans", 60, 1.minute).performed!
      @room.room_bans.find(params[:id]).destroy!
      head :no_content
    end

    private

    def load_room
      @room = Resenha::Room.find(params[:room_id])
    end

    def ensure_manageable_persistent_room!
      guardian.ensure_can_manage_resenha_room!(@room)
      if @room.ephemeral?
        raise Discourse::InvalidParameters.new(I18n.t("resenha.errors.ephemeral_room_ban"))
      end
    end

    def fetch_user
      user =
        if params[:user_id].present?
          User.find_by(id: params[:user_id].to_i)
        elsif params[:username].present?
          User.find_by_username(params[:username])
        end

      user || raise(Discourse::InvalidParameters.new(:user))
    end

    def ensure_bannable!(user)
      if user.id == current_user.id
        raise Discourse::InvalidParameters.new(I18n.t("resenha.errors.cannot_ban_self"))
      end

      if user.id == @room.creator_id
        raise Discourse::InvalidParameters.new(I18n.t("resenha.errors.cannot_ban_creator"))
      end

      membership = @room.room_memberships.find_by(user_id: user.id)
      if user.staff? || membership&.moderator?
        raise Discourse::InvalidParameters.new(I18n.t("resenha.errors.cannot_ban_manager"))
      end
    end

    def serialize_ban(ban)
      {
        id: ban.id,
        user: BasicUserSerializer.new(ban.user, scope: guardian, root: false).as_json,
        banned_by:
          if ban.banned_by
            BasicUserSerializer.new(ban.banned_by, scope: guardian, root: false).as_json
          end,
        created_at: ban.created_at,
      }
    end
  end
end
