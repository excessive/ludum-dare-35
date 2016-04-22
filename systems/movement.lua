local cpml = require "cpml"
local tiny = require "tiny"

return tiny.processingSystem {
	filter = tiny.requireAll("possessed", "dynamic", "position", "velocity"),
	physics_system = true,
	process = function(self, entity, dt)
		entity.position.x = entity.position.x + entity.velocity.x
		entity.position.y = entity.position.y + entity.velocity.y
		entity.position.z = entity.position.z + entity.velocity.z

		entity.grid.x = entity.position.x / 2.5 - self.world.grid_offset.x
		entity.grid.y = entity.position.y / 2.5 - self.world.grid_offset.y
		entity.grid.z = entity.position.z / 2.5 - self.world.grid_offset.z

		entity.velocity.x = 0
		entity.velocity.y = 0
		entity.velocity.z = 0
	end
}
