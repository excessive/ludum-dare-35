// Shadows
uniform mat4 u_shadow_vp;
uniform int  u_shadow_index = 0;
uniform sampler2DShadow shadow_texture;

varying vec3 f_normal;
varying vec4 f_shadow_coords;
varying vec3 f_view_direction;

#define MAX_LIGHTS 4
#define PI 3.14159265

#ifdef VERTEX
   attribute vec3 VertexNormal;
   attribute vec4 VertexWeight;
   attribute vec4 VertexBone; // used as ints!

   uniform vec3 u_view_direction;
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
      f_view_direction = u_view_direction;
      f_shadow_coords = u_shadow_vp * transform * v_position;
      // f_shadow_coords *= 0.5;
      // f_shadow_coords += 0.5;
      return u_projection * u_view * transform * v_position;
   }
#endif

#ifdef PIXEL
   // Lighting
   uniform vec3 u_light_direction[MAX_LIGHTS];
   uniform vec3 u_light_specular[MAX_LIGHTS];
   uniform vec3 u_light_color[MAX_LIGHTS];
   uniform int  u_lights = 1;
   uniform vec3 u_ambient = vec3(0.05, 0.05, 0.05);

   // Material
   uniform float u_roughness = 0.25;
   uniform float u_fresnel   = 0.0;

   // Debug
   uniform int force_color;

   // Diffuse
   float oren_nayar_diffuse(vec3 lightDirection, vec3 viewDirection, vec3 surfaceNormal, float roughness, float albedo) {
     float LdotV = dot(lightDirection, viewDirection);
     float NdotL = dot(lightDirection, surfaceNormal);
     float NdotV = dot(surfaceNormal, viewDirection);

     float s = LdotV - NdotL * NdotV;
     float t = mix(1.0, max(NdotL, NdotV), step(0.0, s));

     float sigma2 = roughness * roughness;
     float A = 1.0 + sigma2 * (albedo / (sigma2 + 0.13) + 0.5 / (sigma2 + 0.33));
     float B = 0.45 * sigma2 / (sigma2 + 0.09);

     return albedo * max(0.0, NdotL) * (A + B * s / t) / PI;
   }

   // Specular
   float ggx_specular(vec3 L, vec3 V, vec3 N, float roughness, float fresnel) {
       vec3 H = normalize(V+L);

       float dotNL = clamp(dot(N,L), 0.0, 1.0);
       float dotLH = clamp(dot(L,H), 0.0, 1.0);
       float dotNH = clamp(dot(N,H), 0.0, 1.0);

       float alpha = roughness * roughness;
       float alphaSqr = alpha * alpha;
       float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0;
       float D = alphaSqr/(PI * denom * denom);

       float dotLH5 = pow(1.0-dotLH,5.0);
       float F = fresnel + (1.0-fresnel) * (dotLH5);

       float k = alpha * 0.5;
       float g1v = 1.0/(dotLH*(1.0-k)+k);
       float Vs = g1v * g1v;

       return dotNL * D * F * Vs;
   }

   vec3 shade(vec3 normal, vec4 albedo, int i) {
      vec3 view_direction  = normalize(f_view_direction);
      vec3 light_direction = normalize(u_light_direction[i]);

      float diff = oren_nayar_diffuse(light_direction, view_direction, normal, u_roughness, length(albedo.rgb));
      float fresnel = 1.0-pow(clamp(dot(normalize(f_view_direction), -normal), 0.0, 1.0), 1.0/2.5);
      float spec = ggx_specular(light_direction, -view_direction, normal, u_roughness, fresnel /* fresnel */);

      // Factor in shadow for the casting light
      if (i == u_shadow_index && f_shadow_coords.w > 0.0) {
         float illuminated = shadow2DProj(shadow_texture, f_shadow_coords).z;
         diff *= illuminated;
         spec *= illuminated;
      }
      diff = clamp(diff, 0.03, 1.0);

      vec3 color = u_light_color[i] * albedo.rgb * diff;
      color += u_light_specular[i] * spec * fresnel;

      return color;
   }
   vec4 effect(vec4 tint, Image texture, vec2 texture_coords, vec2 _s) {
      if (force_color != 0)
			return tint;

      vec3 normal = normalize(f_normal);
      vec4 albedo = texture2D(texture, texture_coords) * tint;
      vec3 color = u_ambient;

      for (int i = 0; i < u_lights; ++i) {
         color += max(shade(normal, albedo, i), vec3(0.0));
      }

      color = mix(albedo.rgb, color, 0.9);
      // color = mix(color, vec3(fresnel), 0.995);

      return vec4(color, albedo.a);
   }
#endif
