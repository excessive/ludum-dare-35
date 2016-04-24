local cpml  = require "cpml"
local tiny  = require "tiny"
local load  = require "load_files"
local timer = require "timer"

local stun_timer = timer.new()

local function check_collision(e1, e2)
	return cpml.intersect.circle_circle({
		radius   = e1.radius + e1.weapon_radius,
		position = cpml.vec3(e1.position.x, e1.position.y, 0)
	}, {
		radius   = e2.radius,
		position = cpml.vec3(e2.position.x, e2.position.y, 0)
	})
end

local function get_dmg_delta(attacker, defender)
	local delta = (10 + attacker.stats.atk - defender.stats.def) + love.math.random(85, 115) / 100
	if delta < 1 then delta = 1 end
	return delta
end

conversation:listen("attack enemy", function(player, enemy)
	conversation:say("top_up_aggro", enemy)

	-- Reduce enemy hp
	enemy.hp = enemy.hp - get_dmg_delta(player, enemy)

	-- TODO: hits aren't instant, this should happen after a small delay.
	enemy.stun = 0.4
	enemy.animation:play("idle")
	conversation:say("hit enemy")

	if enemy.hp <= 0 then
		enemy.hp = 0
		conversation:say("killed enemy", enemy)
	end
end)

conversation:listen("attack player", function(player, enemy)
	local dir    = (enemy.position - player.position):normalize()
	local facing = player.direction:dot(dir) >= 1.0 - (player.weapon_size or 0.5)

	-- Fully mitigate attacks while shield is up or dodging
	if not (player.blocking and facing) and not player.dodging then
		conversation:say("hit", enemy)

		-- Reduce player hp
		player.hp = player.hp - get_dmg_delta(enemy, player)

		if player.hp <= 0 then
			player.hp = 0
			conversation:say("player died")
		else
			conversation:say("take damage")
		end
	end
end)

return tiny.processingSystem {
	filter = tiny.requireAll("attacking"),
	process = function(self, entity, dt)
		-- don't try to attack if we're stunned, dodging, etc.
		if entity.stun or entity.dodging or entity.blocking then
			return
		end
		if entity.attacking then
			entity.attacking = false
			for k, e in ipairs(self.entities) do
				if entity ~= e then
					-- Check to see if you are within attack distance
					local proximity = check_collision(entity, e)

					-- determine if object is within a cone in front of you
					local dir    = (e.position - entity.position):normalize()
					local facing = entity.direction:dot(dir) >= 1.0 - (entity.weapon_size or 0.5)

					entity.regen_cooldown = 7

					if proximity and facing then
						if entity.possessed then
							conversation:say("attack enemy", entity, e)
						else
							conversation:say("attack player", e, entity)
						end

						entity.regen_cooldown = 7
						e.regen_cooldown      = 7
					end
				end
			end
		end

		if entity.anim_cooldown > 0 then
			-- stop movement
			entity.velocity.x = 0
			entity.velocity.y = 0
			entity.velocity.z = 0
		end
	end,
	knockback = function(self)
		local player = self.world.player

		for _, enemy in ipairs(self.entities) do
			if enemy ~= player then
				-- Check to see if you are within attack distance
				local proximity = check_collision(player, enemy)

				-- determine if object is within a cone in front of you
				local dir    = (enemy.position - player.position):normalize()
				local facing = player.direction:dot(dir) >= 1.0 - (player.weapon_size or 0.5)

				if proximity and facing then
					enemy.animation:reset()
					enemy.animation:play("knockback")
					enemy.knockback = 2/3 -- seconds
					-- DO NOT USE LOVE.TIMER.GETDELTA YOU STUPID MOTHERFUCKER
					-- WE USE A FIXED TIMESTEP
					enemy.velocity = player.direction * 2 * self.world.timestep

					local text, sfx = self.world.language:get("play/player_leaf")
					sfx = load.sound(sfx)
					sfx:play()
					conversation:say("draw_text", text, 2)
				end
			end
		end
	end
}
