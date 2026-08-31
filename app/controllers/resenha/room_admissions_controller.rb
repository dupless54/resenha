# frozen_string_literal: true

module Resenha
  class RoomAdmissionsController < RoomsController
    def join
      pending_invite = pending_locked_room_invite
      guardian.ensure_can_enter_resenha_room!(@room)

      params[:invited_by] = pending_invite.invited_by.username_lower if pending_invite&.invited_by

      super
      redeem_pending_invite!(pending_invite)
    end

    private

    def pending_locked_room_invite
      return unless @room.locked?

      Resenha::Invite
        .includes(:invited_by)
        .where(room_id: @room.id, user_id: current_user.id, redeemed_at: nil)
        .order(updated_at: :desc)
        .first
    end

    def redeem_pending_invite!(invite)
      return unless invite && response.successful?
      return if invite.reload.redeemed_at.present?

      invite.update!(redeemed_at: Time.current)
      Resenha::BadgeGranterHooks.on_invite_redeemed(invite)
    end
  end
end
