local cpml = require "cpml"
local load = require "load_files"

return function(world, name, position, variant)
	local entity = {
		name        = name or "Spawn",
		spawn       = true,
		--visible     = true,
		variant     = variant,
		radius      = 2.5,
		position    = position or cpml.vec3(),
		orientation = cpml.quat(0, 0, 0, 1),
		scale       = cpml.vec3(1, 1, 1),
		color       = { 0.5, 0.5, 0.5 },
		mesh        = load.model("assets/models/cube.iqm", false)
	}

	return entity
end
