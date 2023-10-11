class CreateTemperatureReadings < ActiveRecord::Migration[7.1]
  def change
    create_table :temperature_readings do |t|
      t.references :room, null: false, foreign_key: true
      t.datetime :read_at
      t.float :temperature
      t.float :humidity

      t.timestamps
    end
  end
end
