local cpml    = require "cpml"
local iqm     = require "iqm"
local memoize = require "memoize"
local lume    = require "lume"

local load_model = memoize(function(path, actor)
	return iqm.load(path, actor)
end)

local function load(world, path)
	local chunk = love.filesystem.load(path)
	local ok, map = pcall(chunk)
	if not ok then
		console.e("Unable to load map: %s", map)
		return false
	end

	local trees = {}

	world.level_entities = {}
	for _, data in ipairs(map.objects) do
		local entity = {}
		for k, v in pairs(data) do
			entity[k] = v
		end
		if entity.path then
			assert(
				love.filesystem.isFile(entity.path),
				string.format("%s doesn't exist!", entity.path)
			)
			entity.mesh = assert(load_model(entity.path, entity.actor))
		end

		entity.position	 = cpml.vec3(entity.position)
		entity.orientation = cpml.quat(entity.orientation)
		entity.scale       = cpml.vec3(entity.scale)
		entity.velocity    = cpml.vec3(0, 0, 0)
		entity.force       = cpml.vec3(0, 0, 0)
		entity.direction   = entity.orientation * cpml.vec3.unit_y
		world.level_entities[entity.name] = entity
		world:addEntity(entity)

		if entity.name:find("Tree") then
			table.insert(trees, entity.position / 2.5)
		end
	end

	table.sort(trees, function(a, b)
		return a.y < b.y
	end)

	local tmp_grid = {}
	local basis = false
	for i, tree in ipairs(trees) do
		local x = math.floor(tree.x)
		local y = math.floor(tree.y)
		if not basis then
			basis = y
		end
		local idx = y - basis + 1
		tmp_grid[idx] = tmp_grid[idx] or {}
		table.insert(tmp_grid[idx], x)
	end

	local grid = {}
	local max = 0
	for i, row in ipairs(tmp_grid) do
		grid[i] = {}
		max = math.max(max, #row)
	end

	local offset = cpml.vec2(0, -basis + 1)

	for i, row in ipairs(tmp_grid) do
		table.sort(row, function(a, b)
			return a < b
		end)
		local basis = math.min(offset.x, row[1])
		offset.x = basis
		for j, x in ipairs(row) do
			local idx = x - basis + 1
			grid[i][idx] = 1
		end
		for j = 1, max do
			grid[i][j] = grid[i][j] or 0
		end
	end

	offset.x = offset.x - 1

	-- Reverse the row order because i r a dumb
	local final_grid = {}
	for i, row in lume.ripairs(grid) do
		table.insert(final_grid, row)
	end

	-- for i, row in ipairs(final_grid) do
	-- 	local fmt = string.rep("%f ", #row)
	-- 	print(table.concat(row, " "))
	-- end

	-- print(offset)

	return final_grid, offset
end

return {
	load = load
}
