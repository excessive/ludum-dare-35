local anchor  = require "anchor"
local convoke = require "convoke"
local timer   = require "timer"
local tiny    = require "tiny"

local splash = tiny.system {
	name = "splash",
	logos = {
		l3d   = love.graphics.newImage("assets/images/logo-love3d.png"),
		exmoe = love.graphics.newImage("assets/images/logo-exmoe.png")
	},
	timer   = timer.new(),
	delay   = 5.5, -- seconds before fade out
	overlay = {
		opacity = 255
	},
	bgm = {
		volume = 0.5,
		music  = love.audio.newSource("assets/bgm/love.ogg")
	},
	next_scene = "scenes.main-menu"
}

function splash:enter()
	love.graphics.setBackgroundColor(30, 30, 44)
	self.bgm.music:play()
	love.mouse.setVisible(false)

	-- BGM
	convoke(function(continue, wait)
		self.bgm.music:setVolume(self.bgm.volume)
		self.bgm.music:play()
		self.timer.add(self.delay, continue())
		wait()
		self.timer.tween(1.5, self.bgm, {volume = 0}, 'in-quad', continue())
		wait()
		self.bgm.music:stop()
	end)()

	-- Overlay fade
	convoke(function(continue, wait)
		-- Fade in
		self.timer.tween(1.5, self.overlay, {opacity=0}, 'cubic', continue())
		wait()
		-- Wait a little bit
		self.timer.add(self.delay, continue())
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

function splash:leave(self)
	love.mouse.setVisible(true)
end

function splash:update(dt)
	self.timer.update(dt)
	self.bgm.music:setVolume(self.bgm.volume)

	-- Skip if user wants to get the hell out of here.
	if self.world.inputs.game.action:pressed() then
		self.bgm.music:stop()
		Scene.switch(require(self.next_scene))
	end
end

function splash:draw()
	local cx, cy = anchor:center()

	local lw, lh = self.logos.exmoe:getDimensions()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(self.logos.exmoe, cx-lw/2, cy-lh/2 - 84)

	local lw, lh = self.logos.l3d:getDimensions()
	love.graphics.draw(self.logos.l3d, cx-lw/2, cy-lh/2 + 64)

	-- Full screen fade, we don't care about logical positioning for this.
	local w, h = love.graphics.getDimensions()
	love.graphics.setColor(0, 0, 0, self.overlay.opacity)
	love.graphics.rectangle("fill", 0, 0, w, h)
end

return splash
