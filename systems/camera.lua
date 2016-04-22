local tiny   = require "tiny"
local cpml   = require "cpml"

local system     = tiny.processingSystem {
	filter        = tiny.requireAll("camera"),
	active_camera = false,
	camera_data   = {},
	default       = {
		fov  = 45,
		near = 0.001, -- 1mm
		far  = 100.0, -- 100m
		exposure = 1.0,

		position     = cpml.vec3(0, 0, 0),
		orientation  = cpml.quat(0, 0, 0, 1),
		scale        = cpml.vec3(1, 1, 1),
		velocity     = cpml.vec3(0, 0, 0),
		direction    = cpml.vec3(0, -1, 0),
		orbit_offset = cpml.vec3(0, 0, 0),
		offset       = cpml.vec3(0, 0, 0),
		up           = cpml.vec3.unit_z,

		-- up/down limit (percent)
		pitch_limit_up    = 0.5, --math.pi / 2.05,
		pitch_limit_down  = 0.5, --math.pi / 2.05,

		mouse_sensitivity = 1 / 15, -- radians/px
	}
}

function system:onAdd(entity)
	-- Ensure camera is properly set up
	self.already_bitched = false

	entity.position     = entity.position     or self.default.position
	entity.orientation  = entity.orientation  or self.default.orientation
	entity.scale        = entity.scale        or self.default.scale
	entity.velocity     = entity.velocity     or self.default.velocity
	entity.direction    = entity.direction    or self.default.direction
	entity.orbit_offset = entity.orbit_offset or self.default.orbit_offset
	entity.offset       = entity.offset       or self.default.offset
	entity.up           = entity.up           or self.default.up
	entity.fov          = entity.fov          or self.default.fov
	entity.near         = entity.near         or self.default.near
	entity.far          = entity.far          or self.default.far
	entity.exposure     = entity.exposure     or self.default.exposure

	entity.pitch_limit_up   = entity.pitch_limit_up   or self.default.pitch_limit_up
	entity.pitch_limit_down = entity.pitch_limit_down or self.default.pitch_limit_down

	self.active_camera = entity

	system.camera_data[entity] = {
		view       = cpml.mat4(),
		projection = cpml.mat4()
	}
end

function system:onRemoveFromWorld()
	system.camera_data = {}
	system.active_camera = false
end

function system:onRemove(entity)
	system.camera_data[entity] = nil
	if entity == self.active_camera then
		self.active_camera = false
	end
end

function system:process(entity, dt)
	local data   = self.camera_data[entity]
	local pos    = entity.position
	local dir    = entity.direction
	local up     = entity.up
	local orbit  = entity.orbit_offset
	local offset = entity.offset

	if not entity.forced_transforms and not entity.tracking then
		data.view = data.view:identity()
			:translate(orbit)
			:look_at(pos, pos + dir, up)
			:translate(offset)
	elseif entity.tracking then
		data.view = data.view:identity()
			:translate(orbit)
			:look_at(pos, entity.tracking, up)
			:translate(offset)
	end

	local w, h = love.graphics.getDimensions()
	data.projection = data.projection:identity()
	data.projection = data.projection:perspective(entity.fov, w/h, entity.near, entity.far)
end

function system:move(vector, speed, normal)
	local entity = self.active_camera
	if not entity then
		if not self.already_bitched then
			console.e("No active camera.")
			self.already_bitched = true
		end
		return
	end
	local forward = entity.direction:normalize()
	local up      = (normal or entity.up):normalize()
	local side    = forward:cross(up):normalize()

	if not entity.position then
		entity.position = self.defaults.position:clone()
	end

	entity.position.x = entity.position.x + vector.x * side.x * speed
	entity.position.y = entity.position.y + vector.x * side.y * speed
	entity.position.z = entity.position.z + vector.x * side.z * speed

	entity.position.x = entity.position.x + vector.y * forward.x * speed
	entity.position.y = entity.position.y + vector.y * forward.y * speed
	entity.position.z = entity.position.z + vector.y * forward.z * speed

	entity.position.x = entity.position.x + vector.z * up.x * speed
	entity.position.y = entity.position.y + vector.z * up.y * speed
	entity.position.z = entity.position.z + vector.z * up.z * speed
end

function system:rotate_xy(mx, my)
	local entity = self.active_camera
	if not entity then
		if not self.already_bitched then
			console.e("No active camera.")
			self.already_bitched = true
		end
		return
	end
	local sensitivity = entity.mouse_sensitivity or self.defaults.mouse_sensitivity
	local mouse_direction = {
		x = math.rad(mx * sensitivity),
		y = math.rad(my * sensitivity)
	}

	if not entity.direction then
		entity.direction = self.defaults.direction:clone()
	end

	if not entity.up then
		entity.up = self.defaults.up:clone()
	end

	-- get the axis to rotate around the x-axis.
	local axis = entity.direction:cross(entity.up)
	axis = axis:normalize()

	if not entity.orientation then
		entity.orientation = self.defaults.orientation:clone()
	end

	-- First, we apply a left/right rotation.
	entity.orientation = cpml.quat.rotate(mouse_direction.x, entity.up) * entity.orientation

	-- Next, we apply up/down rotation.
	-- up/down rotation is applied after any other rotation (so that other rotations are not affected by it),
	-- hence we post-multiply it.
	local new_orientation = entity.orientation * cpml.quat.rotate(mouse_direction.y, cpml.vec3.unit_x)
	local new_pitch = (new_orientation * cpml.vec3.unit_y):dot(entity.up)

	-- Don't rotate up/down more than entity.pitch_limit.
	-- We need to limit pitch, but the only reliable way we're going to get away with this is if we
	-- calculate the new orientation twice. If the new rotation is going to be over the threshold and
	-- Y will send you out any further, cancel it out. This prevents the camera locking up at +/-PITCH_LIMIT
	if new_pitch >= entity.pitch_limit_up then
		mouse_direction.y    = math.min(0, mouse_direction.y)
	elseif new_pitch <= -entity.pitch_limit_down then
		mouse_direction.y    = math.max(0, mouse_direction.y)
	end

	entity.orientation = entity.orientation * cpml.quat.rotate(mouse_direction.y, cpml.vec3.unit_x)

	-- Apply rotation to camera direction
	entity.direction = entity.orientation * cpml.vec3.unit_y
end

function system:send(shader, view_name, proj_name, exposure_name)
	assert(shader)
	local entity = self.active_camera
	if not entity then
		if not self.already_bitched then
			console.e("No active camera.")
			self.already_bitched = true
		end
		return
	end
	local data = self.camera_data[entity]
	local ename = exposure_name or "u_exposure"
	if shader:getExternVariable(ename) then
		shader:send(ename, entity.exposure)
	end
	local vname = view_name or "u_view"
	if shader:getExternVariable(vname) then
		shader:send(vname, data.view:to_vec4s())
	end
	local pname = proj_name or "u_projection"
	if shader:getExternVariable(pname) then
		local proj = data.projection
		if flip or love.graphics.getCanvas() then
			proj = proj:scale(cpml.vec3(1, -1, 1))
		end
		shader:send(pname, proj:to_vec4s())
	end
end

return system
