# frozen_string_literal: true

class Room < ApplicationRecord
  has_many :temperature_readings
end
