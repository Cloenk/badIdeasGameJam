shader_type spatial;
render_mode unshaded;

uniform sampler2D gradient_map : source_color, filter_linear, repeat_disable;

varying float height;

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
	float direction_rotate = 1.618;//PI + 0.2;//1.618;
	float rotate_sum = 0.7;
	vec2 vert = VERTEX.xz;
	float vert_rotate = 0.3;
	float skew = 0.3;
	float skew_decay = -0.71;
	float floor_time = floor(TIME * 8.0) * 0.125;
	for (int i = 0; i < iterations; i++) {
		vec2 input_vec = rotate(vert, rotate_sum) * freq * vec2(1.0, 2.0) + vec2(0.0, 2.0 * amp * floor_time);
		input_vec.x += input_vec.y * skew;
		total_height += amp * waves((input_vec));
		highest += amp;
		freq *= scale;
		amp *= decay;
		rotate_sum += direction_rotate;
		skew *= skew_decay;
		//vert = rotate(vert, vert_rotate);
	}
	total_height /= sqrt(highest);
	height = total_height;
	VERTEX = vec3(VERTEX.x, 2.0 * total_height, VERTEX.z);
}

void fragment() {
	ALBEDO = texture(gradient_map, vec2(height, 0.5)).rgb;
	ROUGHNESS = 1.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
