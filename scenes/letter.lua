local tiny    = require "tiny"
local lume    = require "lume"
local memoize = require "memoize"
local cpml    = require "cpml"
local anchor  = require "anchor"
local timer   = require "timer"
local convoke = require "convoke"

local gp = tiny.system {
	name    = "letter",
	timer   = timer.new(),
	delay   = 25, -- seconds before fade out
	overlay = {
		opacity = 255
	},
	next_scene = "scenes.play"
}

local load_sound = memoize(function(filename)
	return love.audio.newSource(filename)
end)

local load_font = memoize(function(filename, size)
	return love.graphics.newFont(filename, size)
end)

function gp:enter(from, ngp)
	self.ngp = ngp

	love.mouse.setVisible(false)

	if self.ngp then
		gp.world.language:set_locale("phpceo")
	end

	self.text, self.sfx = gp.world.language:get("play/grandpa_letter")
	self.sfx = load_sound(self.sfx)
	-- self.sfx:setRelative(true)

	-- Overlay fade
	convoke(function(continue, wait)
		-- Fade in
		self.timer.tween(1.5, self.overlay, {opacity=0}, 'cubic', continue())
		wait()
		-- Wait briefly
		self.timer.add(2, continue())
		wait()
		-- Wait a little bit
		self.timer.add(self.delay, continue())
		self.sfx:play()
		wait()
		-- Fade out
		self.timer.tween(1.25, self.overlay, {opacity=255}, 'out-cubic', continue())
		wait()
		-- Wait briefly
		self.timer.add(0.25, continue())
		wait()
		-- Switch
		Scene.switch(require(self.next_scene), self.ngp)
	end)()
end

function gp:update(dt)
	self.timer.update(dt)
end

function gp:draw()
	local font = load_font("assets/fonts/NotoSans-Bold.ttf", 20)
	love.graphics.setFont(font)

	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.printf(self.text, anchor:center_x() - 300, anchor:center_y() - 200, 600)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.printf(self.text, anchor:center_x() - 300, anchor:center_y() - 201, 600)

	-- Full screen fade, we don't care about logical positioning for this.
	local w, h = love.graphics.getDimensions()
	love.graphics.setColor(0, 0, 0, self.overlay.opacity)
	love.graphics.rectangle("fill", 0, 0, w, h)
end

return gp
