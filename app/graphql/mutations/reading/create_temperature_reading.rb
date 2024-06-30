# frozen_string_literal: true

module Mutations
  module Reading
    class CreateTemperatureReading < Mutations::BaseMutation
      argument(:room_key, String)
      argument(:temperature, Float)
      argument(:humidity, Float)

      field(:temperature_reading, ::Types::TemperatureReadingType)
      field(:errors, [String], null: false)

      def resolve(room_key:, temperature:, humidity:)
        begin
          room = ::Room.find_by!(key: room_key)
        rescue ActiveRecord::RecordNotFound
          return {
            errors: ["Could not find room with key: #{room_key}"],
            temperature_reading: nil,
          }
        end

        temperature_reading = room.temperature_readings.new(temperature:, humidity:)
        if temperature_reading.save
          {
            errors: [],
            temperature_reading:,
          }
        else
          {
            errors: temperature_reading.errors.full_messages,
            temperature_reading: nil,
          }
        end
      end
    end
  end
end
