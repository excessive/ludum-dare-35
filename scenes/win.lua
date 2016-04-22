local tiny       = require "tiny"
local lume       = require "lume"
local memoize    = require "memoize"
local cpml       = require "cpml"
local iqm        = require "iqm"
local anim9      = require "anim9"
local map_loader = require "map"
local anchor     = require "anchor"
local timer      = require "timer"
local convoke    = require "convoke"

conversation = require("talkback").new()

local gp = tiny.system {
	name = "win",
	next_scene = "scenes.credits",
	timer   = timer.new(),
	overlay = {
		opacity = 255
	},
	delay1 = 12,
	delay2 = 10,
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

local tiger = { "Pet", "atk", { atk=0,  def=0, spd=0 }, 9999, 0.35 }

function gp:enter(from, ngp)
	self.subtitle  = {
		text    = "",
		opacity = 0,
		font    = love.graphics.newFont("assets/fonts/NotoSans-Regular.ttf", 18)
	}

	self.ngp = ngp
	love.filesystem.write("ngp", "")

	self.text1, self.sfx1 = gp.world.language:get("play/grandpa_came")
	self.sfx1 = load_sound(self.sfx1)
	self.sfx1:setRelative(true)

	self.text2, self.sfx2 = gp.world.language:get("play/grandpa_gift")
	self.sfx2 = load_sound(self.sfx2)
	self.sfx2:setRelative(true)

	self.time = 0
	love.graphics.setBackgroundColor(115, 145, 105)
	-- love.graphics.setBackgroundColor(100, 10, 10)

	local map, grid_offset = map_loader.load(self.world, "assets/levels/level.lua")


	self.camera = self.world:addEntity {
		name        = "Camera",
		camera      = true,
		fov         = 60,
		near        = 0.0001,
		far         = 100,
		exposure    = 1.025,
		position    = cpml.vec3(0, 0, 0),
		orientation = cpml.quat(0, 0, 0, 1) * cpml.quat.rotate(math.pi, cpml.vec3.unit_z),
		offset      = cpml.vec3(-1, -0.5, 5)
	}
	self.camera.orientation = self.camera.orientation * cpml.quat.rotate(math.pi/15, cpml.vec3.unit_x)
	self.camera.direction   = self.camera.orientation * -cpml.vec3.unit_y

	self.player = self.world:addEntity(entities.player(self.world, self.ngp))
	self.player.position = cpml.vec3(0, 20, 0)
	self.player.orientation = self.player.orientation * cpml.quat.rotate(math.pi/2, cpml.vec3.unit_z)
	self.player.animation:play("idle")

	self.grandpa = self.world:addEntity(entities.grandpa(self.world))
	self.grandpa.position = cpml.vec3(2, 20, 0)
	self.grandpa.orientation = self.grandpa.orientation * cpml.quat.rotate(math.pi/2, -cpml.vec3.unit_z)

	local light = self.world:addEntity {
		name        = "Sol",
		light       = true,
		direction   = cpml.vec3(0.2, 0.1, 0.7):normalize(),
		color       = { 1.6, 1.10, 1.10 },
		position    = cpml.vec3(3, -2.1, 0),
		intensity   = 10,
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

	self.animation = self.world:addSystem(require "systems.animation")
	self.audio     = self.world:addSystem(require "systems.audio")

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

	-- Overlay fade
	convoke(function(continue, wait)
		-- Fade in
		self.timer.tween(1.5, self.overlay, {opacity=0}, 'cubic', continue())
		wait()
		-- Wait briefly
		self.timer.add(2, continue())
		wait()
		-- Wait a little bit
		self.timer.add(self.delay1, continue())
		self.sfx1:play()
		self:draw_text(self.text1, 11)
		wait()

		self.timer.add(self.delay2, continue())
		self.sfx2:play()
		self:draw_text(self.text2, 13)

		self.gift = self.world:addEntity({
			name          = "Gift",
			visible       = true,
			orientation   = cpml.quat(0, 0, 0, 1),
			scale         = cpml.vec3(0.5, 0.5, 0.5),
			position      = cpml.vec3(1, 20, 1),
			color         = { 0.5, 0.75, 0.25 },
			mesh          = load_model("assets/models/cube.iqm", false)
		})
		wait()
		-- Fade out
		self.timer.tween(1.25, self.overlay, {opacity=255}, 'out-cubic', continue())
		wait()
		-- Wait briefly
		self.timer.add(0.25, continue())
		wait()
		-- Switch
		Scene.switch(require(self.next_scene))
	end)()
end

function gp:update(dt)
	self.time = self.time + dt
	self.timer.update(dt)
end

function gp:draw()
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

	-- Full screen fade, we don't care about logical positioning for this.
	local w, h = love.graphics.getDimensions()
	love.graphics.setColor(0, 0, 0, self.overlay.opacity)
	love.graphics.rectangle("fill", 0, 0, w, h)
end

return gp
