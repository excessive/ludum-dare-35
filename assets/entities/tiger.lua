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

return function(world, position, name, stat, stats, hp, scale, orientation, color, roughness)
	local entity = {
		name           = name or "Tiger",
		visible        = true,
		dynamic        = true,
		enemy          = true,
		aggro          = false,
		aggro_position = false,
		hp             = hp or 100,
		max_hp         = hp or 100,
		cooldown       = 0,
		max_cooldown   = 1.75,
		anim_cooldown  = 0,
		knockback      = 0,
		orientation    = orientation or cpml.quat(0, 0, 0, 1),
		scale          = cpml.vec3(scale or 1, scale or 1, scale or 1),
		position       = position or cpml.vec3(),
		velocity       = cpml.vec3(0, 0, 0),
		force          = cpml.vec3(0, 0, 0),
		color          = color,
		roughness      = roughness,
		primary_stat   = stat or "atk",
		stats          = stats or { atk=3, def=3, spd=3 },
		mesh           = load_model("assets/models/tiger.iqm", false),
		animation      = anim9(load_anims("assets/models/tiger.iqm")),
		textures       = {
			body = "assets/textures/tiger_diffuse.png"
		},
	}

	entity.speed         = 3 + stats.spd / 10
	entity.radius        = 1.6 * (scale or 1)
	entity.weapon_radius = 1.6 * (scale or 1)
	entity.direction     = entity.orientation * -cpml.vec3.unit_y
	entity.animation:play("idle")

	if world.grid_offset then
		entity.grid = entity.position / 2.5 + world.grid_offset
	end

	return entity
end
