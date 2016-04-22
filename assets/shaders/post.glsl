const float gamma = 2.5;

uniform float u_exposure = 1.0;

vec3 filmic_tonemap(vec3 color)
{
	color = max(vec3(0.), color - vec3(0.002));
	color = (color * (6.2 * color + .5)) / (color * (6.2 * color + 1.7) + 0.06);
	return color;
}

vec3 uncharted2_tonemap(vec3 x) {
	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;

	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	vec2  center = vec2(love_ScreenSize.x / 2.0, love_ScreenSize.y / 2.0);
	float aspect = love_ScreenSize.x / love_ScreenSize.y;
	float distance_from_center = distance(screen_coords, center);
	float power = 2.25;
	float offset = 2.0;
	vec4 bg  = texture2D(texture, texture_coords);
	// vec4 tex = texture2D(u_noise, screen_coords / 128.0) * u_noise_strength;
	vec4 fg = (color) * vec4(vec3(1.0 - pow(distance_from_center / (center.x * offset), power) + (1.0 - color.a)), 1.0);

	// if (texture_coords.x > 0.5) {
	// 	return vec4(pow(bg.rgb, vec3(gamma)), 1.0);
	// }

	return vec4(filmic_tonemap(pow(bg.rgb * u_exposure, vec3(gamma))), 1.0) * fg;
}
