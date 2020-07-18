----------------------------------------------------------------------
-- LICENSE & CREDITS
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

dge.direction = {
	up = { value = 1, string = "up" },
	left = { value = 2, string = "left" },
	down = { value = 4, string = "down" },
	right = { value = 8, string = "right" }
}

dge.msg = {
	move_start = hash("move_start"),
	move_end = hash("move_end")
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
	local _lerp = { t = 0, v1 = vmath.vector3(), v2 = vmath.vector3() }

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
		end
		go.set_position(progress)
		return complete
	end

	function member.get_direction()
		return _direction
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

	function member.get_position()
		return dge.to_grid_coordinates(go.get_position() + _offset)
	end

	function member.reach()
		return member.get_position() + neighbor[_direction.value]
	end

	function member.move_up()
		_input.up = true
	end

	function member.move_left()
		_input.left = true
	end

	function member.move_down()
		_input.down = true
	end

	function member.move_right()
		_input.right = true
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
			_moving = true
			_lerp.v1 = go.get_position()
			_lerp.v2 = _lerp.v1 + vmath.vector3(0, dge.stride, 0)
		elseif _input.left then
			_moving = true
			_lerp.v1 = go.get_position()
			_lerp.v2 = _lerp.v1 + vmath.vector3(-dge.stride, 0, 0)
		elseif _input.down then
			_moving = true
			_lerp.v1 = go.get_position()
			_lerp.v2 = _lerp.v1 + vmath.vector3(0, -dge.stride, 0)
		elseif _input.right then
			_moving = true
			_lerp.v1 = go.get_position()
			_lerp.v2 = _lerp.v1 + vmath.vector3(dge.stride, 0, 0)
		end
		if _moving then
			_direction = input_to_direction(_input)
			if not complete then
				msg.post("#", dge.msg.move_start)
				lerp(dt)
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