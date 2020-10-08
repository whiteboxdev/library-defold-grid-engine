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

-- https://github.com/gymratgames/defold-grid-engine

----------------------------------------------------------------------
-- DEPENDENCIES
----------------------------------------------------------------------

local dge = {}

----------------------------------------------------------------------
-- PROPERTIES
----------------------------------------------------------------------

dge.member = {}
dge.stride = 0
dge.collision_map = {}
dge.property_map = {}
dge.map_offset = vmath.vector3()

dge.tag = {
	{ name = hash("passable"), passable = true },
	{ name = hash("impassable"), passable = false }
}

----------------------------------------------------------------------
-- CONSTANT VALUES
----------------------------------------------------------------------

local neighbor = {
	[1] = vmath.vector3(0, 1, 0),
	[2] = vmath.vector3(-1, 0, 0),
	[4] = vmath.vector3(0, -1, 0),
	[8] = vmath.vector3(1, 0, 0)
}

dge.direction = {
	up = { value = 1, string = "up" },
	left = { value = 2, string = "left" },
	down = { value = 4, string = "down" },
	right = { value = 8, string = "right" }
}

dge.msg = {
	move_start = hash("move_start"),
	move_end = hash("move_end"),
	move_repeat = hash("move_repeat"),
	collide_none = hash("collide_none"),
	collide_passable = hash("collide_passable"),
	collide_impassable = hash("collide_impassable")
}

----------------------------------------------------------------------
-- CONSTANT FUNCTIONS
----------------------------------------------------------------------

function dge.get_stride()
	return dge.stride
end

function dge.get_collision_map()
	return dge.collision_map
end

function dge.get_property_map()
	return dge.property_map
end

function dge.get_map_offset()
	return dge.map_offset
end

function dge.get_tag(name)
	for key, value in ipairs(dge.tag) do
		if value.name == name then
			return { key = key, value = value }
		end
	end
end

function dge.to_pixel_position(grid_position)
	local half_stride = dge.stride * 0.5
	return vmath.vector3(grid_position.x * dge.stride - half_stride, grid_position.y * dge.stride - half_stride, grid_position.z)
end

function dge.to_grid_position(pixel_position)
	return vmath.vector3(math.floor(pixel_position.x / dge.stride) + 1, math.floor(pixel_position.y / dge.stride) + 1, pixel_position.z)
end

