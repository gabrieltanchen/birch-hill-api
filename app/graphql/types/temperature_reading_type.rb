# frozen_string_literal: true

module Types
  class TemperatureReadingType < Types::BaseObject
    field(:id, ID, null: false)
    field(:temperature, Float, null: false)
    field(:humidity, Float, null: false)
    field(:recorded_at, GraphQL::Types::ISO8601DateTime, null: false)
  end
end
