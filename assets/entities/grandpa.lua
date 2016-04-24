local cpml = require "cpml"
local load = require "load_files"

return function(world)
	entity = {
		name          = "Grandpa",
		visible       = true,
		rigid_body    = true,
		dynamic       = true,
		radius        = 0.25,
		speed         = 3,
		orientation   = cpml.quat(0, 0, 0, 1),
		scale         = cpml.vec3(1, 1, 1),
		position      = cpml.vec3(-15, -26, 0),
		velocity      = cpml.vec3(0, 0, 0),
		force         = cpml.vec3(0, 0, 0),
		color         = { 0.75, 0.75, 0.75 },
		mesh          = load.model("assets/models/grandpa.iqm", false),
		animation     = load.anims("assets/models/grandpa.iqm"),
		textures      = {
			body = "assets/textures/grandpa_diffuse_body.png",
			head = "assets/textures/grandpa_diffuse_head.png"
		}
	}

	entity.direction = entity.orientation * -cpml.vec3.unit_y
	entity.animation:play("idle")

	return entity
end
