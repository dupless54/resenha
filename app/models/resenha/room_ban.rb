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

# == Schema Information
#
# Table name: resenha_room_bans
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  banned_by_id :bigint
#  room_id      :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  idx_resenha_room_bans_on_room_and_user       (room_id,user_id) UNIQUE
#  index_resenha_room_bans_on_banned_by_id       (banned_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (banned_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (room_id => resenha_rooms.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
