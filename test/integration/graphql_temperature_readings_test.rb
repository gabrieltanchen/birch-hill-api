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

  test("creates a temperature reading") do
    query_string = <<-GRAPHQL
      mutation($roomKey: String!, $temperature: Float!, $humidity: Float!) {
        createTemperatureReading(input: {
          roomKey: $roomKey
          temperature: $temperature
          humidity: $humidity
        }) {
          temperatureReading {
            id
            temperature
            humidity
          }
          errors
        }
      }
    GRAPHQL

    result = BirchHillApiSchema.execute(
      query_string,
      variables: {
        roomKey: "living_room",
        temperature: 12.34,
        humidity: 56.78,
      },
    )

    temperature_reading_id = result["data"]["createTemperatureReading"]["temperatureReading"]["id"]
    temperature_reading = TemperatureReading.find(temperature_reading_id)
    assert_equal(12.34, temperature_reading.temperature)
    assert_equal(56.78, temperature_reading.humidity)
    assert_empty(result["data"]["createTemperatureReading"]["errors"])
  end

  test("returns an error when the room key does not exist") do
    query_string = <<-GRAPHQL
      mutation($roomKey: String!, $temperature: Float!, $humidity: Float!) {
        createTemperatureReading(input: {
          roomKey: $roomKey
          temperature: $temperature
          humidity: $humidity
        }) {
          temperatureReading {
            id
            temperature
            humidity
          }
          errors
        }
      }
    GRAPHQL

    result = BirchHillApiSchema.execute(
      query_string,
      variables: {
        roomKey: "unknown_room",
        temperature: 12.34,
        humidity: 56.78,
      },
    )
    assert_nil(result["data"]["createTemperatureReading"]["temperatureReading"])
    assert_equal(["Could not find room with key: unknown_room"], result["data"]["createTemperatureReading"]["errors"])
  end

  test("returns an error when failing to create a temperature reading") do
    query_string = <<-GRAPHQL
      mutation($roomKey: String!, $temperature: Float!, $humidity: Float!) {
        createTemperatureReading(input: {
          roomKey: $roomKey
          temperature: $temperature
          humidity: $humidity
        }) {
          temperatureReading {
            id
            temperature
            humidity
          }
          errors
        }
      }
    GRAPHQL
    temperature_reading = TemperatureReading.new(temperature: 12.34, humidity: 56.78)
    temperature_reading.errors.add(:base, "Test error")
    temperature_reading.stubs(:save).returns(false)
    TemperatureReading.stubs(:new).returns(temperature_reading)

    result = BirchHillApiSchema.execute(
      query_string,
      variables: {
        roomKey: "living_room",
        temperature: 12.34,
        humidity: 56.78,
      },
    )
    assert_nil(result["data"]["createTemperatureReading"]["temperatureReading"])
    assert_equal(["Test error"], result["data"]["createTemperatureReading"]["errors"])
  end
end
