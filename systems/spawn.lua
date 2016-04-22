local tiny = require "tiny"
local cpml = require "cpml"

return tiny.processingSystem {
	filter = tiny.requireAll("spawn"),
	process = function(self, entity, dt)
		local c1 = {
			radius = entity.radius,
			position = cpml.vec3(entity.position.x, entity.position.y, 0)
		}
		local c2 = {
			radius = 0.05,
			position = cpml.vec3(self.world.player.position.x, self.world.player.position.y, 0)
		}
		local collision = cpml.intersect.circle_circle(c1, c2)

		if collision then
			conversation:say("spawn tiger", entity.position, entity.variant)
			self.world:removeEntity(entity)
		end

	end
}
