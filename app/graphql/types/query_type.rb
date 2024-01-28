# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field(:node, Types::NodeType, null: true, description: "Fetches an object given its ID.") do
      argument :id, ID, required: true, description: "ID of the object."
    end
    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field(
      :nodes,
      [Types::NodeType, { null: true }],
      null: true,
      description: "Fetches a list of objects given a list of IDs.",
    ) do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end
    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    field(:room, Types::RoomType) do
      argument(:id, ID)
      description("Room")
    end
    def room(id:)
      Room.find(id)
    end

    field(:rooms, Types::RoomType.connection_type, null: false)
    def rooms
      Room.all
    end

    field(:temperature_readings, Types::TemperatureReadingType.connection_type, null: false) do
      argument(:room_id, ID, required: true)
    end
    def temperature_readings(room_id:)
      room = Room.find(room_id)
      room.temperature_readings.order(recorded_at: :desc)
    end
  end
end
