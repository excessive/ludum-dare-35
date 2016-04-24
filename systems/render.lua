local tiny = require "tiny"
local cpml = require "cpml"
local load = require "load_files"
local l3d  = love.graphics.getLove3D()

local renderer = tiny.system {
	filter = tiny.requireAny(
		tiny.requireAll("mesh", "position"),
		tiny.requireAll("light", "direction")
	),
	-- view_range = false,
	view_range = 14,
	view_offset = 4,
	msaa = 4,
	octree_debug = false,
	shaders = {
		default  = love.graphics.newShader("assets/shaders/shaded.glsl"),
		post     = love.graphics.newShader("assets/shaders/post.glsl"),
		sky      = love.graphics.newShader("assets/shaders/sky.glsl"),
		particle = love.graphics.newShader("assets/shaders/particle.glsl"),
		shadow   = l3d.new_shader_raw("2.1", "assets/shaders/shadow.glsl")
	},

	shadow_map = l3d.new_shadow_map(2048, 2048),
	default_orientation = cpml.quat(0, 0, 0, 1),
	default_scale = cpml.vec3(1, 1, 1),
	lights = {
		ambient = { 0.02, 0.04, 0.04 },
		-- ambient = { 0, 0, 0 },
		default = {
			direction = cpml.vec3(0.3, 0.0, 0.7),
			color     = { 1, 1, 1 },
			specular  = { 1, 1, 1 }
		}
	},
	sky = false,
	particle_systems = {},
	objects = {},
	grass = {}
}

function renderer:resize(w, h)
	local limits  = love.graphics.getSystemLimits()
	local formats = love.graphics.getCanvasFormats()
	local msaa    = limits.canvasmsaa >= self.msaa and self.msaa or false
	local fmt     = "normal"
	if formats.rg11b10f then
		fmt = "rg11b10f"
		self.use_hdr = true
	end
	-- canvas support in general is guaranteed in 0.10.0+, so we just need to
	-- make sure to get the right number of msaa samples.
	self.canvas = love.graphics.newCanvas(w, h, fmt, msaa, true)
end

function renderer:draw_overlay()
	local anchor = require "anchor"
	local str = string.format(
		"FPS: %0.2f (%0.4f)",
		love.timer.getFPS(),
		love.timer.getAverageDelta()
	)
	local width = love.graphics.getFont():getWidth(str)

	if Scene.current().draw then
		Scene.current():draw()
	end

	love.graphics.setColor(255, 255, 255, 255)
	-- love.graphics.print(str, anchor:right() - width, anchor:top())
end



function renderer:onAdd(entity)
	if entity.light then
		table.insert(self.lights, entity)
		return
	end
	if entity.sky then
		self.sky = entity
		return
	end
	if entity.possessed then
		self.player = entity
	end
	if entity.textures then
		local flags = {
			mipmaps = true
		}
		for _, v in pairs(entity.textures) do
			load.texture(v) -- pre-load all the textures
		end
	end
	if entity.particles then
		table.insert(self.particle_systems, entity)
		return
	end
	if string.find(entity.name, "Grass") then
		table.insert(self.grass, entity)
		return
	end
	--print("added", entity.name)
	table.insert(self.objects, entity)
end

function renderer:onRemove(entity)
	if entity.light then
		for i, light in ipairs(self.lights) do
			if light == entity then
				table.remove(self.lights, i)
				return
			end
		end
	end
	if entity.sky then
		self.sky = false
	end
	for i, object in ipairs(self.objects) do
		if object == entity then
			table.remove(self.objects, i)
			return
		end
	end
	for i, object in ipairs(self.particle_systems) do
		if object == entity then
			table.remove(self.particle_systems, i)
			return
		end
	end
end

