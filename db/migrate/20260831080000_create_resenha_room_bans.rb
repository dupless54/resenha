# frozen_string_literal: true

class CreateResenhaRoomBans < ActiveRecord::Migration[8.0]
  def change
    create_table :resenha_room_bans do |t|
      t.bigint :room_id, null: false
      t.bigint :user_id, null: false
      t.bigint :banned_by_id
      t.timestamps
    end

    add_index :resenha_room_bans,
              %i[room_id user_id],
              unique: true,
              name: "idx_resenha_room_bans_on_room_and_user"
    add_index :resenha_room_bans, :banned_by_id

    add_foreign_key :resenha_room_bans, :resenha_rooms, column: :room_id, on_delete: :cascade
    add_foreign_key :resenha_room_bans, :users, column: :user_id, on_delete: :cascade
    add_foreign_key :resenha_room_bans, :users, column: :banned_by_id, on_delete: :nullify
  end
end
