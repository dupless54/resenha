# frozen_string_literal: true

module Resenha
  class RoomBan < ActiveRecord::Base
    self.table_name = "#{Resenha.table_name_prefix}room_bans"

    belongs_to :room, class_name: "Resenha::Room"
    belongs_to :user
    belongs_to :banned_by, class_name: "User", optional: true

    validates :user_id, uniqueness: { scope: :room_id }
  end
end
