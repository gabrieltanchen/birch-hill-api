# frozen_string_literal: true

class CreateRooms < ActiveRecord::Migration[7.1]
  def change
    create_table :rooms do |t|
      t.string :key, index: { unique: true, name: 'unique_keys' }
      t.string :name

      t.timestamps
    end
  end
end
