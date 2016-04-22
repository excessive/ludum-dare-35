local tiny = require "tiny"
local cpml = require "cpml"
local console = require "console"

local noclip = false

if FLAGS.debug_mode then
	console.defineCommand(
		"noclip",
		"Disable collisions",
		function(args)
			noclip = not noclip
			console.d("noclip: %s", tostring(noclip))
		end
	)
end

return tiny.processingSystem {
	filter = tiny.requireAll("rigid_body", "position"),
	process = function(self, entity, dt)
		-- HULK SMASH
		for k, e in ipairs(self.entities) do
			if entity.possessed and entity ~= e then
				--[[
				local aabb = {
					position = entity.position,
					extent   = entity.scale / 2
				}
				local obb  = {
					position = e.position,
					extent   = e.scale / 2,
					rotation = cpml.mat4():rotate(e.orientation)
				}
				local collision = cpml.intersect.aabb_obb(aabb, obb)
				--]]

				local c1 = {
					radius = entity.radius,
					position = cpml.vec3(entity.position.x, entity.position.y, 0)
				}
				local c2 = {
					radius = e.radius,
					position = cpml.vec3(e.position.x, e.position.y, 0)
				}
				local collision = cpml.intersect.circle_circle(c1, c2)

				-- TODO: knockback, i-frames

				if collision and not noclip then
					-- <MattRB_> when a collision is detected apply a force with the
					-- strength of the dot product between the object's relative
					-- velocities and direction of contact.
					local direction = (c1.position - c2.position):normalize()
					local power     = entity.velocity:dot(direction)
					local reject    = direction * -power
					entity.velocity = entity.velocity + reject
					entity.force    = reject
					entity.position = c2.position + direction * (c1.radius + c2.radius)
				else
					entity.force = entity.direction * entity.speed
				end
			end
		end
	end
}
