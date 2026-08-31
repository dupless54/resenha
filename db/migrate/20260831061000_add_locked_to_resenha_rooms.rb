# frozen_string_literal: true

class AddLockedToResenhaRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :resenha_rooms, :locked, :boolean, default: false, null: false
  end
end
