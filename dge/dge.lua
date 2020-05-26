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

local direction = {
	up          = 1,
	left        = 2,
	down        = 4,
	right       = 8,
	up_left     = 3,
	down_left   = 6,
	down_right  = 12,
	up_right    = 9
}

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

function dge.init(config)
	dge.debug = config.debug
	dge.stride = config.stride
	dge.ordinal = config.ordinal
	if config.debug then
		print("DGE: Initialized.")
	end
end

function dge.register(config)
	
	dge.members[go.get_id()] = true
	
	----------------------------------------------------------------------
	-- INSTANCE PROPERTIES
	----------------------------------------------------------------------

	local member  = {}
	local speed   = config.speed
	local input   = { up = 0, left = 0, down = 0, right = 0 }
	local moving  = false
	local elapsed = 0
	local start   = go.get_position()
	local target  = start
	local facing  = direction.down
	
	----------------------------------------------------------------------
	-- INSTANCE FUNCTIONS
	----------------------------------------------------------------------

	local function lerp(dt)
		elapsed = elapsed + dt * speed
		local progress = vmath.lerp(elapsed, start, target)
		if elapsed >= 1 then
			elapsed = 0
			moving = false
			start = target
			progress = target
		end
		go.set_position(progress)
	end

	function member.reach()
		local result = go.get_position()
		if facing == direction.up then
			result.y = result.y + dge.stride
		elseif facing == direction.left then
			result.x = result.x - dge.stride
		elseif facing == direction.down then
			result.y = result.y - dge.stride
		elseif facing == direction.right then
			result.x = result.x + dge.stride
		elseif facing == direction.up_left then
			result.x = result.x - dge.stride
			result.y = result.y + dge.stride
		elseif facing == direction.down_left then
			result.x = result.x - dge.stride
			result.y = result.y - dge.stride
		elseif facing == direction.down_right then
			result.x = result.x + dge.stride
			result.y = result.y - dge.stride
		elseif facing == direction.up_right then
			result.x = result.x + dge.stride
			result.y = result.y + dge.stride
		end
		return { x = math.floor(result.x / dge.stride + 1), y = math.floor(result.y / dge.stride + 1) }
	end

	function member.move_up()
		input.up = 1
	end

	function member.move_left()
		input.left = -1
	end

	function member.move_down()
		input.down = -1
	end

	function member.move_right()
		input.right = 1
	end

	function member.stop_up()
		input.up = 0
	end

	function member.stop_left()
		input.left = 0
	end

	function member.stop_down()
		input.down = 0
	end

	function member.stop_right()
		input.right = 0
	end

	function member.update(dt)
		if moving then
			lerp(dt)
			return
		end
		if input.up ~= 0 then
			moving = true
			target = target + vmath.vector3(0, dge.stride, 0)
			facing = bit.bor(facing, direction.up)
		end
		if input.left ~= 0 then
			moving = true
			target = target + vmath.vector3(-dge.stride, 0, 0)
			facing = bit.bor(facing, direction.left)
		end
		if input.down ~= 0 then
			moving = true
			target = target + vmath.vector3(0, -dge.stride, 0)
			facing = bit.bor(facing, direction.down)
		end
		if input.right ~= 0 then
			moving = true
			target = target + vmath.vector3(dge.stride, 0, 0)
			facing = bit.bor(facing, direction.right)
		end
		if moving then
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

	return member
	
end

return dge