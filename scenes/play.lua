local tiny       = require "tiny"
local lume       = require "lume"
local memoize    = require "memoize"
local cpml       = require "cpml"
local iqm        = require "iqm"
local anim9      = require "anim9"
local map_loader = require "map"
local Grid       = require "jumper.grid"
local anchor     = require "anchor"
local timer      = require "timer"
local convoke    = require "convoke"

conversation = require("talkback").new()

local gp = tiny.system {
	name = "gameplay",
	next_scene = "scenes.win",
	overlay = {
		opacity = 0
	},
	draw_text = function(self, text, len)
		self.subtitle.text    = text
		self.subtitle.opacity = 0

		convoke(function(continue, wait)
			self.timer.tween(0.25, self.subtitle, { opacity=255 }, 'out-cubic', continue())
			wait()

			self.timer.add(len, continue())
			wait()

			self.timer.tween(0.25, self.subtitle, { opacity=0 }, 'out-cubic', continue())
			wait()

			self.subtitle.text = ""
		end)()
	end
}


local stats = { "atk", "spd", "def" }
-- unused but I want the table
local winning_matchup = {
	atk = "def",
	def = "spd",
	spd = "atk",
}
local losing_matchup = {
	def = "atk",
	spd = "def",
	atk = "spd"
}

local load_model = memoize(function(path, actor)
	return iqm.load(path, actor)
end)

local load_anims
do
	local _lanim = memoize(function(path)
		return iqm.load_anims(path)
	end)
	load_anims = function(path)
		return anim9(_lanim(path))
	end
end

local load_sound = memoize(function(filename)
	return love.audio.newSource(filename)
end)

local load_font = memoize(function(filename, size)
	return love.graphics.newFont(filename, size)
end)

local entities = {
	spawn   = require "assets.entities.spawn",
	tiger   = require "assets.entities.tiger",
	player  = require "assets.entities.player",
	grandpa = require "assets.entities.grandpa"
}

local tigers = {
	{ "ULTRA TAIGA",              "atk", { atk=10, def=5, spd=3 },  150, 1.75 },
	{ "Tony",                     "atk", { atk=5,  def=3, spd=1 },   50, 1 },
	{ "Tonya",                    "spd", { atk=3,  def=1, spd=5 },   50, 1 },
	{ "Kahn",                     "def", { atk=2,  def=7, spd=2 },   75, 1.2 },
	{ "Nyanners",                 "atk", { atk=1,  def=1, spd=1 },   35, 0.65 },
	{ "Steve",                    "def", { atk=3,  def=3, spd=3 },   65, 1 },
	{ "xXx_420_n0_Sc0p3_420_xXx", "spd", { atk=1,  def=1, spd=10 }, 150, 0.35 },
}

local function set_stats(player, stat)
	stat = stat or lume.randomchoice(stats)

	if player.stat == stat then
		return
	end

	local text, sfx, shift
	if stat == "atk" then
		text, sfx = gp.world.language:get("play/player_hickory")
		-- print(_, sfx)
		shift = load_sound(sfx)
		player.weapon_radius = 1.5
		player.weapon_size = 0.55
		player.max_cooldown = 1
		player.speed = 3
	elseif stat == "def" then
		text, sfx = gp.world.language:get("play/player_shrublord")
		shift = load_sound(sfx)
		player.weapon_radius = 1
		player.weapon_size = 0.7
		player.max_cooldown = 1
		player.speed = 3
	else
		text, sfx = gp.world.language:get("play/player_bow")
		shift = load_sound(sfx)
		player.weapon_radius = 7.5
		player.weapon_size = 0.35
		player.max_cooldown = 0.65
		player.speed = 5
	end
	shift:setRelative(true)
	shift:play()
	gp:draw_text(text, 2)

	-- reset everything
	player.stats.atk = -5
	player.stats.def = -5
	player.stats.spd = -5

	-- boost the selected stat
	player.stats[stat] = 10
	player.stat = stat

	-- Adjust player speed
	--player.max_cooldown = 0.7 + (player.stats.spd * -0.05)
	--player.speed        = 4.0 + (player.stats.spd *  0.25)
end

