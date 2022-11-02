----------------------------------------------------------------------
-- LICENSE
----------------------------------------------------------------------

-- MIT License

-- Copyright (c) 2020 Klayton Kowalski

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- https://github.com/klaytonkowalski/library-defold-grid-engine

----------------------------------------------------------------------
-- PROPERTIES
----------------------------------------------------------------------

local dgrid = {}

local tile_width
local tile_height

local entities = {}

local map = {}
local map_width
local map_height
local map_offset_x = 0
local map_offset_y = 0

local tags =
{
	[1] = { id = hash("passable"), passable = true },
	[2] = { id = hash("impassable"), passable = false }
}

----------------------------------------------------------------------
-- CONSTANTS
----------------------------------------------------------------------

dgrid.messages =
{
	turn = hash("turn"),
	move_start = hash("move_start"),
	move_complete = hash("move_complete"),
	collide_passable = hash("collide_passable"),
	collide_impassable = hash("collide_impassable"),
	collide_entity = hash("collide_entity")
}

----------------------------------------------------------------------
-- LOCAL FUNCTIONS
----------------------------------------------------------------------

local function to_tile_position(pixel_x, pixel_y)
	return math.floor(pixel_x / tile_width) + 1, math.floor(pixel_y / tile_height) + 1
end

local function to_pixel_position(tile_x, tile_y)
	return tile_x * tile_width - tile_width * 0.5, tile_y * tile_height - tile_height * 0.5
end

local function to_map_position(tile_x, tile_y)
	return tile_x - map_offset_x, tile_y - map_offset_y
end

local function get_forward_tile_position(tile_x, tile_y, direction)
	if direction == 1 then
		return tile_x, tile_y + 1
	end
	if direction == 2 then
		return tile_x - 1, tile_y
	end
	if direction == 3 then
		return tile_x, tile_y - 1
	end
	if direction == 4 then
		return tile_x + 1, tile_y
	end
end

local function get_tile(tile_x, tile_y)
	local forward_map_x, forward_map_y = to_map_position(tile_x, tile_y)
	return map[forward_map_y][forward_map_x]
end

local function get_entity(tile_x, tile_y)
	for _, entity in pairs(entities) do
		if entity.tile_x == tile_x and entity.tile_y == tile_y then
			return entity
		end
	end
end

local function check_collision(entity, direction)
	local forward_tile_x, forward_tile_y = get_forward_tile_position(entity.tile_x, entity.tile_y, direction)
	local tile = get_tile(forward_tile_x, forward_tile_y)
	if tile.tag.passable then
		msg.post(entity.url, dgrid.messages.collide_passable, { tag = tile.tag, data = tile.data })
	else
		msg.post(entity.url, dgrid.messages.collide_impassable, { tag = tile.tag, data = tile.data })
		return true
	end
	local other_entity = get_entity(forward_tile_x, forward_tile_y)
	if other_entity then
		msg.post(entity.url, dgrid.messages.collide_entity, { data = other_entity.data })
		return true
	end
end

local function move(entity, dt)
	local position = go.get_position(entity.id)
	entity.dt = entity.dt + dt * entity.speed
	if entity.direction == 1 then
		local current_y = vmath.lerp(entity.dt, entity.start_pixel_y, entity.target_pixel_y)
		if current_y > entity.target_pixel_y then
			current_y = entity.target_pixel_y
		end
		go.set_position(vmath.vector3(position.x, current_y, position.z), entity.id)
	elseif entity.direction == 2 then
		local current_x = vmath.lerp(entity.dt, entity.start_pixel_x, entity.target_pixel_x)
		if current_x < entity.target_pixel_x then
			current_x = entity.target_pixel_x
		end
		go.set_position(vmath.vector3(current_x, position.y, position.z), entity.id)
	elseif entity.direction == 3 then
		local current_y = vmath.lerp(entity.dt, entity.start_pixel_y, entity.target_pixel_y)
		if current_y < entity.target_pixel_y then
			current_y = entity.target_pixel_y
		end
		go.set_position(vmath.vector3(position.x, current_y, position.z), entity.id)
	elseif entity.direction == 4 then
		local current_x = vmath.lerp(entity.dt, entity.start_pixel_x, entity.target_pixel_x)
		if current_x > entity.target_pixel_x then
			current_x = entity.target_pixel_x
		end
		go.set_position(vmath.vector3(current_x, position.y, position.z), entity.id)
	end
end

local function is_move_complete(entity)
	local position = go.get_position(entity.id)
	if entity.direction == 1 then
		return position.y == entity.target_pixel_y
	elseif entity.direction == 2 then
		return position.x == entity.target_pixel_x
	elseif entity.direction == 3 then
		return position.y == entity.target_pixel_y
	elseif entity.direction == 4 then
		return position.x == entity.target_pixel_x
	end
