local cpml = require "cpml"
local tiny = require "tiny"
local memoize = require "memoize"

local load_sound = memoize(function(filename)
	return love.audio.newSource(filename)
end)

return tiny.processingSystem {
	filter = tiny.requireAll("cooldown", "anim_cooldown", "hp"),
	process = function(self, entity, dt)
		-- If cooldown is active, perform hit
		if entity.cooldown == entity.max_cooldown and not entity.dodging and not entity.blocking then
			for k, e in pairs(self.entities) do
				if entity ~= e then
					-- determine if object is within a cone in front of you
					local dir = (e.position - entity.position):normalize()

					-- Check to see if you are within attack distance
					local c1 = {
						radius   = entity.radius + entity.weapon_radius,
						position = cpml.vec3(entity.position.x, entity.position.y, 0)
					}
					local c2 = {
						radius   = e.radius,
						position = cpml.vec3(e.position.x, e.position.y, 0)
					}
					local proximity = cpml.intersect.circle_circle(c1, c2)
					local facing    = entity.direction:dot(dir) >= 1.0 - (entity.weapon_size or 0.5)

					entity.regen_cooldown = 0
					if proximity and facing then
						-- Get enemy direction
						local edir = (entity.position - e.position):normalize()
						local efacing = e.direction:dot(edir) >= 1.0 - (e.weapon_size or 0.5)

						-- Fully mitigate attacks while shield is up or dodging
						if e.blocking and efacing or e.dodging then
						else
							-- Change stats
							if entity.enemy then
								conversation:say("hit", entity)
							else
								conversation:say("top_up_aggro", e)
							end

							entity.regen_cooldown = 0
							e.regen_cooldown = 0

							-- Reduce enemy hp
							local delta = (10 + entity.stats.atk - e.stats.def) + love.math.random(85, 115) / 100
							if delta < 1 then delta = 1 end

							e.hp = e.hp - delta

							if e.hp <= 0 then
								e.hp = 0

								if e.possessed then
									conversation:say("player died")
								else
									conversation:say("killed enemy", e)
								end
							elseif e.possessed then
								conversation:say("take damage")
							end
						end
					end
				end
			end
		end

		-- Reduce cooldown
		entity.cooldown = entity.cooldown - dt

		-- Don't let cooldown fall below 0
		if entity.cooldown < 0 then
			entity.cooldown = 0
		end

		if entity.anim_cooldown > 0 then
			-- stop movement
			entity.velocity.x = 0
			entity.velocity.y = 0
			entity.velocity.z = 0
		end

		-- Reduce cooldown
		entity.anim_cooldown = entity.anim_cooldown - dt

		-- Don't let cooldown fall below 0
		if entity.anim_cooldown < 0 then
			entity.anim_cooldown = 0
		end
	end,
	knockback = function(self)
		local player = self.world.player

		for _, enemy in ipairs(self.entities) do
			if enemy ~= player then
				-- determine if object is within a cone in front of you
				local dir = (enemy.position - player.position):normalize()

				-- Check to see if you are within attack distance
				local c1 = {
					radius   = player.radius + player.weapon_radius,
					position = cpml.vec3(player.position.x, player.position.y, 0)
				}
				local c2 = {
					radius   = enemy.radius,
					position = cpml.vec3(enemy.position.x, enemy.position.y, 0)
				}
				local proximity = cpml.intersect.circle_circle(c1, c2)
				local facing    = player.direction:dot(dir) >= 1.0 - (player.weapon_size or 0.5)

				if proximity and facing then
					enemy.animation:reset()
					enemy.animation:play("knockback")
					enemy.knockback = 2/3 -- seconds
					enemy.velocity = player.direction * 2 * love.timer.getDelta()

					local text, sfx = self.world.language:get("play/player_leaf")
					sfx = load_sound(sfx)
					sfx:play()
					conversation:say("draw_text", text, 2)
				end
			end
		end
	end
}
