local tiny  = require "tiny"
local cpml  = require "cpml"

return tiny.processingSystem {
	filter         = tiny.requireAll("possessed", "orientation"),
	in_menu        = false,
	dead_zone      = 0.25,
	sfx = {
		atk_attack = love.audio.newSource("assets/sfx/sword_swing.wav"),
		def_attack = love.audio.newSource("assets/sfx/sword_swing.wav"),
		spd_attack = love.audio.newSource("assets/sfx/sword_swing.wav"),

		atk_pattack = love.audio.newSource("assets/sfx/player_swing.wav"),
		def_pattack = love.audio.newSource("assets/sfx/player_swing.wav"),
		spd_pattack = love.audio.newSource("assets/sfx/player_shoot.wav"),

		player_hurt1 = love.audio.newSource("assets/sfx/player_ouch.wav"),
		player_hurt2 = love.audio.newSource("assets/sfx/player_scream.wav"),

		step  = love.audio.newSource("assets/sfx/step.wav")
	},
	toggle_mouse   = function(self)
		love.mouse.setRelativeMode(not love.mouse.getRelativeMode())
		love.mouse.setVisible(not love.mouse.isVisible())
	end,
	onAddToWorld = function(self)
		self.sfx.step:setLooping(true)
		self.sfx.step:setRelative(true)
		self.sfx.step:setVolume(0.5)
		self.sfx.atk_attack:setRelative(true)
		self.sfx.def_attack:setRelative(true)
		self.sfx.spd_attack:setRelative(true)
		self.sfx.atk_pattack:setRelative(true)
		self.sfx.def_pattack:setRelative(true)
		self.sfx.spd_pattack:setRelative(true)
	end,
	onAdd = function(self, entity)
		entity.orientation_offset = cpml.quat(0, 0, 0, 1)
	end,
	process = function(self, entity, dt)
		local gi = self.world.inputs.game

		-- Check buttons
		local action      = gi.action:pressed()
		local dodge       = gi.dodge:pressed()
		local menu        = gi.menu:pressed()
		local menu_back   = gi.menu_back:pressed()
		local menu_action = gi.menu_action:pressed()
		local menu_up     = gi.menu_up:pressed()
		local menu_down   = gi.menu_down:pressed()
		local menu_left   = gi.menu_left:pressed()
		local menu_right  = gi.menu_right:pressed()

		-- Check axes
		local move_x = gi.move_x:getValue()
		local move_y = gi.move_y:getValue()

		--== Menu ==--
		if menu then
			self.in_menu = not self.in_menu
			-- self:toggle_mouse()
		end

		--== Camera ==--

		local camera = self.world.camera_system.active_camera
		-- camera.position = entity.position + cpml.vec3(0, -3.75, 7)

		--== Movement ==--
		local snap_cancel = false

		local move  = cpml.vec3(move_x, -move_y, 0)
		local speed = 5
		local l     = move:len()

		-- Each axis had a deadzone, but we also want a little more overall.
		if l < self.dead_zone then
			move.x = 0
			move.y = 0
		elseif l > 1 then
			-- normalize
			move = move / l
		end

		--== Orientation ==--
		local angle = cpml.vec2(move.x, move.y):angle_to() - math.pi / 2

		-- Change direction player is facing, as long as they aren't mid-attack
		if move.x ~= 0 or move.y ~= 0 and entity.anim_cooldown <= 0 then
			local snap_to = camera.orientation:clone() * cpml.quat.rotate(angle, cpml.vec3(0, 0, 1))

			if entity.snap_to then
				-- Directions
				local current = entity.snap_to * cpml.vec3.unit_y
				local next    = snap_to * cpml.vec3.unit_y
				local from    = current:dot(camera.direction)
				local to      = next:dot(camera.direction)

				-- If you move in the opposite direction, snap to end of slerp
				if from ~= to and math.abs(from) - math.abs(to) == 0 then
					entity.orientation = entity.snap_to:clone()
				end
			end

			entity.snap_to = snap_to
			entity.slerp   = 0
		end

		if entity.snap_to and entity.anim_cooldown <= 0 then
			entity.orientation   = entity.orientation:slerp(entity.snap_to, 8*dt*2)
			entity.orientation.x = 0
			entity.orientation.y = 0
			entity.orientation   = entity.orientation:normalize()
			entity.slerp         = entity.slerp + dt

			if entity.slerp > 1/2 then
				entity.snap_to = nil
				entity.slerp   = 0
			end
		end

		if action or dodge then
			snap_cancel = true
		end

		--- cancel the orientation transition if needed
		if snap_cancel and entity.snap_to then
			entity.orientation = entity.snap_to:clone()
			entity.orientation.x = 0
			entity.orientation.y = 0
			entity.orientation   = entity.orientation:normalize()

			entity.snap_to   = nil
			entity.slerp     = 0
		end

		entity.direction = entity.orientation * -cpml.vec3.unit_y

		-- Move
		entity.move = entity.orientation * cpml.quat.rotate(-angle, cpml.vec3(0, 0, 1)) * move

		if entity.anim_cooldown == 0 then
			entity.velocity = move * entity.speed * dt
			entity.dodging  = false
			entity.blocking = false
		elseif entity.dodging then
			entity.velocity = entity.dodging * (entity.speed * 1.5) * dt
			entity.position = entity.position + entity.velocity
		elseif entity.blocking then
			entity.velocity = cpml.vec3()
		end

		-- anim9
		if entity.anim_cooldown == 0 then
			if dodge and entity.stat ~= "def" then
				entity.animation:reset()
				entity.animation:play(entity.stat .. "_dodge")

				entity.dodging = entity.direction
				if entity.stat == "spd" then
					entity.dodging = -entity.dodging
				end

				entity.cooldown      = entity.max_cooldown
				entity.anim_cooldown = entity.animation:length()
				self.sfx[entity.stat .. "_pattack"]:setVolume(0.5)
				self.sfx[entity.stat .. "_pattack"]:setPitch(0.9)
				self.sfx[entity.stat .. "_pattack"]:stop()
				self.sfx[entity.stat .. "_pattack"]:play()
			elseif dodge and entity.stat == "def" then
				entity.animation:reset()
				entity.animation:play("def_block")

				entity.blocking      = true
				entity.cooldown      = entity.max_cooldown
				entity.anim_cooldown = entity.animation:length()
				self.sfx["def_pattack"]:setVolume(0.5)
				self.sfx["def_pattack"]:setPitch(0.9)
				self.sfx["def_pattack"]:stop()
				self.sfx["def_pattack"]:play()

				conversation:say("knockback", self.world.attack)
			elseif l == 0 then
				entity.animation:play(entity.stat .. "_idle")
				self.sfx.step:stop()
			else
				entity.animation:play(entity.stat .. "_run")
				self.sfx.step:play()
			end
		end

		--== Actions ==--
		if entity.regen_cooldown == 0 and entity.hp < entity.max_hp then
			entity.hp = math.min(entity.hp + dt * 20, entity.max_hp)

			if entity.hp == entity.max_hp then
				entity.regen_cooldown = false
				conversation:say("max hp")
			end
		end

		-- We don't want these to happen if you're just trying to click
		-- menu buttons, so cancel out.
		if self.in_menu then
			return
		end

		-- Do attack
		if action and entity.cooldown == 0 then
			entity.attacking = true
			entity.animation:reset()

			-- Perform animation
			entity.animation:play(entity.stat .. "_attack")
			self.sfx.step:stop()

			-- Weapon sound
			self.sfx[entity.stat .. "_attack"]:setVolume(0.75)
			self.sfx[entity.stat .. "_attack"]:stop()
			self.sfx[entity.stat .. "_attack"]:play()

			-- Player sound
			self.sfx[entity.stat .. "_pattack"]:setVolume(0.75)
			self.sfx[entity.stat .. "_pattack"]:setPitch(1.0 + math.random() * 0.075)
			self.sfx[entity.stat .. "_pattack"]:stop()
			self.sfx[entity.stat .. "_pattack"]:play()

			-- Set cooldowns
			entity.cooldown       = entity.max_cooldown
			entity.anim_cooldown  = entity.animation:length()
			entity.regen_cooldown = 7
		end
	end
}
