local tiny  = require "tiny"

return function()
	local keys = { "animations", "textures", "sounds" }
	local sys  = tiny.processingSystem()
	sys.filter = tiny.requireAny("model", "animations", "textures", "sounds")

	function sys:onAddToWorld(world)
		world.cache = {
			models         = {},
			materials      = {},
			textures       = {},
			animations     = {},
			level_entities = {},
			keymaps        = {}
		}
	end

	function sys:onRemoveFromWorld(world)
		world.cache = nil
	end

	function sys:onAdd(entity)
		if entity.model then
			local model = self.world.cache.models[entity.model]

			if model then
				model.count = model.count + 1

				for _, buffer in ipairs(model.model) do
					local material = self.world.cache.materials[buffer.material]

					if material then
						material.count = material.count + 1
					end
				end
			end
		end

		for _, k in ipairs(keys) do
			if entity[k] then
				for _, v in ipairs(entity[k]) do
					local ref = self.world.cache[k][v]
					if ref then
						ref.count = ref.count + 1
					end
				end
			end
		end
	end

	function sys:onRemove(entity)
		if entity.model then
			local model = self.world.cache.models[entity.model]

			if model then
				model.count = model.count - 1

				if model.count <= 0 and not model.keep then
					self.world.cache.models[entity.model] = nil
				end

				for _, buffer in ipairs(model.model) do
					local material = self.world.cache.materials[buffer.material]

					if material then
						material.count = material.count - 1

						if material.count <= 0 and not material.keep then
							self.world.cache.materials[buffer.material] = nil
						end
					end
				end
			end
		end

		if entity.animations then
			for _, animation in ipairs(entity.animations) do
				local animation = self.world.cache.animations[animation]

				if animation then
					animation.count = animation.count - 1

					if animation.count <= 0 and not animation.keep then
						self.world.cache.animations[entity.animations] = nil
					end
				end
			end
		end

		if entity.textures then
			for _, texture in ipairs(entity.textures) do
				local texture = self.world.cache.textures[texture]

				if texture then
					texture.count = texture.count - 1

					if texture.count <= 0 and not texture.keep then
						self.world.cache.textures[entity.textures] = nil
					end
				end
			end
		end

		if entity.sounds then
			for _, sound in ipairs(entity.sounds) do
				local sound = self.world.cache.sounds[sound]

				if sound then
					sound.count = sound.count - 1

					if sound.count <= 0 and not sound.keep then
						self.world.cache.sounds[entity.sounds] = nil
					end
				end
			end
		end
	end

	return sys
end
