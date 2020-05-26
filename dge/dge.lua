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

----------------------------------------------------------------------
-- MODULE PROPERTIES
----------------------------------------------------------------------

dge.members = {}
dge.debug   = false
dge.stride  = 0
dge.ordinal = true

----------------------------------------------------------------------
-- MODULE FUNCTIONS
----------------------------------------------------------------------

local function to_pixel_coordinates(grid_coordinates)
	return vmath.vector3(math.floor(grid_coordinates.x * dge.stride), math.floor(grid_coordinates.y * dge.stride), grid_coordinates.z)
end

local function to_grid_coordinates(pixel_coordinates)
	return vmath.vector3(math.floor(pixel_coordinates.x / dge.stride) + 1, math.floor(pixel_coordinates.y / dge.stride) + 1, pixel_coordinates.z)
end

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

function dge.set_debug(debug)
	dge.debug = debug
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

function dge.register(config)
	
	dge.members[go.get_id()] = true
	
	----------------------------------------------------------------------
	-- INSTANCE PROPERTIES
	----------------------------------------------------------------------

	local member   = {}
	local _speed   = config.speed
	local _input   = { up = false, left = false, down = false, right = false }
	local _moving  = false
	local _elapsed = 0
	local _start   = go.get_position()
	local _target  = _start
	local _front   = _start
	
	----------------------------------------------------------------------
	-- LOCAL INSTANCE FUNCTIONS
	----------------------------------------------------------------------

	local function snap_position()
		local grid_positon = to_grid_coordinates(go.get_position())
		local half_stride = dge.stride * 0.5
		local snap_position = vmath.vector3(grid_positon.x * dge.stride - half_stride, grid_positon.y * dge.stride - half_stride, grid_positon.z)
		go.set_position(snap_position)
		_moving = false
		_elapsed = 0
		_start = snap_position
		_target = _start
		_front = _start
	end

	local function ordinal_movement()
		return (_input.up and (_input.left or _input.right)) or (_input.down and (_input.left or _input.right))
	end

	local function lerp_scalar()
		return 1
	end

	local function lerp(dt)
		_elapsed = _elapsed + dt * _speed
		local progress = vmath.lerp(_elapsed, _start, _target)
		if _elapsed >= 1 then
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

	function member.get_moving()
		return _moving
	end

	function member.reach()
		if not _moving then
			return to_grid_coordinates(_front)
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
				_front = _target + vmath.vector3(0, dge.stride, 0)
			end
		end
		if _input.left then
			if dge.ordinal or not _moving then
				_moving = true
				_target = _target + vmath.vector3(-dge.stride, 0, 0)
				_front = _target + vmath.vector3(-dge.stride, 0, 0)
			end
		end
		if _input.down then
			if dge.ordinal or not _moving then
				_moving = true
				_target = _target + vmath.vector3(0, -dge.stride, 0)
				_front = _target + vmath.vector3(0, -dge.stride, 0)
			end
		end
		if _input.right then
			if dge.ordinal or not _moving then
				_moving = true
				_target = _target + vmath.vector3(dge.stride, 0, 0)
				_front = _target + vmath.vector3(dge.stride, 0, 0)
			end
		end
		if _moving then
			lerp(dt)
		end
	end

	function member.unregister()
		dge.members[go.get_id()] = nil
		if dge.debug then
			print("DGE: Game object unregistered. " .. go.get_id())
		end
	end

	print("DGE: Game object registered. " .. go.get_id())

	snap_position()

	return member
	
end

return dge