function renderer:send_lights(shader, caster, light_vp)
	local lights = math.min(math.max(#self.lights, 1), 4)
	shader:sendInt("u_lights", lights)

	if light_vp and self.shadow_map then
		shader:send("u_shadow_vp", light_vp:to_vec4s())
		l3d.bind_shadow_texture(self.shadow_map, shader)
	end

	if #self.lights == 0 then
		shader:send("u_light_direction", { self.lights.default.direction:unpack() })
		shader:send("u_light_color", self.lights.default.color)
		shader:send("u_light_specular", self.lights.default.specular)
		shader:sendInt("u_shadow_index", 0)
		return
	end

	local light_info = {
		directions = {},
		colors = {},
		speculars = {}
	}
	for i = 1, math.min(#self.lights, 4) do
		local light = self.lights[i]
		local color = light.color or light.color or self.lights.default.color
		local specular = light.specular or light.specular or self.lights.default.specular
		local intensity = light.intensity or 1
		if light == caster then
			shader:sendInt("u_shadow_index", i-1)
		end
		table.insert(light_info.directions, { light.direction:unpack() })
		table.insert(light_info.speculars, {
			specular[1] * intensity,
			specular[2] * intensity,
			specular[3] * intensity
		})
		table.insert(light_info.colors, {
			color[1] * intensity,
			color[2] * intensity,
			color[3] * intensity
		})
	end

	shader:send("u_light_direction", unpack(light_info.directions))
	shader:send("u_light_specular",  unpack(light_info.speculars))
	shader:send("u_light_color",     unpack(light_info.colors))
end

function renderer:draw(state)
	local camera = self.world.camera_system.active_camera
	if Scene.current().disable_camera or not camera then
		self:draw_overlay()
		return
	end

	-- Render everything
	local shader = self.shaders.shadow

	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setDepthTest("less")

	local caster = false
	local light_vp, light_view, light_proj
	for i, light in ipairs(self.lights) do
		if light.cast_shadow and light.position then
			caster = light
			break
		end
	end

	local relevant_objects = {}
	local pos = assert(self.player.position)
	pos = pos + cpml.vec3(0, self.view_offset, 0)
	for _, object in ipairs(self.objects) do
		local distance = object.position:dist(pos)
		if not self.view_range or distance < self.view_range or object.always_visible then
			table.insert(relevant_objects, object)
		end
	end

	if caster and self.shadow_map then
		light_proj = cpml.mat4():ortho(-(caster.range or 2), (caster.range or 2), -(caster.range or 2), (caster.range or 2), -(caster.depth or 50), (caster.depth or 50))
		-- light_proj = cpml.mat4():perspective(caster.fov or 20, 1.0, caster.near or 0.1, caster.far or 1000.0)
		light_view = cpml.mat4():look_at(
			caster.position,
			caster.position - caster.direction,
			cpml.vec3(0,1,0)
		)
		local bias = cpml.mat4 {
			0.5, 0.0, 0.0, 0.0,
			0.0, 0.5, 0.0, 0.0,
			0.0, 0.0, 0.5, 0.0,
			0.5, 0.5, 0.5, 1.0 + caster.bias or 0.0
		}
		light_vp = light_view * light_proj * bias
		love.graphics.setShader(shader)
		shader:send("u_projection", light_proj:to_vec4s())
		shader:send("u_view", light_view:to_vec4s())

		-- remove this after filtering
		love.graphics.setCulling("front")
		l3d.bind_shadow_map(self.shadow_map)
		l3d.clear()
		for _, entity in ipairs(relevant_objects) do
			-- TODO: change to cast_shadow instead of a negative
			if not entity.no_shadow and entity.visible then
				self:draw_entity(entity, shader)
			end
		end
		l3d.bind_shadow_map()
		l3d.clear()
	end

	love.graphics.setCulling("back")
	love.graphics.setFrontFace("cw")
	love.graphics.setCanvas(self.canvas)
	love.graphics.clear(love.graphics.getBackgroundColor())
	love.graphics.clearDepth()

	if self.sky then
		shader = self.shaders.sky
		shader:send("u_light_direction", {(caster.direction or self.lights.default.direction):unpack()})
		love.graphics.setShader(shader)
		self.world.camera_system:send(shader)
		self:draw(self.sky, shader)
	end

	shader = self.shaders.default

	love.graphics.setShader(shader)
	love.graphics.clearDepth()
	love.graphics.setBlendMode("alpha", "premultiplied")

	shader:send("u_ambient", self.lights.ambient)
	self:send_lights(shader, caster, light_vp)
	shader:send("u_view_direction", { camera.direction:unpack() })
	self.world.camera_system:send(shader)
	if caster and caster.light_debug then
		shader:send("u_projection", light_proj:to_vec4s())
		shader:send("u_view", light_view:to_vec4s())
	end

	for _, entity in ipairs(relevant_objects) do
		if entity.visible then
			love.graphics.push("all")
			shader:sendInt("force_color", entity.force_color and 1 or 0)
			shader:send("u_roughness", entity.roughness or 0.4)
			if entity.color then
				love.graphics.setColor(
					entity.color[1]*255,
					entity.color[2]*255,
					entity.color[3]*255
				)
			else
				love.graphics.setColor(255, 255, 255)
			end
			-- don't send textures for the light pass
			local textures
			if entity.textures then
				textures = entity.textures
			end
			self:draw_entity(entity, shader, textures)
			love.graphics.pop()
		end
	end

	if false then
		table.sort(self.grass, function(a, b)
			return a.position.y > b.position.y
		end)

		love.graphics.setBlendMode("alpha")
		love.graphics.setColor(255, 255, 255)
		local grass_textures = {
			Material = "assets/textures/grass_texture.png"
		}
		love.graphics.setDepthWrite(false)
		for _, entity in ipairs(self.grass) do
			if entity.visible then
				love.graphics.push("all")
				shader:sendInt("force_color", 0)
				shader:send("u_roughness", 0.2)
				self:draw_entity(entity, shader, grass_textures)
				love.graphics.pop()
			end
		end
		love.graphics.setDepthWrite(true)
	end

	-- Octree Junk
	if self.octree_debug then
		local iqm = require "iqm".load("assets/models/cube.iqm")
		self.world.camera_system:send(self.shaders.default)
		self.world.octree:draw_bounds(model.mesh)
		self.world.octree:draw_objects(model.mesh, function(o)
			return o.triangle
		end)
	end

	shader = self.shaders.particle
	love.graphics.setShader(shader)
	self.world.camera_system:send(shader)
	for _, entity in ipairs(self.particle_systems) do
		self.world.particles:draw_particles(entity, shader)
	end

	-- Reset
	love.graphics.setBlendMode("alpha")
	love.graphics.setDepthTest()
	love.graphics.setCulling()

	love.graphics.setCanvas()
	if self.use_hdr then
		love.graphics.setShader(self.shaders.post)
		self.world.camera_system:send(self.shaders.post)
	else
		love.graphics.setShader()
	end
	love.graphics.draw(self.canvas)

	love.graphics.setShader()

	-- Draw top screen
	self:draw_overlay()
end

function renderer:draw_entity(entity, shader, textures)
	local model = assert(entity.mesh)

	local orientation = entity.orientation or self.default_orientation
	if entity.orientation_offset then
		orientation = orientation * entity.orientation_offset
	end
	local scale = entity.scale or self.default_scale

	love.graphics.updateMatrix(
		"transform",
		cpml.mat4()
			:translate(entity.position)
			:rotate(orientation)
			:scale(scale)
	)

	if entity.animation then
		entity.animation:send_pose(shader, "u_bone_matrices", "u_skinning")
	else
		shader:sendInt("u_skinning", 0)
	end

	for _, buffer in ipairs(model) do
		if textures then
			model.mesh:setTexture(load.texture(textures[buffer.material]))
		else
			model.mesh:setTexture()
		end
		model.mesh:setDrawRange(buffer.first, buffer.last)
		love.graphics.draw(model.mesh)
	end
end

return renderer
