local cpml       = require "cpml"
local tiny       = require "tiny"
local lume       = require "lume"
local iqm        = require "iqm"
local memoize    = require "memoize"
local Pathfinder = require "jumper.pathfinder"

local load_model = memoize(function(path, actor)
	return iqm.load(path, actor)
end)

local function to_grid(world, position)
	local pos = cpml.vec3(position)
	pos = pos - world.grid_offset * 2.5
	pos = pos / cpml.vec3(2.5, -2.5, 1)
	return cpml.vec3(
		cpml.utils.round(pos.x),
		cpml.utils.round(pos.y),
		0
	)
end

local function to_world(world, position)
	local pos = cpml.vec3(position)
	pos = pos * cpml.vec3(2.5, -2.5, 1)
	pos = pos + world.grid_offset * 2.5
	return pos
end

local function drop_nodes(world, path)
	local nodes = {}
	if not path then
		return nodes
	end
	for i, node in ipairs(path) do
		local pos = to_world(world, cpml.vec3(node))

		table.insert(nodes, world:addEntity {
			name = "node" .. i,
			visible = true,
			position = pos,
			mesh = load_model("assets/models/cube.iqm", false)
		})
	end
	return nodes
end

conversation:listen("top_up_aggro", function(entity)
	entity.aggro = 10
end)

return tiny.processingSystem {
	filter = tiny.requireAll("enemy"),
	nodes  = {},
	sfx = {
		rawr1  = love.audio.newSource("assets/sfx/tiger_rawr.wav"),
		rawr2  = love.audio.newSource("assets/sfx/tiger_graw.wav"),
		attack = love.audio.newSource("assets/sfx/crunch.wav"),
		dead   = love.audio.newSource("assets/sfx/tiger_mrow.wav"),
	},
	onAddToWorld = function(self, world)
		assert(self.world.nav_grid, "load the map first pls")
		self.finder = Pathfinder(self.world.nav_grid, 'ASTAR', 0)
	end,

	onAdd = function(self, entity)
		self.nodes[entity] = {}
	end,

	process = function(self, entity, dt)
		-- Count down to resetting aggro
		if entity.aggro then
			entity.aggro = entity.aggro - dt
			if entity.aggro < 0 then
				entity.aggro = 0
			end
		end

		-- if we're on the way somewhere, don't update the path.
		if entity.arrived and self.nodes[entity] then
			for i, v in lume.ripairs(self.nodes[entity]) do
				self.world:removeEntity(table.remove(self.nodes[entity], i))
			end
		end

		-- we don't path find for the player or enemies in transit
		if entity == self.world.player or (entity.arrived ~= nil and not entity.arrived) then
			return
		end

		local start  = to_grid(self.world, entity.position)
		local finish = to_grid(self.world, self.world.player.position)

		-- attack!
		local distance = entity.position:dist(self.world.player.position)
		if distance <= 1.5 and entity.cooldown == 0 then
			-- Perform animation
			entity.animation:reset()
			entity.animation:play("attack")

			-- Play sounds
			self.sfx.attack:setPosition((entity.position / 10):unpack())
			self.sfx.attack:play()

			-- Set cooldowns
			entity.cooldown      = entity.max_cooldown
			entity.anim_cooldown = entity.animation:length()
		end

		local queue = false
		if not entity.path then
			queue = true
		end

		entity.path = self.finder:getPath(start.x, start.y, finish.x, finish.y)

		-- Invalid path or path too long or aggroed for too long/far, do not aggro
		if (not entity.path and (not entity.aggro or entity.aggro == 0)) or
			(entity.path and #entity.path > 3 and (not entity.aggro or entity.aggro == 0)) or
			(entity.aggro_position and entity.position:dist(entity.aggro_position) > 15 and entity.aggro == 0) then
			entity.aggro = false
			entity.hp    = entity.max_hp
			finish       = to_grid(self.world, entity.aggro_position)
			entity.path  = self.finder:getPath(start.x, start.y, finish.x, finish.y)
			entity.aggro_position = false
			conversation:say("aggro reset", entity)
		-- Initial aggro
		elseif not entity.aggro then
			entity.aggro = 10
			entity.aggro_position = entity.position:clone()

			local r = love.math.random(2)
			self.sfx["rawr" .. r]:stop()
			self.sfx["rawr" .. r]:setPosition((entity.position / 10):unpack())
			self.sfx["rawr" .. r]:play()

			conversation:say("aggro", entity)
		end

		-- self.nodes[entity] = drop_nodes(self.world, entity.path)
		if queue then
			self.world:addEntity(entity)
		end

		if entity.path then
			entity.arrived = false
		end
	end
}
