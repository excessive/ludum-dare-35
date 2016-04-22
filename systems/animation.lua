local tiny = require "tiny"

return tiny.processingSystem {
	filter = tiny.requireAll("animation"),
	process = function(self, entity, dt)
		if entity.animation then
			entity.animation:update(dt)
		end
	end
}
