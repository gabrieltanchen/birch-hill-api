# frozen_string_literal: true

require "test_helper"

class GraphqlTemperatureReadingsTest < ActionDispatch::IntegrationTest
  test("loads a list of temperature readings") do
    query_string = <<-GRAPHQL
      query {
        temperatureReadings(roomId: #{rooms(:living_room).id}) {
          edges {
            cursor
            node {
              id
            }
          }
        }
      }
    GRAPHQL

    result = BirchHillApiSchema.execute(query_string)
    edges = result["data"]["temperatureReadings"]["edges"]
    assert_equal(3, edges.length)
  end

  test("loads an empty list of temperature readings") do
    query_string = <<-GRAPHQL
      query($roomId: ID!) {
        temperatureReadings(roomId: $roomId) {
          edges {
            cursor
            node {
              id
            }
          }
        }
      }
    GRAPHQL

    home_office = rooms(:home_office)
    empty_result = BirchHillApiSchema.execute(
      query_string,
      variables: { roomId: home_office.id },
    )
    assert_equal(0, empty_result["data"]["temperatureReadings"]["edges"].length)
  end

  test("loads a paginated list of temperature readings") do
    query_string = <<-GRAPHQL
      query($roomId: ID!, $first: Int!, $after: String) {
        temperatureReadings(roomId: $roomId, first: $first, after: $after) {
          edges {
            cursor
            node {
              id
              recordedAt
              temperature
              humidity
            }
          }
        }
      }
    GRAPHQL

    living_room = rooms(:living_room)
    first_page_result = BirchHillApiSchema.execute(
      query_string,
      variables: { roomId: living_room.id, first: 2 },
    )
    first_page_edges = first_page_result["data"]["temperatureReadings"]["edges"]
    assert_equal(2, first_page_edges.length)

    living_room_reading2 = temperature_readings(:living_room_reading2)
    assert_equal(living_room_reading2.id.to_s, first_page_edges[0]["node"]["id"])
    assert_equal(living_room_reading2.recorded_at.iso8601, first_page_edges[0]["node"]["recordedAt"])
    assert_equal(living_room_reading2.temperature, first_page_edges[0]["node"]["temperature"])
    assert_equal(living_room_reading2.humidity, first_page_edges[0]["node"]["humidity"])

    living_room_reading3 = temperature_readings(:living_room_reading3)
    assert_equal(living_room_reading3.id.to_s, first_page_edges[1]["node"]["id"])
    assert_equal(living_room_reading3.recorded_at.iso8601, first_page_edges[1]["node"]["recordedAt"])
    assert_equal(living_room_reading3.temperature, first_page_edges[1]["node"]["temperature"])
    assert_equal(living_room_reading3.humidity, first_page_edges[1]["node"]["humidity"])

    second_page_result = BirchHillApiSchema.execute(
      query_string,
      variables: { roomId: living_room.id, first: 2, after: first_page_edges[1]["cursor"] },
    )
    second_page_edges = second_page_result["data"]["temperatureReadings"]["edges"]
    assert_equal(1, second_page_edges.length)

    living_room_reading1 = temperature_readings(:living_room_reading1)
    assert_equal(living_room_reading1.id.to_s, second_page_edges[0]["node"]["id"])
    assert_equal(living_room_reading1.recorded_at.iso8601, second_page_edges[0]["node"]["recordedAt"])
    assert_equal(living_room_reading1.temperature, second_page_edges[0]["node"]["temperature"])
    assert_equal(living_room_reading1.humidity, second_page_edges[0]["node"]["humidity"])
  end
end
