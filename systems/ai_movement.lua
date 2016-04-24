local cpml = require "cpml"
local tiny = require "tiny"

local function calc_target(self, entity)
	if not entity.path then
		return false
	end
	local step = entity.path[1]
	if not step then
		return false
	end
	local target = cpml.vec3(step)
	target = target * cpml.vec3(2.5, -2.5, 1)
	target = target + self.world.grid_offset * 2.5
	return target
end

local function orient(entity)
	local angle = entity.direction:angle_to()
	angle = angle + math.pi / 2
	entity.orientation = cpml.quat.rotate((angle % (math.pi * 2)), cpml.vec3.unit_z)
end

return tiny.processingSystem {
	filter = tiny.requireAll("dynamic", "path"),
	physics_system = true,
	process = function(self, entity, dt)
		if entity.knockback > 0 then
			entity.position.x = entity.position.x + entity.velocity.x
			entity.position.y = entity.position.y + entity.velocity.y
			entity.position.z = entity.position.z + entity.velocity.z
			return
		end

		local target = calc_target(self, entity)

		if not target then
			entity.arrived = true

			-- get direction towards player
			if (entity.stun and entity.stun <= 0) and entity.position:dist(self.world.player.position) < 2.5 then
				entity.direction = (self.world.player.position - entity.position):normalize()
				orient(entity)
			end

			return
		end

		if entity.position:dist(target) < 0.25 then
			table.remove(entity.path, 1)
			target = calc_target(self, entity)
			if not target then
				entity.arrived = true

				if entity.anim_cooldown == 0 then
					--entity.animation:reset()
					entity.animation:play("idle")
				end

				-- get direction towards player
				if entity.position:dist(self.world.player.position) < 2.5 then
					entity.direction = (self.world.player.position - entity.position):normalize()
					orient(entity)
				end

				return
			end
		end

		if entity.cooldown > 0 or (entity.stun and entity.stun > 0) then
			return
		end

		entity.animation:play("run")
		entity.arrived = false
		entity.move_to = target

		-- get direction towards next step
		entity.direction = (entity.move_to - entity.position):normalize()
		entity.velocity  = entity.direction * entity.speed * dt
		orient(entity)

		entity.position.x = entity.position.x + entity.velocity.x
		entity.position.y = entity.position.y + entity.velocity.y
		entity.position.z = entity.position.z + entity.velocity.z

		entity.velocity.x = 0
		entity.velocity.y = 0
		entity.velocity.z = 0
	end
}
