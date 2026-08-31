# frozen_string_literal: true

module Resenha
  class RoomLocksController < ApplicationController
    before_action :load_room

    def update
      set_locked!(true)
    end

    def destroy
      set_locked!(false)
    end

    private

    def load_room
      @room = Resenha::Room.find(params[:room_id])
    end

    def set_locked!(locked)
      guardian.ensure_can_manage_resenha_room!(@room)
      if @room.ephemeral?
        raise Discourse::InvalidParameters.new(I18n.t("resenha.errors.ephemeral_room_lock"))
      end

      changed = @room.locked? != locked
      @room.update!(locked: locked)
      Resenha::DirectoryBroadcaster.broadcast(action: :updated, room: @room) if changed

      render_serialized @room, Resenha::RoomSerializer, root: :room
    end
  end
end
