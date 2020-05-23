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



----------------------------------------------------------------------
-- MODULE PROPERTIES
----------------------------------------------------------------------

dge.members = {}
dge.debug = false
dge.stride = 16

----------------------------------------------------------------------
-- MODULE FUNCTIONS
----------------------------------------------------------------------

function dge.init(config)
	dge.debug = config.debug
	dge.stride = config.stride
	if config.debug then
		print("DGE: Initialized.")
	end
end

function dge.register(config)
	
	dge.members[go.get_id()] = true
	
	----------------------------------------------------------------------
	-- INSTANCE PROPERTIES
	----------------------------------------------------------------------

	local member = {}
	local speed = config.speed
	local input = { up = 0, left = 0, down = 0, right = 0 }
	local moving = false
	local elapsed = 0
	local start = go.get_position()
	local target = start
	
	----------------------------------------------------------------------
	-- INSTANCE FUNCTIONS
	----------------------------------------------------------------------

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
			elapsed = elapsed + dt
			local ratio = dge.stride / speed
			local progress = vmath.lerp(elapsed * ratio, start, target)
			if elapsed >= 1 then
				elapsed = 0
				moving = false
				start = target
				progress = target
			end
			go.set_position(progress)
		else
			if input.up ~= 0 then
				moving = true
				target = target + vmath.vector3(0, dge.stride, 0)
			end
			if input.left ~= 0 then
				moving = true
				target = target + vmath.vector3(-dge.stride, 0, 0)
			end
			if input.down ~= 0 then
				moving = true
				target = target + vmath.vector3(0, -dge.stride, 0)
			end
			if input.right ~= 0 then
				moving = true
				target = target + vmath.vector3(dge.stride, 0, 0)
			end
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