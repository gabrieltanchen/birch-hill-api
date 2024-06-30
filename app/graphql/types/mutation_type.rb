# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field(:create_room, mutation: Mutations::Room::CreateRoom)
    field(:create_temperature_reading, mutation: Mutations::Reading::CreateTemperatureReading)
    field(:update_room, mutation: Mutations::Room::UpdateRoom)
  end
end
