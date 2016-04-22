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

return function(world, ngp)
	entity = {
		name          = "Player",
		possessed     = true,
		visible       = true,
		rigid_body    = true,
		dynamic       = true,
		radius        = 0.25,
		weapon_radius = 1,
		weapon_size   = 0.5,
		hp            = 100,
		max_hp        = 100,
		cooldown      = 0,
		max_cooldown  = 0.75,
		anim_cooldown = 0,
		speed         = 3,
		orientation   = cpml.quat(0, 0, 0, 1),
		scale         = cpml.vec3(1, 1, 1),
		position      = cpml.vec3(-15, -26, 0),
		velocity      = cpml.vec3(0, 0, 0),
		force         = cpml.vec3(0, 0, 0),
		color         = { 0.75, 0.75, 0.75 },
		mesh          = load_model(ngp and "assets/models/ngp.iqm" or "assets/models/mc.iqm", false),
		animation     = anim9(load_anims("assets/models/mc.iqm")),
		stat          = "atk",
		stats         = { atk=10, def=-10, spd=-10 },
		textures      = {
			body = "assets/textures/mc_diffuse_body.png",
			["body.ngp"] = "assets/textures/mc_diffuse_body_ngp.png",
			head = "assets/textures/mc_diffuse_head.png"
		}
	}

	entity.direction = entity.orientation * -cpml.vec3.unit_y
	entity.animation:play(entity.stat .. "_idle")

	if world.grid_offset then
		entity.grid = entity.position / 2.5 + world.grid_offset
	end

	return entity
end
