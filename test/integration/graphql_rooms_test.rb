# frozen_string_literal: true

require "test_helper"

class GraphqlRoomsTest < ActionDispatch::IntegrationTest
  test("loads rooms by ID") do
    query_string = <<-GRAPHQL
      query($id: ID!) {
        room(id: $id) {
          id
          name
        }
      }
    GRAPHQL

    room = rooms(:living_room)
    result = BirchHillApiSchema.execute(query_string, variables: { id: room.id })

    room_result = result["data"]["room"]
    assert_equal(room.id.to_s, room_result["id"])
    assert_equal(room.name, room_result["name"])
  end

  test("loads a list of rooms") do
    query_string = <<-GRAPHQL
      query {
        rooms {
          edges {
            cursor
            node {
              id
              name
            }
          }
        }
      }
    GRAPHQL

    result = BirchHillApiSchema.execute(query_string)

    edges = result["data"]["rooms"]["edges"]
    assert_equal(8, edges.length)
  end

  test("loads a paginated list of rooms") do
    query_string = <<-GRAPHQL
      query($first:Int, $after:String) {
        rooms(first:$first, after:$after) {
          edges {
            cursor
            node {
              id
              name
            }
          }
        }
      }
    GRAPHQL

    first_page_result = BirchHillApiSchema.execute(query_string, variables: { first: 2 })
    first_page_edges = first_page_result["data"]["rooms"]["edges"]
    assert_equal(2, first_page_edges.length)

    living_room = rooms(:living_room)
    assert_equal(living_room.id.to_s, first_page_edges[0]["node"]["id"])
    assert_equal(living_room.name, first_page_edges[0]["node"]["name"])

    family_room = rooms(:family_room)
    assert_equal(family_room.id.to_s, first_page_edges[1]["node"]["id"])
    assert_equal(family_room.name, first_page_edges[1]["node"]["name"])

    second_page_result = BirchHillApiSchema.execute(
      query_string,
      variables: { first: 3, after: first_page_edges[1]["cursor"] },
    )
    second_page_edges = second_page_result["data"]["rooms"]["edges"]
    assert_equal(3, second_page_edges.length)

    kitchen = rooms(:kitchen)
    assert_equal(kitchen.id.to_s, second_page_edges[0]["node"]["id"])
    assert_equal(kitchen.name, second_page_edges[0]["node"]["name"])

    pantry = rooms(:pantry)
    assert_equal(pantry.id.to_s, second_page_edges[1]["node"]["id"])
    assert_equal(pantry.name, second_page_edges[1]["node"]["name"])

    dining_room = rooms(:dining_room)
    assert_equal(dining_room.id.to_s, second_page_edges[2]["node"]["id"])
    assert_equal(dining_room.name, second_page_edges[2]["node"]["name"])
  end

  test("creates a room") do
    query_string = <<-GRAPHQL
      mutation($name: String!) {
        createRoom(input: {
          name: $name
        }) {
          room {
            id
            name
            createdAt
            updatedAt
          }
          errors
        }
      }
    GRAPHQL

    result = BirchHillApiSchema.execute(query_string, variables: { name: "Test room" })

    room_id = result["data"]["createRoom"]["room"]["id"]
    room = Room.find(room_id)
    assert_equal("Test room", room.name)
    assert_empty(result["data"]["createRoom"]["errors"])
  end

  test("returns an error when failing to create a room") do
    query_string = <<-GRAPHQL
      mutation($name: String!) {
        createRoom(input: {
          name: $name
        }) {
          room {
            id
            name
            createdAt
            updatedAt
          }
          errors
        }
      }
    GRAPHQL
    room = Room.new(name: "Test room")
    room.errors.add(:base, "Test error")
    room.stubs(:save).returns(false)
    Room.stubs(:new).returns(room)

    result = BirchHillApiSchema.execute(query_string, variables: { name: "Test room" })
    assert_nil(result["data"]["createRoom"]["room"])
    assert_equal(["Test error"], result["data"]["createRoom"]["errors"])
  end

  test("updates a room without any changes") do
    query_string = <<-GRAPHQL
      mutation($id: ID!, $name: String!) {
        updateRoom(input: {
          id: $id
          name: $name
        }) {
          room {
            id
            name
            createdAt
            updatedAt
          }
          errors
        }
      }
    GRAPHQL

    living_room = rooms(:living_room)
    result = BirchHillApiSchema.execute(query_string, variables: { id: living_room.id, name: living_room.name })

    assert_equal(living_room.id.to_s, result["data"]["updateRoom"]["room"]["id"])
    assert_equal(living_room.name, result["data"]["updateRoom"]["room"]["name"])
    assert_empty(result["data"]["updateRoom"]["errors"])
  end

  test("updates a room by changing its name") do
    query_string = <<-GRAPHQL
      mutation($id: ID!, $name: String!) {
        updateRoom(input: {
          id: $id
          name: $name
        }) {
          room {
            id
            name
            createdAt
            updatedAt
          }
          errors
        }
      }
    GRAPHQL

    living_room = rooms(:living_room)
    updated_name = "#{living_room.name} 2"
    result = BirchHillApiSchema.execute(query_string, variables: { id: living_room.id, name: updated_name })

    assert_equal(living_room.id.to_s, result["data"]["updateRoom"]["room"]["id"])
    assert_equal(updated_name, result["data"]["updateRoom"]["room"]["name"])
    assert_empty(result["data"]["updateRoom"]["errors"])

    living_room.reload
    assert_equal(updated_name, living_room.name)
  end

  test("returns an error when updating and failing to find the ID") do
    query_string = <<-GRAPHQL
      mutation($id: ID!, $name: String!) {
        updateRoom(input: {
          id: $id
          name: $name
        }) {
          room {
            id
            name
            createdAt
            updatedAt
          }
          errors
        }
      }
    GRAPHQL

    fake_room_id = 1000000
    result = BirchHillApiSchema.execute(query_string, variables: { id: fake_room_id, name: "Test Room" })
    assert_nil(result["data"]["updateRoom"]["room"])
    assert_equal(["Could not find room with ID: #{fake_room_id}"], result["data"]["updateRoom"]["errors"])
  end

  test("returns an error when failing to update a room") do
    query_string = <<-GRAPHQL
      mutation($id: ID!, $name: String!) {
        updateRoom(input: {
          id: $id
          name: $name
        }) {
          room {
            id
            name
            createdAt
            updatedAt
          }
          errors
        }
      }
    GRAPHQL

    living_room = rooms(:living_room)
    living_room.errors.add(:base, "Test error")
    living_room.stubs(:save).returns(false)
    Room.stubs(:find).returns(living_room)

    result = BirchHillApiSchema.execute(query_string, variables: { id: living_room.id, name: "New name" })
    assert_nil(result["data"]["updateRoom"]["room"])
    assert_equal(["Test error"], result["data"]["updateRoom"]["errors"])
  end
end