function dge.to_map_position(grid_position)
	local result = vmath.vector3(grid_position.x - dge.map_offset.x, #dge.collision_map - grid_position.y + 1 + dge.map_offset.y, 0)
	if 1 <= result.y and result.y <= #dge.collision_map and 1 <= result.x and result.x <= #dge.collision_map[1] then
		return result
	end
	return nil
end

----------------------------------------------------------------------
-- VOLATILE FUNCTIONS
----------------------------------------------------------------------

function dge.set_stride(stride)
	dge.stride = stride
end

function dge.set_collision_map(collision_map)
	dge.collision_map = collision_map
end

function dge.set_property_map(property_map)
	dge.property_map = property_map
end

function dge.set_map_offset(offset)
	dge.map_offset = offset
end

function dge.set_tag(name, passable)
	for key, value in ipairs(dge.tag) do
		if value.name == name then
			value.passable = passable
		end
	end
end

function dge.add_tag(name, passable)
	if not dge.get_tag(name) then
		table.insert(dge.tag, { name = name, passable = passable })
		return #dge.tag
	end
end

function dge.register(config)

	dge.member[go.get_id()] = true

	----------------------------------------------------------------------
	-- INSTANCE PROPERTIES
	----------------------------------------------------------------------

	local member = {}
	local _size = config.size
	local _direction = config.direction
	local _speed = config.speed
	local _offset = vmath.vector3(0, dge.stride * 0.5 - _size.y * 0.5, 0)
	local _input = { up = false, left = false, down = false, right = false }
	local _moving = false
	local _force = false
	local _lerp = { t = 0, v1 = vmath.vector3(), v2 = vmath.vector3() }
	local _lerp_callback = {}

	----------------------------------------------------------------------
	-- INSTANCE CONSTANT FUNCTIONS
	----------------------------------------------------------------------

	function member.get_size()
		return _size
	end

	function member.get_direction()
		return _direction
	end

	function member.get_speed()
		return _speed
	end

	function member.is_moving()
		return _moving
	end

	function member.is_forcing_movement()
		return _force
	end

	function member.get_grid_position()
		return dge.to_grid_position(go.get_position() + _offset)
	end

	function member.get_map_position()
		return dge.to_map_position(member.get_grid_position())
	end

	function member.reach()
		return member.get_grid_position() + neighbor[_direction.value]
	end

	----------------------------------------------------------------------
	-- INSTANCE VOLATILE FUNCTIONS
	----------------------------------------------------------------------

	local function snap()
		go.set_position(dge.to_pixel_position(dge.to_grid_position(go.get_position() + _offset)) - _offset)
	end

	local function lerp(dt)
		local complete = false
		_lerp.t = _speed == 0 and 1 or _lerp.t + dt * _speed
		local progress = vmath.lerp(_lerp.t, _lerp.v1, _lerp.v2)
		if _lerp.t >= 1 then
			_lerp.t = 0
			_moving = false
			progress = _lerp.v2
			complete = true
			if #_lerp_callback > 0 then
				local i = 1
				while i <= #_lerp_callback do
					_lerp_callback[i].callback()
					if _lerp_callback[i].volatile then
						table.remove(_lerp_callback, i)
					else
						i = i + 1
					end
				end
			end
		end
		go.set_position(progress)
		return complete
	end

	function member.set_direction(direction)
		_direction = direction
	end

	function member.set_speed(speed)
		_speed = speed
	end

	function member.force_movement(flag)
		_force = flag
	end

	function member.add_lerp_callback(callback, volatile)
		table.insert(_lerp_callback, { callback = callback, volatile = volatile })
	end

	function member.remove_lerp_callback(callback, volatile)
		for key, value in ipairs(_lerp_callback) do
			if value.callback == callback and value.volatile == volatile then
				table.remove(_lerp_callback, key)
			end
		end
	end

	function member.set_grid_position(grid_position)
		if not _moving then
			go.set_position(dge.to_pixel_position(grid_position) - _offset)
		end
	end

	function member.move(direction)
		if direction == dge.direction.up then
			_input.up = true
		elseif direction == dge.direction.left then
			_input.left = true
		elseif direction == dge.direction.down then
			_input.down = true
		elseif direction == dge.direction.right then
			_input.right = true
		end
	end

	function member.stop(direction)
		if direction == dge.direction.up then
			_input.up = false
		elseif direction == dge.direction.left then
			_input.left = false
		elseif direction == dge.direction.down then
			_input.down = false
		elseif direction == dge.direction.right then
			_input.right = false
		end
	end

	function member.update(dt)
		local complete = false
		if _moving then
			complete = lerp(dt)
			if not complete then
				return
			end
		end
		if _input.up then
			_direction = dge.direction.up
			local map_position = dge.to_map_position(member.reach())
			local tag = map_position and dge.tag[dge.collision_map[map_position.y][map_position.x]] or nil
			msg.post("#", tag and (tag.passable and dge.msg.collide_passable or dge.msg.collide_impassable) or dge.msg.collide_none, tag and { name = tag.name, property = dge.property_map[map_position.x .. map_position.y] } or nil)
			if not tag or tag.passable or _force then
				_moving = true
				_lerp.v1 = go.get_position()
				_lerp.v2 = _lerp.v1 + vmath.vector3(0, dge.stride, 0)
			end
		elseif _input.left then
			_direction = dge.direction.left
			local map_position = dge.to_map_position(member.reach())
			local tag = map_position and dge.tag[dge.collision_map[map_position.y][map_position.x]] or nil
			msg.post("#", tag and (tag.passable and dge.msg.collide_passable or dge.msg.collide_impassable) or dge.msg.collide_none, tag and { name = tag.name, property = dge.property_map[map_position.x .. map_position.y] } or nil)
			if not tag or tag.passable or _force then
				_moving = true
				_lerp.v1 = go.get_position()
				_lerp.v2 = _lerp.v1 + vmath.vector3(-dge.stride, 0, 0)
			end
		elseif _input.down then
			_direction = dge.direction.down
			local map_position = dge.to_map_position(member.reach())
			local tag = map_position and dge.tag[dge.collision_map[map_position.y][map_position.x]] or nil
			msg.post("#", tag and (tag.passable and dge.msg.collide_passable or dge.msg.collide_impassable) or dge.msg.collide_none, tag and { name = tag.name, property = dge.property_map[map_position.x .. map_position.y] } or nil)
			if not tag or tag.passable or _force then
				_moving = true
				_lerp.v1 = go.get_position()
				_lerp.v2 = _lerp.v1 + vmath.vector3(0, -dge.stride, 0)
			end
		elseif _input.right then
			_direction = dge.direction.right
			local map_position = dge.to_map_position(member.reach())
			local tag = map_position and dge.tag[dge.collision_map[map_position.y][map_position.x]] or nil
			msg.post("#", tag and (tag.passable and dge.msg.collide_passable or dge.msg.collide_impassable) or dge.msg.collide_none, tag and { name = tag.name, property = dge.property_map[map_position.x .. map_position.y] } or nil)
			if not tag or tag.passable or _force then
				_moving = true
				_lerp.v1 = go.get_position()
				_lerp.v2 = _lerp.v1 + vmath.vector3(dge.stride, 0, 0)
			end
		end
		if _moving then
			if not complete then
				msg.post("#", dge.msg.move_start)
				lerp(dt)
			else
				msg.post("#", dge.msg.move_repeat)
			end
		elseif complete then
			msg.post("#", dge.msg.move_end)
		end
	end

	function member.unregister()
		dge.member[go.get_id()] = nil
	end

	snap()

	return member

end

return dge