function gp:enter(from, ngp)
	self.ngp = ngp
	self.time = 0
	self.subtitle  = {
		text    = "",
		opacity = 0,
		font    = love.graphics.newFont("assets/fonts/NotoSans-Regular.ttf", 18)
	}

	love.graphics.setBackgroundColor(115, 145, 105)
	-- love.graphics.setBackgroundColor(100, 10, 10)

	local map, grid_offset = map_loader.load(self.world, "assets/levels/level.lua")
	self.world.nav_grid = Grid(map)
	self.world.grid_offset = cpml.vec3(grid_offset)

	self.camera = self.world:addEntity {
		name        = "Camera",
		camera      = true,
		fov         = 60,
		near        = 0.0001,
		far         = 100,
		exposure    = 1.025,
		position    = cpml.vec3(0, 0, 0),
		orientation = cpml.quat(0, 0, 0, 1) * cpml.quat.rotate(math.pi, cpml.vec3.unit_z),
		offset      = cpml.vec3(0, 0, -0.25)
	}
	self.camera.orientation = self.camera.orientation * cpml.quat.rotate(math.pi/3, cpml.vec3.unit_x)
	self.camera.direction   = self.camera.orientation * -cpml.vec3.unit_y

	-- Add spawn points
	self.world:addEntity(entities.spawn(self.world, "Spawn.01", cpml.vec3(  1.0,  10.5, 0), 1))
	self.world:addEntity(entities.spawn(self.world, "Spawn.02", cpml.vec3(-12.5,  27.5, 0), 5))
	self.world:addEntity(entities.spawn(self.world, "Spawn.03", cpml.vec3( -5.0,   4.5, 0), 3))
	self.world:addEntity(entities.spawn(self.world, "Spawn.04", cpml.vec3( 17.5,  27.5, 0), 7))
	self.world:addEntity(entities.spawn(self.world, "Spawn.05", cpml.vec3( 17.5, -22.0, 0), 6))
	self.world:addEntity(entities.spawn(self.world, "Spawn.06", cpml.vec3( 15.0,   7.5, 0), 4))
	self.world:addEntity(entities.spawn(self.world, "Spawn.07", cpml.vec3( -2.5, -25.0, 0), 2))
	self.world:addEntity(entities.spawn(self.world, "Spawn.08", cpml.vec3(-17.5,  -7.5, 0), 3))
	self.world:addEntity(entities.spawn(self.world, "Spawn.09", cpml.vec3( 10.0, -30.0, 0), 6))
	self.world:addEntity(entities.spawn(self.world, "Spawn.10", cpml.vec3( -5.0, -12.5, 0), 2))
	self.world:addEntity(entities.spawn(self.world, "Spawn.11", cpml.vec3( 17.5,  -5.0, 0), 4))

	-- Add player
	self.player = self.world:addEntity(entities.player(self.world, self.ngp))
	self.world.player = self.player

	local light = self.world:addEntity {
		name        = "Sol",
		light       = true,
		direction   = cpml.vec3(0.2, 0.1, 0.7):normalize(),
		color       = { 1.6, 1.10, 1.10 },
		position    = cpml.vec3(3, -2.1, 0),
		intensity   = 1,
		range       = 12.5,
		-- range       = 40,
		fov         = 25,
		near        = 1.0,
		far         = 100.0,
		bias        = 1.0e-4,
		depth       = 50,
		cast_shadow = true
	}

	self.world:addEntity {
		name        = "Sol 2",
		light       = true,
		direction   = cpml.vec3(0.0, 0.0, 1.0):normalize(),
		color       = { 0.1, 0.2, 1.0 },
		intensity   = 5,
		cast_shadow = false
	}

	-- SQUAWK
	local bird = false
	if FLAGS.debug_mode then
		console.defineCommand(
			"bird",
			"bird",
			function()
				bird = not bird
				if bird then
					self.world.renderer.lights[1].range = 40
				else
					self.world.renderer.lights[1].range = 12.5
				end
			end
		)
		console.defineCommand(
			"luna",
			"can't see shit capn",
			function()
				if light.intensity < 5 then
					self.timer.tween(0.5, light, { intensity = 10 }, "in-out-quad")
				else
					self.timer.tween(0.5, light, { intensity = 1 }, "in-out-quad")
				end
			end
		)
	end

	conversation:listen("aggro", function(enemy)
		self.aggro = enemy
	end)

	conversation:listen("aggro reset", function(enemy)
		if self.aggro == enemy then
			self.aggro = false
		end
	end)

	conversation:listen("hit", function(enemy)
		set_stats(self.player, losing_matchup[enemy.primary_stat])
	end)

	conversation:listen("player died", function()
		local sfx = load_sound("assets/sfx/player_scream.wav")
		sfx:setPosition((self.player.position / 10):unpack())
		sfx:play()

		self.dead = true
		self.timer.tween(2.5, light, { intensity = 1, color = { 1.1, 0.0, 0.0 } }, "in-out-quad")

		self.timer.add(5, function()
			require("fire").reset_the_world()
		end)

		self.world:removeEntity(self.player)
	end)

	conversation:listen("killed enemy", function(enemy)
		local sfx = load_sound("assets/sfx/tiger_mrow.wav")
		sfx:setPosition((enemy.position / 10):unpack())
		sfx:play()

		self.timer.tween(0.25, light, { intensity = 15 }, "in-out-quad")
		self.timer.add(0.25, function()
			self.timer.tween(0.25, light, { intensity = 10 }, "in-out-quad")
		end)

		if enemy.name == tigers[1][1] then
			self.player_controller.active = false
			self.movement.active          = false
			self.ai_movement.active       = false

			-- Overlay fade
			convoke(function(continue, wait)
				-- Wait briefly
				self.timer.add(2, continue())
				wait()
				-- Fade out
				self.timer.tween(1.25, self.overlay, {opacity=255}, 'out-cubic', continue())
				wait()
				-- Wait briefly
				self.timer.add(0.25, continue())
				wait()
				-- Switch
				self.world:clearEntities()
				Scene.switch(require(self.next_scene), self.ngp)
			end)()
		end

		self.world:removeEntity(enemy)
	end)

	conversation:listen("take damage", function()
		local sfx = load_sound("assets/sfx/player_ouch.wav")
		sfx:setPosition((self.player.position / 10):unpack())
		sfx:play()
	end)

	conversation:listen("spawn tiger", function(position, variant)
		self.timer.add(1, function()
			self.world:addEntity(entities.tiger(
				self.world,
				position,
				unpack(tigers[variant])
			))

			local text, sfx = gp.world.language:get("play/player_taiga")
			sfx = load_sound(sfx)
			sfx:play()
			gp:draw_text(text, 2)
		end)
	end)

	conversation:listen("draw_text", function(text, len) self:draw_text(text, len) end)


	self.timer = timer.new()
	conversation:listen("max hp", function()
		self.flashing_hp = self.time
		self.timer.add(1.5, function()
			self.flashing_hp = false
		end)
	end)

	self.world.audio_system = self.world:addSystem(tiny.system {
		update = function()
			love.audio.setPosition((self.player.position / 10):unpack())
		end
	})

	self.world:addEntity {
		sound = load_sound("assets/sfx/birdsong_a.wav"),
		position = cpml.vec3(-21, 22, 2),
		sound_volume = 0.25
	}
	self.world:addEntity {
		sound = load_sound("assets/sfx/birdsong_b.wav"),
		position = cpml.vec3(-11, 14, 1),
		sound_volume = 0.95
	}
	self.world:addEntity {
		sound = load_sound("assets/sfx/birdsong_a.wav"),
		position = cpml.vec3(-7, 9, 1),
		sound_volume = 0.25
	}
	self.world:addEntity {
		sound = load_sound("assets/sfx/birdsong_a.wav"),
		position = cpml.vec3(-12, -17, 2),
		sound_volume = 0.5
	}
	self.world:addEntity {
		sound = load_sound("assets/sfx/birdsong_a.wav"),
		position = cpml.vec3(21, 22, 2),
		sound_volume = 0.5
	}
	self.world:addEntity {
		sound = load_sound("assets/sfx/birdsong_b.wav"),
		position = cpml.vec3(11, 14, 1),
		sound_volume = 0.75
	}
	self.world:addEntity {
		sound = load_sound("assets/sfx/birdsong_b.wav"),
		position = cpml.vec3(-4, 12, 1),
		sound_volume = 0.65
	}
	self.world:addEntity {
		sound = load_sound("assets/sfx/birdsong_b.wav"),
		position = cpml.vec3(12, 17, 2),
		sound_volume = 0.75
	}

	self.player_controller = self.world:addSystem(require "systems.player_controller")
	self.attack            = self.world:addSystem(require "systems.attack")
	self.movement          = self.world:addSystem(require "systems.movement")
	self.spawn             = self.world:addSystem(require "systems.spawn")
	self.ai                = self.world:addSystem(require "systems.ai")
	self.ai_movement       = self.world:addSystem(require "systems.ai_movement")
	self.collision         = self.world:addSystem(require "systems.collision")
	self.animation         = self.world:addSystem(require "systems.animation")
	self.audio             = self.world:addSystem(require "systems.audio")

	self.world.attack = self.attack
	conversation:listen("knockback", self.attack.knockback)

	-- Make the light and camera follow the player
	self.world:addSystem(tiny.system {
		update = function()
			light.position = self.player.position:clone()
		end
	})

	self.world:addSystem(tiny.system {
		update = function()
			self.camera.position = self.player.position + cpml.vec3(0, -3.75, 7)
			if bird then
				self.camera.position = self.player.position + cpml.vec3(0, -30.75/2, 50/2)
			end
		end
	})

	self.player_controller.active = false

	-- local _, sfx = gp.world.language:get("play/grandpa_letter")
	-- local gpa = load_sound(sfx)
	-- gpa:setRelative(true)
	-- gpa:play()
	-- self.timer.add(gpa:getDuration(), f)

	local text, sfx = gp.world.language:get("play/player_pine")
	local pine = load_sound(sfx)
	pine:setRelative(true)

	self.timer.add(0.25, function()
		pine:play()
		self:draw_text(text, 3)
		self.timer.add(2.0, function()
			self.player_controller.active = true
		end)
		self.timer.add(1.5, function()
			self.timer.tween(0.5, light, { intensity = 10 }, "in-out-quad")
		end)
	end)

	-- Always refresh before playing with system indices...
	self.world:refresh()
	self.world:setSystemIndex(self.world.inputs, 1)
	self.world:setSystemIndex(self.world.audio_system, 2)
	self.world:setSystemIndex(self.player_controller, 3)
