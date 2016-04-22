varying vec4 VaryingColor;
varying vec4 VaryingTexCoord;

#ifdef VERTEX
	attribute vec4 VertexPosition;
	attribute vec4 VertexWeight;
	attribute vec4 VertexBone;
	//attribute vec4 VertexColor;

	uniform mat4 u_view, u_model, u_projection;
	uniform mat4 u_bone_matrices[32];
	uniform int u_skinning;

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
	void main() {
		mat4 transform = u_model * getDeformMatrix();
		VaryingColor = vec4(1.0);
		VaryingTexCoord = vec4(0.0);
		gl_Position = u_projection * u_view * transform * VertexPosition;
	}
#endif

#ifdef PIXEL
	// do nothing!
	void main() {
		//gl_FragDepth = gl_FragCoord.z;
	}
#endif
