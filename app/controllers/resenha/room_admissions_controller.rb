# frozen_string_literal: true

module Resenha
  class RoomAdmissionsController < RoomsController
    def join
      guardian.ensure_can_enter_resenha_room!(@room)
      super
    end
  end
end
