local tiny  = require "tiny"
local cpml  = require "cpml"
local iqm   = require "iqm"
local anim9 = require "anim9"

return function()
	local sys  = tiny.processingSystem()
	sys.filter = tiny.requireAll("process")

	function sys:onAdd(entity)
		local t = love.timer.getTime()

		-- Load model
		if entity.model then
			if not self.world.cache.models[entity.model] then
				self.world.cache.models[entity.model] = {
					model = iqm.load(entity.model),
					count = 0,
					keep  = false
				}

				local model  = self.world.cache.models[entity.model].model
				local margin = cpml.vec3(0, 0, 0)

				if entity.bound_margin then
					margin.x = entity.bound_margin
					margin.y = entity.bound_margin
					margin.z = entity.bound_margin
				end

				for _, bound in pairs(model.bounds) do
					bound.min  = cpml.vec3(bound.min) - margin
					bound.max  = cpml.vec3(bound.max) + margin
					bound.mesh = self:calc_bounding_box(bound.min, bound.max)
				end

				for _, buffer in ipairs(model) do
					if buffer.material and not self.world.cache.materials[buffer.material] then
						if love.filesystem.isFile(
							string.format("assets/materials/%s.lua", buffer.material)
						) then
							local material = love.filesystem.load(
								string.format("assets/materials/%s.lua", buffer.material)
							)()

							self.world.cache.materials[buffer.material] = {
								color = {
									material.color[1] * 255,
									material.color[2] * 255,
									material.color[3] * 255,
									material.color[4] * 255
								},
								count = 0,
								keep  = false
							}
						end
					end
				end

				if model.has_anims then
					entity.animation = anim9(iqm.load_anims(entity.model))
					entity.animation:play("Dive")
				end
			end
		end

		if self.world.octree then
			local base      = self.world.cache.models[entity.model].model.bounds.base
			local scale_min = entity.scale * base.min
			local scale_max = entity.scale * base.max
			local half_size = (scale_max - scale_min) / 2

			local aabb = {}
			aabb.center = entity.position:clone()
			aabb.size   = half_size * 2
			aabb.min    = aabb.center + half_size * -1
			aabb.max    = aabb.center + half_size

			self.world.octree:add(entity, aabb)
		end

		-- Cycle in world
		entity.process = nil
		self.world:addEntity(entity)
	end

	function sys:calc_bounding_box(min, max)
		local vertices = {
			cpml.vec3(max.x, max.y, min.z),
			cpml.vec3(max.x, min.y, min.z),
			cpml.vec3(max.x, min.y, max.z),
			cpml.vec3(min.x, min.y, max.z),
			cpml.vec3(min),
			cpml.vec3(max),
			cpml.vec3(min.x, max.y, min.z),
			cpml.vec3(min.x, max.y, max.z),
		}

		return self:new_triangle_mesh {
			vertices[1], vertices[2], vertices[3],
			vertices[2], vertices[4], vertices[3],
			vertices[1], vertices[5], vertices[2],
			vertices[2], vertices[5], vertices[4],
			vertices[6], vertices[3], vertices[4],
			vertices[1], vertices[3], vertices[6],
			vertices[1], vertices[7], vertices[5],
			vertices[6], vertices[7], vertices[1],
			vertices[6], vertices[4], vertices[8],
			vertices[6], vertices[8], vertices[7],
			vertices[5], vertices[8], vertices[4],
			vertices[5], vertices[7], vertices[8],
		}
	end

	function sys:new_triangle_mesh(vertices)
		local triangles = {}
		local indices   = {}

		for i, vertex in ipairs(vertices) do
			local current = {}
			table.insert(current, vertex.x)
			table.insert(current, vertex.y)
			table.insert(current, vertex.z)
			table.insert(triangles, current)
			table.insert(indices, i)
		end

		local layout = {{ "VertexPosition", "float", 3 }}
		local mesh   = love.graphics.newMesh(layout, triangles, "triangles", "dynamic")
		mesh:setVertexMap(indices)

		return mesh
	end

	return sys
end
