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

local ordinal_scaler = 1 / math.sqrt(2)

local front = {
	[1]  = vmath.vector3(0, 1, 0),
	[2]  = vmath.vector3(-1, 0, 0),
	[4]  = vmath.vector3(0, -1, 0),
	[8]  = vmath.vector3(1, 0, 0),
	[3]  = vmath.vector3(-1, 1, 0),
	[6]  = vmath.vector3(-1, -1, 0),
	[12] = vmath.vector3(1, -1, 0),
	[9]  = vmath.vector3(1, 1, 0)
}

----------------------------------------------------------------------
-- MODULE PROPERTIES
----------------------------------------------------------------------

dge.members = {}
dge.debug   = false
dge.stride  = 0
dge.ordinal = true

dge.direction = {
	up         = { value = 1,  string = "up"         },
	left       = { value = 2,  string = "left"       },
	down       = { value = 4,  string = "down"       },
	right      = { value = 8,  string = "right"      },
	up_left    = { value = 3,  string = "up_left"    },
	down_left  = { value = 6,  string = "down_left"  },
	down_right = { value = 12, string = "down_right" },
	up_right   = { value = 9,  string = "up_right"   }
}

dge.msg = {
	move_start = hash("move_start"),
	move_end   = hash("move_end")
}

----------------------------------------------------------------------
-- MODULE FUNCTIONS
----------------------------------------------------------------------

function dge.init(config)
	dge.debug = config.debug
	dge.stride = config.stride
	dge.ordinal = config.ordinal
	if config.debug then
		print("DGE: Initialized.")
	end
end

function dge.get_debug()
	return dge.debug
end

function dge.toggle_debug()
	dge.debug = not dge.debug
end

function dge.get_stride()
	return dge.stride
end

function dge.set_stride(stride)
	dge.stride = stride
end

function dge.get_ordinal()
	return dge.ordinal
end

function dge.set_ordinal(ordinal)
	dge.ordinal = ordinal
end

function dge.to_pixel_coordinates(grid_coordinates)
	return vmath.vector3(math.floor(grid_coordinates.x * dge.stride), math.floor(grid_coordinates.y * dge.stride), grid_coordinates.z)
end

function dge.to_grid_coordinates(pixel_coordinates)
	return vmath.vector3(math.floor(pixel_coordinates.x / dge.stride) + 1, math.floor(pixel_coordinates.y / dge.stride) + 1, pixel_coordinates.z)
end

function dge.register(config)
	
	dge.members[go.get_id()] = true
	
	----------------------------------------------------------------------
	-- INSTANCE PROPERTIES
	----------------------------------------------------------------------

	local member     = {}
	local _speed     = config.speed
	local _input     = { up = false, left = false, down = false, right = false }
	local _direction = dge.direction.down
	local _moving    = false
	local _elapsed   = 0
	local _start     = go.get_position()
	local _target    = go.get_position()
	
	----------------------------------------------------------------------
	-- LOCAL INSTANCE FUNCTIONS
	----------------------------------------------------------------------

	local function to_direction(input)
		local result = 0
		if input.up then
			result = bit.bor(result, dge.direction.up.value)
		end
		if input.left then
			result = bit.bor(result, dge.direction.left.value)
		end
		if input.down then
			result = bit.bor(result, dge.direction.down.value)
		end
		if input.right then
			result = bit.bor(result, dge.direction.right.value)
		end
		return result
	end

	local function snap_position()
		local grid_position = dge.to_grid_coordinates(go.get_position())
		local half_stride = dge.stride * 0.5
		local snap_position = vmath.vector3(grid_position.x * dge.stride - half_stride, grid_position.y * dge.stride - half_stride, grid_position.z)
		go.set_position(snap_position)
		_start = snap_position
		_target = snap_position
		if dge.debug then
			print("DGE: Snapped to position. " .. go.get_id() .. " " .. snap_position)
		end
	end

	local function ordinal_movement()
		return _direction == dge.direction.up_left or _direction == dge.direction.down_left or _direction == dge.direction.down_right or _direction == dge.direction.up_right
	end

	local function lerp_scalar()
		if dge.ordinal and ordinal_movement() then
			return ordinal_scaler
		end
		return 1
	end

	local function lerp(dt)
		_elapsed = _elapsed + dt * _speed * lerp_scalar()
		local progress = vmath.lerp(_elapsed, _start, _target)
		if _elapsed >= 1 then
			msg.post("#", dge.msg.move_end)
			_elapsed = 0
			_moving = false
			_start = _target
			progress = _target
		end
		go.set_position(progress)
	end
	
	----------------------------------------------------------------------
	-- MODULE INSTANCE FUNCTIONS
	----------------------------------------------------------------------

	function member.get_speed()
		return _speed
	end

	function member.set_speed(speed)
		_speed = speed
	end

	function member.is_moving()
		return _moving
	end

	function member.get_direction()
		return _direction
	end

	function member.reach()
		if not _moving then
			return dge.to_grid_coordinates(_target + front[_direction.value] * dge.stride)
		end
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
		if _moving then
			lerp(dt)
			return
		end
		if _input.up then
			if dge.ordinal or not _moving then
				_moving = true
				_target = _target + vmath.vector3(0, dge.stride, 0)
			end
		end
		if _input.left then
			if dge.ordinal or not _moving then
				_moving = true
				_target = _target + vmath.vector3(-dge.stride, 0, 0)
			end
		end
		if _input.down then
			if dge.ordinal or not _moving then
				_moving = true
				_target = _target + vmath.vector3(0, -dge.stride, 0)
			end
		end
		if _input.right then
			if dge.ordinal or not _moving then
				_moving = true
				_target = _target + vmath.vector3(dge.stride, 0, 0)
			end
		end
		if _moving then
			msg.post("#", dge.msg.move_start)
			_direction = to_direction(_input)
			lerp(dt)
		end
	end

	function member.unregister()
		dge.members[go.get_id()] = nil
		if dge.debug then
			print("DGE: Game object unregistered. " .. go.get_id())
		end
	end

	if dge.debug then
		print("DGE: Game object registered. " .. go.get_id())
	end

	snap_position()

	return member
	
end

return dge