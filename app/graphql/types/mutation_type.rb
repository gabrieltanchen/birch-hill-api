# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field(:create_room, mutation: Mutations::Room::CreateRoom)
    field(:update_room, mutation: Mutations::Room::UpdateRoom)
  end
end