end

function gp:update(dt)
	self.time = self.time + dt
	self.timer.update(dt)
end

function gp:draw()
	local sf = string.format

	love.graphics.setColor(0, 0, 0, 220)
	love.graphics.push()

	local sections = 100 / 5
	local width = 250
	local height = 35
	love.graphics.translate(anchor:left(), anchor:bottom() - height)
	love.graphics.shear(-0.2, 0)
	love.graphics.rectangle("fill", 0, 0, width+77, height)
	love.graphics.rectangle("fill", -8, -22, 155, 22)

	local a = cpml.vec3(230, 80, 100)
	local b = cpml.vec3(40, 200, 90)
	local f = cpml.vec3(50, 110, 200) -- flash color
	for i = 0, math.ceil(self.player.hp / 5)-1 do
		local c =  cpml.utils.lerp(math.pow(i / sections, 0.5), a, b)
		love.graphics.setColor(c.x, c.y, c.z, 255)
		if math.floor(self.time * 5) % 2 == 0 and self.player.hp <= 25 then
			love.graphics.setColor(c.x, c.y, c.z, 100)
		elseif self.flashing_hp then
			c =  cpml.utils.lerp(math.sin((self.time - self.flashing_hp) * 10), c, f)
			love.graphics.setColor(c.x, c.y, c.z, 100)
		end
		love.graphics.rectangle("fill", i*(width/sections)+1, 1, width / sections - 2, height-2)
	end

	love.graphics.setFont(load_font("assets/fonts/NotoSans-Bold.ttf", 18))
	love.graphics.setColor(0, 0, 0, 180)
	love.graphics.print(sf("HP: %d",  self.player.hp), width + 3, 5)
	love.graphics.setColor(255, 255, 255, 220)
	love.graphics.print(sf("HP: %d",  self.player.hp), width + 5, 3)

	local small_scale = 0.8

	love.graphics.translate(-8, 0)

	love.graphics.push()
	if self.player.stat ~= "atk" then
		love.graphics.scale(small_scale, small_scale)
		love.graphics.translate(15, -2)
		love.graphics.setColor(a.x, a.x, a.z, 150)
	else
		love.graphics.setColor(b.x, b.y, b.z, 255)
		love.graphics.translate(10, 0)
	end
	love.graphics.print(sf("ATK", self.player.stats.atk), 0, -24)
	love.graphics.pop()

	love.graphics.push()
	if self.player.stat ~= "def" then
		love.graphics.scale(small_scale, small_scale)
		love.graphics.translate(15, -2)
		love.graphics.setColor(a.x, a.x, a.z, 150)
	else
		love.graphics.setColor(b.x, b.y, b.z, 255)
	end
	love.graphics.print(sf("DEF", self.player.stats.def), 60, -24)
	love.graphics.pop()

	love.graphics.push()
	if self.player.stat ~= "spd" then
		love.graphics.scale(small_scale, small_scale)
		love.graphics.translate(15, -2)
		love.graphics.setColor(a.x, a.x, a.z, 150)
	else
		love.graphics.setColor(b.x, b.y, b.z, 255)
		love.graphics.translate(-10, 0)
	end
	love.graphics.print(sf("SPD", self.player.stats.spd), 120, -24)
	love.graphics.pop()

	love.graphics.pop()

	-- Draw subtitles
	local o = love.graphics.getFont()
	local f = self.subtitle.font
	local w = f:getWidth(self.subtitle.text)
	local c = anchor:center_x()
	local b = anchor:bottom()

	love.graphics.setColor(255, 255, 255, self.subtitle.opacity)
	love.graphics.setFont(f)
	if self.subtitle.text == "kek" then
		self.subtitle.text = ""
	end
	love.graphics.print(self.subtitle.text, c - w/2, b - 50)
	love.graphics.setFont(o)
	love.graphics.setColor(255, 255, 255, 255)

	if not self.player_controller.active then
		-- Full screen fade, we don't care about logical positioning for this.
		local w, h = love.graphics.getDimensions()
		love.graphics.setColor(0, 0, 0, self.overlay.opacity)
		love.graphics.rectangle("fill", 0, 0, w, h)
		return
	end

	if FLAGS.debug_mode then
		local font = load_font("assets/fonts/NotoSans-Bold.ttf", 18)
		local str = tostring(self.player.position)
		love.graphics.setFont(font)
		love.graphics.setColor(0, 0, 0, 220)
		love.graphics.print(str, anchor:right() - font:getWidth(str) + 2, anchor:top() + 2)
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.print(str, anchor:right() - font:getWidth(str), anchor:top())
	end

	local font = load_font("assets/fonts/NotoSans-Bold.ttf", 16)
	love.graphics.setFont(font)

	-- Full screen fade, we don't care about logical positioning for this.
	local w, h = love.graphics.getDimensions()
	love.graphics.setColor(0, 0, 0, self.overlay.opacity)
	love.graphics.rectangle("fill", 0, 0, w, h)

	if self.dead then
		love.audio.stop()
		self.world:clearEntities()
		love.graphics.setColor(50, 20, 20, 255)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
		love.graphics.setColor(255, 255, 255, 255)
		local font = load_font("assets/fonts/NotoSans-Bold.ttf", 30)
		local str = "WASTED"
		love.graphics.setFont(font)
		love.graphics.print(str, anchor:center_x() - font:getWidth(str) / 2, anchor:center_y() - 20)
		return
	end

	if not self.aggro then
		return
	end

	if self.aggro.hp <= 0 then
		self.aggro = false
		return
	end

	love.graphics.setColor(0, 0, 0, 220)
	love.graphics.push()

	local sections = self.aggro.max_hp / 5
	local width = 500
	local height = 35
	love.graphics.translate(anchor:center_x() - width / 2, anchor:top())
	love.graphics.shear(-0.2, 0)
	love.graphics.rectangle("fill", 0, 0, width, height)

	local a = cpml.vec3(230, 80, 100)
	local b = cpml.vec3(40, 90, 200)
	local f = cpml.vec3(50, 110, 200) -- flash color
	for i = 0, math.ceil(self.aggro.hp / 5)-1 do
		local c =  cpml.utils.lerp(math.pow(i / sections, 0.5), a, b)
		love.graphics.setColor(c.x, c.y, c.z, 255)
		love.graphics.rectangle("fill", i*(width/sections)+1, 1, width / sections - 2, height-2)
	end

	love.graphics.setFont(load_font("assets/fonts/NotoSans-Bold.ttf", 18))
	love.graphics.setColor(0, 0, 0, 180)
	love.graphics.print(sf("%s",  self.aggro.name), 4, 32)
	love.graphics.setColor(255, 255, 255, 220)
	love.graphics.print(sf("%s",  self.aggro.name), 6, 30)

	love.graphics.pop()
end

return gp
