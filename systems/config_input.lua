local tiny    = require "tiny"
local cpml    = require "cpml"
local tactile = require "tactile"

return function()
	local system   = tiny.processingSystem()
	system.filter  = tiny.requireAll("possessed", "config_keys")

	function system:onAddToWorld(world)
		-- Shorthand functions
		local a = function(axis, gamepad)
			return tactile.analogStick(axis, gamepad)
		end
		local b = function(neg, pos)
			return tactile.binaryAxis(neg, pos)
		end
		local g = function(button, gamepad)
			return tactile.gamepadButton(button, gamepad)
		end
		local k = tactile.key
		local m = tactile.mouseButton
		local t = function() return false end
		local kb_return = function()
			return love.keyboard.isDown("return") and
				not (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt"))
		end

		-- Left X axis
		local kb_leftx1 = b(k "a",    k "d")
		local kb_leftx2 = b(k "left", k "right")
		local gp_leftx  = a("leftx", 1)

		-- Left Y axis
		local kb_lefty1 = b(k "w",  k "s")
		local kb_lefty2 = b(k "up", k "down")
		local gp_lefty  = a("lefty", 1)

		-- Left trigger
		local kb_triggerleft1 = b(t, k "q")
		local kb_triggerleft2 = b(t, k "kp7")
		local gp_triggerleft  = a("triggerleft", 1)

		-- Right X axis
		-- would be nice to have mouse axes in here?
		local kb_rightx1 = b(k "kp4", k"kp6")
		local kb_rightx2 = b(k "kp4", k"kp6")
		local gp_rightx  = a("rightx", 1)

		-- Rigth Y axis
		-- would be nice to have mouse axes in here?
		local kb_righty1 = b(k "kp2", k"kp8")
		local kb_righty2 = b(k "kp2", k"kp8")
		local gp_righty  = a("righty", 1)

		-- Right trigger
		local kb_triggerright1 = b(t, k "e")
		local kb_triggerright2 = b(t, k "kp9")
		local gp_triggerright  = a("triggerright", 1)

		-- Register buttons
		local keymaps = system.world.cache.keymaps

		table.insert(keymaps, {
			move_x       = tactile.newAxis(gp_leftx,             kb_leftx1,        kb_leftx2),
			move_y       = tactile.newAxis(gp_lefty,             kb_lefty1,        kb_lefty2),
			camera_x     = tactile.newAxis(gp_rightx,            kb_rightx1,       kb_rightx2),
			camera_y     = tactile.newAxis(gp_righty,            kb_righty1,       kb_righty2),
			camera_z_in  = tactile.newAxis(gp_triggerleft,       kb_triggerleft1,  kb_triggerleft2),
			camera_z_out = tactile.newAxis(gp_triggerright,      kb_triggerright1, kb_triggerright2),
			camera_snap  = tactile.newButton(g("rightstick", 1), k "kp5",          m(3)),
			auto_run     = tactile.newButton(g("leftstick", 1),  k "kp/",          m(4)),
			action       = tactile.newButton(g("a", 1),          kb_return,        m(1)),
			back         = tactile.newButton(g("b", 1),          k "space",        k "kp0"),
			menu         = tactile.newButton(g("start", 1),      g("y", 1),        k "escape", m(2), m(5)),
			menu_back    = tactile.newButton(g("start", 1),      g("b", 1),        k "escape", m(3)),
			menu_action  = tactile.newButton(g("a", 1),          kb_return,        k "space"),
			menu_up      = tactile.newButton(g("dpup", 1),       k "up",           k "w"),
			menu_down    = tactile.newButton(g("dpdown", 1),     k "down",         k "s"),
			menu_left    = tactile.newButton(g("dpleft", 1),     k "left",         k "a"),
			menu_right   = tactile.newButton(g("dpright", 1),    k "right",        k "d")
		})

		-- fuck off I'll deadzone this myself
		keymaps[1].move_x.deadzone = 0.1
		keymaps[1].move_y.deadzone = 0.1
	end

	function system:process(entity, dt)
		local player = entity.possessed
	end

	return system
end
