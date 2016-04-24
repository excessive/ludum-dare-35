local cpml = require "cpml"
local tiny = require "tiny"

return tiny.processingSystem {
	cooldowns = {
		"cooldown",
		"anim_cooldown",
		"regen_cooldown",
		"knockback",
		"aggro",
		"stun"
	},
	filter = tiny.requireAny(
		"cooldown",
		"anim_cooldown",
		"regen_cooldown",
		"knockback",
		"aggro",
		"stun"
	),
	process = function(self, entity, dt)
		for _, cooldown in ipairs(self.cooldowns) do
			if entity[cooldown] and
				type(entity[cooldown]) == "number" and
				entity[cooldown] > 0 then
				entity[cooldown] = math.max(entity[cooldown] - dt, 0)
			end
		end
	end
}
