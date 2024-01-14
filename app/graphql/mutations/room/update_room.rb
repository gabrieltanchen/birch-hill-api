# frozen_string_literal: true

module Mutations
  module Room
    class UpdateRoom < Mutations::BaseMutation
      argument(:id, ID)
      argument(:name, String)

      field(:room, ::Types::RoomType)
      field(:errors, [String], null: false)

      def resolve(id:, name:)
        begin
          room = ::Room.find(id)
        rescue ActiveRecord::RecordNotFound
          return {
            errors: ["Could not find room with ID: #{id}"],
            room: nil,
          }
        end

        room.name = name

        if room.changed? && !room.save
          return {
            errors: room.errors.full_messages,
            room: nil,
          }
        end

        {
          errors: [],
          room:,
        }
      end
    end
  end
end
