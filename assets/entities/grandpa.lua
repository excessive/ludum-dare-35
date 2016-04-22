local cpml    = require "cpml"
local iqm     = require "iqm"
local anim9   = require "anim9"
local memoize = require "memoize"

local load_model = memoize(function(path, actor)
	return iqm.load(path, actor)
end)

local load_anims = memoize(function(path)
	return iqm.load_anims(path)
end)

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
		mesh          = load_model("assets/models/grandpa.iqm", false),
		animation     = anim9(load_anims("assets/models/grandpa.iqm")),
		textures      = {
			body = "assets/textures/grandpa_diffuse_body.png",
			head = "assets/textures/grandpa_diffuse_head.png"
		}
	}

	entity.direction = entity.orientation * -cpml.vec3.unit_y
	entity.animation:play("idle")

	return entity
end
