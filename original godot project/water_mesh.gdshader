shader_type spatial;
render_mode unshaded;

uniform sampler2D gradient_map : source_color, filter_linear, repeat_disable;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, repeat_disable, filter_nearest;

uniform float depth_fade_distance : hint_range(0.0, 20.0) = 1.0;
uniform float absorbance : hint_range(0.0, 10.0) = 2.0;

varying float height;
varying float foam_mix;
varying float sharper;

float triangle(float x) {
	return abs(fract((x - 1.0) * 0.25) * 4.0 - 2.0) - 1.0;
}

float waves(vec2 position) {
	float wave_linear = 0.5 * (1.0 + min(triangle(position.x), triangle(position.y)));
	return wave_linear * wave_linear;
}

vec2 rotate(vec2 vert, float angle) {
	float s = sin(angle);
	float c = cos(angle);

	// [cos - sin, sin + cos]
	return vec2(vert.x * c - vert.y * s, vert.x * s + vert.y * c );
}

void vertex() {
	float total_height;
	int iterations = 10;
	float decay = 0.7;
	float scale = 1.3333;
	float freq = 0.1;
	float amp = 1.0;
	float highest = 0.0;
	vec2 direction = vec2(1.0, 0.0);
	float direction_rotate = PI - 0.2;//1.618;
	float rotate_sum = PI * 0.5;
	float floor_time = floor(TIME * 8.0) * 0.125;
	vec2 vert = VERTEX.xz + vec2(floor_time * 1.5, 0.0);
	float vert_rotate = 0.3;
	float skew = 0.3;
	float skew_decay = -0.71;
	float foam = 0.0;
	float foam_total = 0.0;
	//float sharper_total = 0.0;
	for (int i = 0; i < iterations; i++) {
		vec2 input_vec = rotate(vert, rotate_sum) * freq * vec2(1.0, 2.0) + vec2(0.0, 2.0 * amp * floor_time);
		input_vec.x += input_vec.y * skew;
		float wave_output = waves((input_vec));
		sharper += (1.0 - amp) * wave_output; // commenting this out somehow breaks shader compilation and i do not know how
		//sharper_total += (1.0 - amp);
		foam += wave_output * float(i) * float(i);
		foam_total += float(i) * float(i);
		total_height += amp * wave_output;
		highest += amp;
		freq *= scale;
		amp *= decay;
		rotate_sum += direction_rotate;
		skew *= skew_decay;
		//vert = rotate(vert, vert_rotate);
	}
	total_height /= sqrt(highest);
	foam /= float(foam_total);
	//sharper /= sqrt(sharper_total);
	foam_mix = mix(total_height, mix(total_height, 1.0, 0.5) * 5.0 * foam, 0.5);
	height = total_height;
	VERTEX = vec3(VERTEX.x, 4.0 * total_height, VERTEX.z);
}

void fragment() {
	// Depth texture magic
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float depth_texture_y = world.y / world.w;
	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	float vertical_depth = vertex_y - depth_texture_y;
	
	// Changes the color of geometry behind it as the water gets deeper
	float depth_fade_blend = exp(-vertical_depth / depth_fade_distance);
	depth_fade_blend = clamp(depth_fade_blend, 0.0, 1.0);
	
	//float foam_thresholded = step(0.6, foam_mix);
	float foam_thresholded = clamp(10.0 * (foam_mix - 0.7), -0.5, 0.5) + 0.5;
	
	// Makes the water more transparent as it gets more shallow
	float alpha_blend = -(vertical_depth) * absorbance; //mix(absorbance, 4, clamp(foam_mix * foam_mix * foam_mix * foam_mix, 0.0, 1.0));
	alpha_blend = clamp(1.0 - exp(alpha_blend), 0.0, 1.0);

	ALBEDO = texture(gradient_map, vec2(max(foam_mix, 0.5 * (1.0 - alpha_blend)), 0.5)).rgb;
	//ALBEDO = texture(gradient_map, vec2(mix(sharper, foam_mix, 1.0), 0.5)).rgb;
	//ALBEDO = texture(gradient_map, vec2(mix(height, foam_mix, 0.5), 0.5)).rgb;
	//ALBEDO = mix(ALBEDO, vec3(1.0), foam_thresholded);
	ROUGHNESS = 1.0;
	//ALPHA = alpha_blend;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