end

local function complete_move(entity)
	entity.moving = false
	entity.speed = 0
	entity.dt = nil
	entity.start_pixel_x = nil
	entity.start_pixel_y = nil
	entity.target_pixel_x = nil
	entity.target_pixel_y = nil
	msg.post(entity.url, dgrid.messages.move_complete, { tile_x = entity.tile_x, tile_y = entity.tile_y })
end

local function snap_to_tile(entity)
	local position = go.get_position(entity.id)
	local tile_x, tile_y = to_tile_position(position.x, position.y)
	local pixel_x, pixel_y = to_pixel_position(tile_x, tile_y)
	go.set_position(vmath.vector3(pixel_x, pixel_y, position.z))
end

----------------------------------------------------------------------
-- MODULE FUNCTIONS
----------------------------------------------------------------------

function dgrid.set_map_dimensions(width, height)
	map = {}
	map_width = width
	map_height = height
	for y = 1, height do
		table.insert(map, {})
		for x = 1, width do
			table.insert(map[y], { tag = tags[1], data = {} })
		end
	end
end

function dgrid.set_map_offset(x, y)
	map_offset_x = x
	map_offset_y = y
end

function dgrid.set_map_tags(keys)
	for y = 1, #keys do
		for x = 1, #keys[y] do
			map[y][x].tag = tags[keys[#keys - y + 1][x]]
		end
	end
end

function dgrid.add_map_tag(id, passable)
	table.insert(tags, { id = id, passable = passable })
	return #tags
end

function dgrid.modify_map_tag(key, passable)
	tags[key].passable = passable
end

function dgrid.set_tile_dimensions(width, height)
	tile_width = width
	tile_height = height
end

function dgrid.set_tile_data(x, y, data)
	map[y][x].data = data
end

function dgrid.get_tile_data(x, y)
	return map[y][x].data
end

function dgrid.add_entity(id, url, center, direction, data)
	if not entities[id] then
		local position = go.get_position(id)
		local tile_x, tile_y = to_tile_position(position.x, position.y)
		entities[id] =
		{
			id = id,
			url = url,
			center = center,
			direction = direction,
			data = data or {},
			moving = false,
			speed = 0,
			dt = nil,
			start_x = nil,
			start_y = nil,
			target_x = nil,
			target_y = nil,
			tile_x = tile_x,
			tile_y = tile_y
		}
		snap_to_tile(entities[id])
	end
end

function dgrid.remove_entity(id)
	entities[id] = nil
end

function dgrid.clear_entities()
	entities = {}
end

function dgrid.set_entity_url(id, url)
	if entities[id] then
		entities[id].url = url
	end
end

function dgrid.get_entity_direction(id)
	return entities[id] and entities[id].direction
end

function dgrid.set_entity_data(id, data)
	if entities[id] then
		entities[id].data = data
	end
end

function dgrid.get_entity_data(id)
	return entities[id] and entities[id].data
end

function dgrid.is_entity_moving(id)
	return entities[id] and entities[id].moving
end

function dgrid.get_entity_speed(id)
	return entities[id] and entities[id].speed
end

function dgrid.get_entity_position(id)
	if entities[id] then
		return entities[id].tile_x, entities[id].tile_y
	end
end

function dgrid.interact(id)
	local entity = entities[id]
	if entity and not entity.moving then
		local forward_tile_x, forward_tile_y = get_forward_tile_position(entity.tile_x, entity.tile_y, entity.direction)
		local tile = get_tile(forward_tile_x, forward_tile_y)
		local entity = get_entity(forward_tile_x, forward_tile_y)
		return { tag = tile.tag, tile_data = tile.data, entity_data = entity.data }
	end
end

function dgrid.turn_up(id)
	local entity = entities[id]
	if entity and not entity.moving then
		entity.direction = 1
		msg.post(entity.url, dgrid.messages.turn, { direction = entity.direction })
	end
end

function dgrid.turn_left(id)
	local entity = entities[id]
	if entity and not entity.moving then
		entity.direction = 2
		msg.post(entity.url, dgrid.messages.turn, { direction = entity.direction })
	end
end

function dgrid.turn_down(id)
	local entity = entities[id]
	if entity and not entity.moving then
		entity.direction = 3
		msg.post(entity.url, dgrid.messages.turn, { direction = entity.direction })
	end
end

function dgrid.turn_right(id)
	local entity = entities[id]
	if entity and not entity.moving then
		entity.direction = 4
		msg.post(entity.url, dgrid.messages.turn, { direction = entity.direction })
	end
end

function dgrid.turn(id, direction)
	if direction == 1 then
		dgrid.turn_up(id)
	elseif direction == 2 then
		dgrid.turn_left(id)
	elseif direction == 3 then
		dgrid.turn_down(id)
	elseif direction == 4 then
		dgrid.turn_right(id)
	end
end

function dgrid.move_up(id, speed)
	local entity = entities[id]
	if entity then
		if not entity.moving then
			dgrid.turn_up(entity.id)
			if not check_collision(entity, 1) then
				entity.moving = true
				entity.speed = speed
				entity.dt = 0
				local position = go.get_position(id)
				entity.start_pixel_x = position.x
				entity.start_pixel_y = position.y
				entity.target_pixel_x = position.x
				entity.target_pixel_y = position.y + tile_height
				local start_tile_x, start_tile_y = to_tile_position(entity.start_pixel_x, entity.start_pixel_y)
				entity.tile_x, entity.tile_y = to_tile_position(entity.target_pixel_x, entity.target_pixel_y)
				msg.post(entity.url, dgrid.messages.move_start, { direction = entity.direction, speed = entity.speed, start_x = start_tile_x, start_y = start_tile_y, target_x = entity.tile_x, target_y = entity.tile_y })
			end
		end
	end
end

function dgrid.move_left(id, speed)
	local entity = entities[id]
	if entity then
		if not entity.moving then
			dgrid.turn_left(entity.id)
			if not check_collision(entity, 2) then
				entity.moving = true
				entity.speed = speed
				entity.direction = 2
				entity.dt = 0
				local position = go.get_position(id)
				entity.start_pixel_x = position.x
				entity.start_pixel_y = position.y
				entity.target_pixel_x = position.x - tile_width
				entity.target_pixel_y = position.y
				local start_tile_x, start_tile_y = to_tile_position(entity.start_pixel_x, entity.start_pixel_y)
				entity.tile_x, entity.tile_y = to_tile_position(entity.target_pixel_x, entity.target_pixel_y)
				msg.post(entity.url, dgrid.messages.move_start, { direction = entity.direction, speed = entity.speed, start_x = start_tile_x, start_y = start_tile_y, target_x = entity.tile_x, target_y = entity.tile_y })
			end
		end
	end
end

function dgrid.move_down(id, speed)
	local entity = entities[id]
	if entity then
		if not entity.moving then
			dgrid.turn_down(entity.id)
			if not check_collision(entity, 3) then
				entity.moving = true
				entity.speed = speed
				entity.direction = 3
				entity.dt = 0
				local position = go.get_position(id)
				entity.start_pixel_x = position.x
				entity.start_pixel_y = position.y
				entity.target_pixel_x = position.x
				entity.target_pixel_y = position.y - tile_height
				local start_tile_x, start_tile_y = to_tile_position(entity.start_pixel_x, entity.start_pixel_y)
				entity.tile_x, entity.tile_y = to_tile_position(entity.target_pixel_x, entity.target_pixel_y)
				msg.post(entity.url, dgrid.messages.move_start, { direction = entity.direction, speed = entity.speed, start_x = start_tile_x, start_y = start_tile_y, target_x = entity.tile_x, target_y = entity.tile_y })
			end
		end
	end
end

function dgrid.move_right(id, speed)
	local entity = entities[id]
	if entity then
		if not entity.moving then
			dgrid.turn_right(entity.id)
			if not check_collision(entity, 4) then
				entity.moving = true
				entity.speed = speed
				entity.direction = 4
				entity.dt = 0
				local position = go.get_position(id)
				entity.start_pixel_x = position.x
				entity.start_pixel_y = position.y
				entity.target_pixel_x = position.x + tile_width
				entity.target_pixel_y = position.y
				local start_tile_x, start_tile_y = to_tile_position(entity.start_pixel_x, entity.start_pixel_y)
				entity.tile_x, entity.tile_y = to_tile_position(entity.target_pixel_x, entity.target_pixel_y)
				msg.post(entity.url, dgrid.messages.move_start, { direction = entity.direction, speed = entity.speed, start_x = start_tile_x, start_y = start_tile_y, target_x = entity.tile_x, target_y = entity.tile_y })
			end
		end
	end
end

function dgrid.move(id, speed, direction)
	if direction == 1 then
		dgrid.move_up(id, speed)
	elseif direction == 2 then
		dgrid.move_left(id, speed)
	elseif direction == 3 then
		dgrid.move_down(id, speed)
	elseif direction == 4 then
		dgrid.move_right(id, speed)
	end
end

function dgrid.update(dt)
	for _, entity in pairs(entities) do
		if entity.moving then
			move(entity, dt)
			if is_move_complete(entity) then
				complete_move(entity)
			end
		end
	end
end

return dgrid