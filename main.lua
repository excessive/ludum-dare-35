require "iqm"
require("fire").save_the_world()

Scene        = require "scene"
local tiny   = require "tiny"
local anchor = require "anchor"
local console = require "console"

-- timestep
local target_framerate = 60
local min_framerate    = 20

local timestep         = 1.0 / target_framerate
local max_delta        = timestep * 3.0

-- make sure we catch the first update
local lag = timestep
local peak = 0.0

-- gamestate
local gs = {
	previous = nil,
	current  = {
		tick = 0
	}
}

local show_overscan = false
local muted = false

if FLAGS.debug_mode then
	console.defineCommand(
		"current-screen",
		"(debug) current-screen screen is this?",
		function()
			local top = Scene.current()
			console.d("Current screen: %s", top.name or "<unknown>")
		end
	)
end

function love.load()
	-- Load global preferences
	PREFERENCES = {
		language = "en",
		volume   = 1.0
	}
	if love.filesystem.isFile("preferences.json") then
		local json = require "dkjson"
		local p = love.filesystem.read("preferences.json")
		local prefs = json.decode(p)
		if prefs and prefs.volume <= 0 then
			muted = true
		end
	end
	-- Set overscan
	anchor:set_overscan(0.1)

	love.audio.setVolume(PREFERENCES.volume)
	love.audio.setDistanceModel("inverseclamped")

	-- Create world
	local world         = tiny.world()
	world.timestep      = timestep
	world.language      = require("languages").load(PREFERENCES.language)
	world.inputs        = world:addSystem(require "inputs")
	world.particles     = world:addSystem(require "systems.particle")
	world.camera_system = world:addSystem(require "systems.camera")
	world.renderer      = world:addSystem(require "systems.render")

	local default_screen = FLAGS.debug_mode and "scenes.main-menu" or "scenes.splash"
	-- local default_screen = "scenes.splash"
	Scene.set_world(world)
	Scene.switch(require(initial_screen or default_screen))
	Scene.register_callbacks()

	love.resize(love.graphics.getDimensions())
end

local function interpolate(gs, alpha)
	local previous, current = gs.previous, gs.current
	assert(previous)
	assert(current)
end

function love.update(delta)
	local unstoppable_systems = tiny.requireAll("no_pause")
	local update_systems      = tiny.requireAll("update", tiny.rejectAny("no_pause"))
	-- local draw_systems        = tiny.requireAll("draw")

	local top    = Scene.current()
	local world  = assert(top.world)

	anchor:update()

	-- allow the game to slowmo if delta is too big.
	-- TODO: allow frame skipping to prevent desync instead.
	lag = lag + math.min(delta, max_delta)

	-- update game logic as lag permits
	while lag >= timestep do
		lag = lag - timestep

		-- Log if we missed an entire frame
		if lag > peak and lag > timestep then
			console.i("%d FRAME(S) SKIPPED (%fms)", lag/timestep, lag*1000)
		end
		peak = math.max(peak, lag)
		gs.previous = gs.current

		if not top.paused or not console.visible then
			gs.current.tick = gs.current.tick + 1

			-- update at a fixed rate each time
			world:update(timestep, update_systems)
		end
	end

	world:update(delta, unstoppable_systems)

	-- how far between frames is this?
	local alpha = lag / timestep
	local state = interpolate(gs, alpha)

	-- present what we've got.
	world.renderer:draw(state)

	-- Display overscan
	if show_overscan then
		love.graphics.setColor(180, 180, 180, 200)
		love.graphics.setLineStyle("rough")
		love.graphics.line(anchor:left(), anchor:center_y(), anchor:right(), anchor:center_y())
		love.graphics.line(anchor:center_x(), anchor:top(), anchor:center_x(), anchor:bottom())
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.rectangle("line", anchor:bounds())
	end

	-- Cycle language
	if world.inputs.sys.change_language:pressed() then
		world.language.cycle(world)
	end
end

function love.resize(w, h)
	local top = Scene.current()

	-- Resize UI or whatever else needs doing.
	if top.resize then top:resize(w, h) end

	-- Update canvases
	top.world.renderer:resize(w, h)
end

--[[

function love.load()
	-- Set overscan
	anchor:set_overscan(0.1)

	-- Create world
	local world = tiny.world()

	local notifications = world:addSystem(require("notifications"))
	function world.notify(msg, ding, icon)
		if ding then
			notifications.ding:stop()
			notifications.ding:play()
		end

		notifications:add(msg, icon)
	end

	world.language = require("languages").load(world, PREFERENCES.language)
	love.audio.setVolume(PREFERENCES.volume)

	--== Input System ==--
	world.inputs = world:addSystem(require "inputs")

	-- local default_screen = FLAGS.debug_mode and "scenes.main-menu" or "scenes.splash"
	local default_screen = "scenes.splash"
	Scene.set_world(world)
	Scene.switch(require(initial_screen or default_screen))
	Scene.register_callbacks()
end

function love.update(dt)
	anchor:update()

	-- Toggle overscan
	if FLAGS.debug_mode then
		if world.inputs.sys.show_overscan:pressed() then
			show_overscan = not show_overscan
		end
	end


	-- Toggle mute
	if world.inputs.sys.mute:pressed() then
		if love.audio.getVolume() < 0.01 then
			love.audio.setVolume(PREFERENCES.volume)
			muted = false
		else
			love.audio.setVolume(0)
			muted = true
		end
		world.notify(muted and "Muted" or "Unmuted", true)
	end

	-- Cycle language
	if world.inputs.sys.change_language:pressed() then
		world.language.cycle(world)
	end
end
--]]
