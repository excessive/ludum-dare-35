varying vec3 f_normal;

uniform vec3 u_light_direction;

#ifdef VERTEX
	attribute vec3 VertexNormal;
	attribute vec4 VertexWeight;
	attribute vec4 VertexBone; // used as ints!

	uniform mat4 u_model, u_view, u_projection;
	uniform mat4 u_bone_matrices[32]; // this is why I want UBOs...
	uniform int	 u_skinning;

	mat4 getDeformMatrix() {
		if (u_skinning != 0) {
			// *255 because byte data is normalized against our will.
			return
				u_bone_matrices[int(VertexBone.x*255.0)] * VertexWeight.x +
				u_bone_matrices[int(VertexBone.y*255.0)] * VertexWeight.y +
				u_bone_matrices[int(VertexBone.z*255.0)] * VertexWeight.z +
				u_bone_matrices[int(VertexBone.w*255.0)] * VertexWeight.w;
		}
		return mat4(1.0);
	}

	vec4 position(mat4 mvp, vec4 v_position) {
		mat4 transform = u_model * getDeformMatrix();
		f_normal = mat3(transform) * VertexNormal;
		vec4 position = u_projection * u_view * transform * v_position;
		position.z = 1.0;

		return position;
	}
#endif

#ifdef PIXEL
	uniform int force_color;

	const vec4 sun_color = vec4(3.0, 2.6, 2.2, 1.0);

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
		if (force_color != 0) {
			return color;
		}
		if (dot(u_light_direction, normalize(f_normal)) < -0.95) {
			return sun_color;
		}

		return texture2D(texture, texture_coords) * color;
	}
#endif
