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
-- CONSTANTS
----------------------------------------------------------------------

local neighbor = {
	[1] = vmath.vector3(0, 1, 0),
	[2] = vmath.vector3(-1, 0, 0),
	[4] = vmath.vector3(0, -1, 0),
	[8] = vmath.vector3(1, 0, 0)
}

----------------------------------------------------------------------
-- PROPERTIES
----------------------------------------------------------------------

dge.member = {}
dge.debug = false
dge.stride = 0
dge.collision = {}
dge.extra = {}

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
	collide_passable = hash("collide_passable"),
	collide_impassable = hash("collide_impassable")
}

dge.tag = {
	{ name = hash("passable"), passable = true },
	{ name = hash("impassable"), passable = false }
}

----------------------------------------------------------------------
-- FUNCTIONS
----------------------------------------------------------------------

function dge.init(config)
	dge.debug = config.debug
	dge.stride = config.stride
	if config.debug then
		print("DGE: Initialized.")
	end
end

function dge.get_debug()
	return dge.debug
end

function dge.set_debug(debug)
	dge.debug = flag
end

function dge.get_collision()
	return dge.collision
end

function dge.set_collision(collision)
	dge.collision = collision
end

function dge.get_tag(name)
	for key, value in ipairs(dge.tag) do
		if value.name == name then
			return { key = key, value = value }
		end
	end
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

function dge.get_extra(gx, gy)
	return dge.extra[gx .. gy]
end

function dge.set_extra(extra, gx, gy)
	dge.extra[gx .. gy] = extra
end

function dge.clear_extra()
	dge.extra = {}
end

function dge.to_pixel_coordinates(grid_coordinates)
	local half_stride = dge.stride * 0.5
	return vmath.vector3(grid_coordinates.x * dge.stride - half_stride, grid_coordinates.y * dge.stride - half_stride, grid_coordinates.z)
end

function dge.to_grid_coordinates(pixel_coordinates)
	return vmath.vector3(math.floor(pixel_coordinates.x / dge.stride) + 1, math.floor(pixel_coordinates.y / dge.stride) + 1, pixel_coordinates.z)
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
	local _movement_gate = true
	local _lerp = { t = 0, v1 = vmath.vector3(), v2 = vmath.vector3() }
	local _lerp_callback = {}

	----------------------------------------------------------------------
	-- INSTANCE FUNCTIONS
	----------------------------------------------------------------------

	local function input_to_direction(input)
		local result = 0
		if input.up then
			result = bit.bor(result, dge.direction.up.value)
		elseif input.left then
			result = bit.bor(result, dge.direction.left.value)
		elseif input.down then
			result = bit.bor(result, dge.direction.down.value)
		elseif input.right then
			result = bit.bor(result, dge.direction.right.value)
		end
		for key, value in pairs(dge.direction) do
			if value.value == result then
				return value
			end
		end
	end

	local function snap()
		go.set_position(dge.to_pixel_coordinates(dge.to_grid_coordinates(go.get_position() + _offset)) - _offset)
		if dge.debug then
			print("DGE: Snapped to position. " .. go.get_id() .. " " .. go.get_position())
		end
	end

	local function lerp(dt)
		local complete = false
		_lerp.t = _lerp.t + dt * _speed
		local progress = vmath.lerp(_lerp.t, _lerp.v1, _lerp.v2)
		if _lerp.t > 1 then
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

	function member.get_direction()
		return _direction
	end

	function member.set_direction(direction)
		_direction = direction
	end

	function member.get_speed()
		return _speed
	end

	function member.set_speed(speed)
		_speed = speed
	end

	function member.get_moving()
		return _moving
	end

	function member.set_movement_gate(gate)
		_movement_gate = gate
		_input = { up = false, left = false, down = false, right = false }
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

	function member.get_position()
		return dge.to_grid_coordinates(go.get_position() + _offset)
	end

	function member.set_position(grid_coordinates)
		if not _moving then
			go.set_position(dge.to_pixel_coordinates(grid_coordinates) - _offset)
		end
	end

	function member.reach()
		return member.get_position() + neighbor[_direction.value]
	end

	function member.move_up()
		if _movement_gate then
			_input.up = true
		end
	end

	function member.move_left()
		if _movement_gate then
			_input.left = true
		end
	end

	function member.move_down()
		if _movement_gate then
			_input.down = true
		end
	end

	function member.move_right()
		if _movement_gate then
			_input.right = true
		end
	end

	function member.stop_up()
		_input.up = false
	end

	function member.stop_left()
		_input.left = false
	end

	function member.stop_down()
		_input.down = false
	end

	function member.stop_right()
		_input.right = false
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
			local position = member.get_position()
			local tag = dge.tag[dge.collision[#dge.collision - position.y][position.x]]
			local extra = dge.extra[position.x .. position.y + 1]
			if tag.passable then
				msg.post("#", dge.msg.collide_passable, { name = tag.name, extra = extra })
				_moving = true
				_lerp.v1 = go.get_position()
				_lerp.v2 = _lerp.v1 + vmath.vector3(0, dge.stride, 0)
			else
				msg.post("#", dge.msg.collide_impassable, { name = tag.name, extra = extra })
				_direction = dge.direction.up
			end
		elseif _input.left then
			local position = member.get_position()
			local tag = dge.tag[dge.collision[#dge.collision - position.y + 1][position.x - 1]]
			local extra = dge.extra[position.x - 1 .. position.y]
			if tag.passable then
				msg.post("#", dge.msg.collide_passable, { name = tag.name, extra = extra })
				_moving = true
				_lerp.v1 = go.get_position()
				_lerp.v2 = _lerp.v1 + vmath.vector3(-dge.stride, 0, 0)
			else
				msg.post("#", dge.msg.collide_impassable, { name = tag.name, extra = extra })
				_direction = dge.direction.left
			end
		elseif _input.down then
			local position = member.get_position()
			local tag = dge.tag[dge.collision[#dge.collision - position.y + 2][position.x]]
			local extra = dge.extra[position.x .. position.y - 1]
			if tag.passable then
				msg.post("#", dge.msg.collide_passable, { name = tag.name, extra = extra })
				_moving = true
				_lerp.v1 = go.get_position()
				_lerp.v2 = _lerp.v1 + vmath.vector3(0, -dge.stride, 0)
			else
				msg.post("#", dge.msg.collide_impassable, { name = tag.name, extra = extra })
				_direction = dge.direction.down
			end
		elseif _input.right then
			local position = member.get_position()
			local tag = dge.tag[dge.collision[#dge.collision - position.y + 1][position.x + 1]]
			local extra = dge.extra[position.x + 1 .. position.y]
			if tag.passable then
				msg.post("#", dge.msg.collide_passable, { name = tag.name, extra = extra })
				_moving = true
				_lerp.v1 = go.get_position()
				_lerp.v2 = _lerp.v1 + vmath.vector3(dge.stride, 0, 0)
			else
				msg.post("#", dge.msg.collide_impassable, { name = tag.name, extra = extra })
				_direction = dge.direction.right
			end
		end
		if _moving then
			_direction = input_to_direction(_input)
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
		if dge.debug then
			print("DGE: Game object unregistered. " .. go.get_id())
		end
	end

	if dge.debug then
		print("DGE: Game object registered. " .. go.get_id())
	end

	snap()

	return member

end

return dge