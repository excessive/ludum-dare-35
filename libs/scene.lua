--[[
Copyright (c) 2010-2013 Matthias Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

local function __NULL__() end

 -- default gamestate produces error on every callback
local state_init = setmetatable({leave = __NULL__, world = false},
		{__index = function() error("Gamestate not initialized. Use Gamestate.switch()") end})
local stack = {state_init}
local world

local GS = {}
function GS.new(t) return t or {} end -- constructor - deprecated!

function GS.switch(to, ...)
	assert(to, "Missing argument: Gamestate to switch to")
	assert(to ~= GS, "Can't call switch with colon operator")
	assert(world, "World not set: Use Gamestate.set_world()")

	local result

	-- xpcall(function(...)
		local pre = stack[#stack]
		world:addSystem(to)
		;(pre.leave or __NULL__)(pre)
		;(to.init or __NULL__)(to)
		to.init = nil
		stack[#stack] = to
		if pre.world then
			pre.world:removeSystem(pre)
			pre.active = false
			to.active = true
		end
		result = (to.enter or __NULL__)(to, pre, ...)
	-- end, function(msg)
		-- console.e(msg)
	-- end, ...)

	return result
end

function GS.push(to, ...)
	assert(to, "Missing argument: Gamestate to switch to")
	assert(to ~= GS, "Can't call push with colon operator")
	local pre = stack[#stack]
	world:addSystem(to)
	;(to.init or __NULL__)(to)
	to.init = nil
	stack[#stack+1] = to
	if pre.world then
		pre.active = false
		to.active = true
	end
	return (to.enter or __NULL__)(to, pre, ...)
end

function GS.pop(...)
	assert(#stack > 1, "No more states to pop!")
	local pre, to = stack[#stack], stack[#stack-1]
	stack[#stack] = nil
	;(pre.leave or __NULL__)(pre)
	if to.world then
		pre.active = false
		to.world:removeSystem(pre)
		to.active = true
	end
	return (to.resume or __NULL__)(to, pre, ...)
end

function GS.current()
	return stack[#stack]
end

local all_callbacks = {
	'focus', 'keypressed', 'keyreleased', 'mousefocus', 'mousemoved',
	'mousepressed', 'mousereleased', 'resize', 'textedit', 'textinput',
	'visible', 'gamepadaxis', 'gamepadpressed', 'gamepadreleased',
	'joystickadded', 'joystickaxis', 'joystickhat', 'joystickpressed',
	'joystickreleased', 'joystickremoved'
}

function GS.set_world(new_world)
	world = new_world
end

function GS.register_callbacks(callbacks)
	if FLAGS.debug_mode then
		console.defineCommand("initial-screen", "Set initial screen for reloads", function(screen)
			initial_screen = screen ~= "" and "scenes." .. screen or false
		end)
	end

	local registry = {}
	callbacks = callbacks or all_callbacks
	for _, f in ipairs(callbacks) do
		registry[f] = love[f] or __NULL__
		love[f] = function(...)
			-- quit is special, make sure GS gets it first!
			if f == "quit" then
				return GS[f](...) or registry[f](...)
			else
				return registry[f](...) or GS[f](...)
			end
		end
	end
end

-- forward any undefined functions
setmetatable(GS, {__index = function(_, func)
	return function(...)
		return (stack[#stack][func] or __NULL__)(stack[#stack], ...)
	end
end})

return GS