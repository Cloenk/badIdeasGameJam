shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D Palette_LUT : repeat_disable, filter_nearest;

#include "res://pixel shader/quantize.gdshaderinc"

// The Bayer matrix pattern to use
// 1 -> 2x2, 2 -> 4x4, 3 -> 8x8
uniform float bayer_pattern : hint_range(1, 3, 1.0) = 1;

const int matrix2[4] = {
    0, 2,
    3, 1
};
const int matrix4[16] = {
    0,  8,  2,  10,
    12, 4,  14, 6,
    3,  11, 1,  9,
    15, 7,  13, 5
};
const int matrix8[64] = {
    0,  32, 8,  40, 2,  34, 10, 42,
    48, 16, 56, 24, 50, 18, 58, 26,
    12, 44, 4,  36, 14, 46, 6,  38,
    60, 28, 52, 20, 62, 30, 54, 22,
    3,  35, 11, 43, 1,  33, 9,  41,
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47, 7,  39, 13, 45, 5,  37,
    63, 31, 55, 23, 61, 29, 53, 21
};

int getBayerValue(float dSize, vec2 in_world_vertex) {
    int iDSize = int(dSize);
    float q_size = max(g_q_size, 1.);
    ivec2 iv = ivec2(mod(in_world_vertex, dSize * q_size));
    iv /= int(q_size);
    int index = iv.x + (iv.y * iDSize);

    switch (iDSize) {
        case 2:
            return matrix2[index];
        case 4:
            return matrix4[index];
        default:
            return matrix8[index];
    }
}

//uniform int pixel_size : hint_range(1, 64) = 4; // Pixel size
//uniform vec2 screen_size = vec2(1280.0, 720.0); // Screen size (set manually)

void vertex() {
	g_q_size = getQuantizeSize(CANVAS_MATRIX);
	g_model_matrix = MODEL_MATRIX;
	g_world_to_clip = SCREEN_MATRIX * CANVAS_MATRIX;
	g_vertex = VERTEX;
}

void fragment() {
	//Pixel coordinates in screen space
	//vec2 pixel_coords = floor(FRAGCOORD.xy / float(pixel_size)) * float(pixel_size);
	// Convert pixel coordinates to UVs for screen texture
	//vec2 uv = pixel_coords / screen_size;
	// Get color from texture screen
	//COLOR = texture(SCREEN_TEXTURE, uv);
	//COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	//COLOR = ditherScreen(SCREEN_TEXTURE, SCREEN_UV, g_vertex);
	vec2 world_vertex;
	COLOR = quantizeScreen(SCREEN_TEXTURE, SCREEN_UV, g_vertex, world_vertex);

	// Get dither size based on matrix selected
	float dSize = pow(2.0, bayer_pattern);
	float dSquared = dSize * dSize;
	// get dither value
	int d = getBayerValue(dSize, world_vertex);

	// normalize the dither value
	float dN = (float(d) / dSquared) - 0.5;
	// get the normalizing value for the division gap
	float r = 1.0 / 32.0;//div;
	float l = r / (dSquared * 2.);

	COLOR += r * dN + l; // add dither value to color

	// LUT is 64 tall, 2048 long. 32 steps of blue, 64 * 64 rg
	float lut_x = (64.0 * COLOR.r + 64.0 * floor(31.0 * COLOR.b)) / 2048.0;
	vec2 lut_pos = vec2(lut_x, 1.0 - COLOR.g);
	COLOR = texture(Palette_LUT, lut_pos);
}