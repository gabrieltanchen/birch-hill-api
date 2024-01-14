# frozen_string_literal: true

module Mutations
  module Room
    class CreateRoom < Mutations::BaseMutation
      argument(:name, String)

      field(:room, ::Types::RoomType)
      field(:errors, [String], null: false)

      def resolve(name:)
        room = ::Room.new(name:)
        if room.save
          {
            errors: [],
            room:,
          }
        else
          {
            errors: room.errors.full_messages,
            room: nil,
          }
        end
      end
    end
  end
end
