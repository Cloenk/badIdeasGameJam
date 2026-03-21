shader_type spatial;
render_mode unshaded;

uniform sampler2D paper_atlas : repeat_enable;//, filter_nearest;
uniform int paper_color_select : hint_range(0, 4, 1) = 0;
uniform sampler2D paper_mult_overlay : filter_linear;

//uniform bool left_holes

struct Line {
	int tiles[8];
	int tile_repeat[8];
	int tiles_use;
	bool repeat_all;
};

struct Page {
	Line lines[8];
	int line_repeat[8];
	int lines_use;
	vec2 page_size;
};


void vertex() {
	// Called for every vertex the material is visible on.
}

vec4 paper_tile(vec2 uv, int tile, int color) {
	vec2 uv_scaled = clamp(uv, vec2(1.0 / 64.0), vec2(63.0 / 64.0));
	if (tile < 0) {
		uv_scaled.x = 1.0 - uv_scaled.x;
	}
	uv_scaled = vec2(0.5) + 1.0 * (uv_scaled - vec2(0.5));
	uv_scaled /= 16.0;
	vec2 tile_pos = vec2(float(tile % 16), float(tile / 16 + color * 3)) / 16.0;
	return texture(paper_atlas, uv_scaled + tile_pos);
}

int page_tile_index(Page page, ivec2 pos) {
	int line_index = -1;
	int line_accum = 0;
	for (int i = 0; i < page.lines_use; i++) {
		line_accum += page.line_repeat[i];
		if (pos.y < line_accum) {
			line_index = i;
			break;
		}
	}
	if (line_index < 0) {
		line_index = page.lines_use - 1;
	}
	Line line = page.lines[line_index];
	int tile_index = -1;
	int tile_accum = 0;
	int pos_x = pos.x;
	if (line.repeat_all) {
		pos_x = pos_x % line.tiles_use;
	}
	for (int i = 0; i < line.tiles_use; i++) {
		tile_accum += line.tile_repeat[i];
		if (pos_x < tile_accum) {
			tile_index = i;
			break;
		}
	}
	if (tile_index < 0) {
		tile_index = line.tiles_use - 1;
	}
	return line.tiles[tile_index];
}

vec4 page_paper(vec2 uv, Page page) {
	float page_scale = exp2(ceil(log2(max(page.page_size.x, page.page_size.y))));
	vec2 page_offset = 0.5 * (vec2(page_scale) - page.page_size);
	vec2 uv_page_scale = uv * page_scale - page_offset;
	vec2 uv_page_scale_clamped = clamp(uv_page_scale, vec2(0.0), page.page_size);
	float inside = (uv_page_scale.x >= 0.0 ? 1.0 : 0.0) * (uv_page_scale.x <= page.page_size.x ? 1.0 : 0.0) * (uv_page_scale.y >= 0.0 ? 1.0 : 0.0) * (uv_page_scale.y <= page.page_size.y ? 1.0 : 0.0);
	vec2 frac_uv = fract(uv_page_scale_clamped);
	//return vec4(frac_uv, inside, 1.0);
	ivec2 int_uv = ivec2(floor(uv_page_scale_clamped));
	int tile_index = page_tile_index(page, int_uv);
	//return vec4(float(tile_index) / 10.0, float(tile_index) / 10.0 - 1.0, float(tile_index) / 10.0 - 2.0, 1.0);
	vec4 tile = paper_tile(frac_uv, tile_index, paper_color_select);
	tile.a *= inside;
	return tile;
}

void fragment() {
	Line lines[] = {
		Line({0, 1, 2, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, false),
		Line({16, 17, 18, 19, 20, 21, 22, 23}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, false),
		Line({24, 25, 26, 32, 0, 0, 0, 0}, {1, 1, 1, 1, 1, 1, 1, 1}, 4, false),
		Line({16, 17, 18, 19, 20, 21, 22, 23}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, false),
		Line({16, 17, 18, 19, 20, 21, 22, 23}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, false),
		Line({16, 17, 18, 19, 20, 21, 22, 23}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, false),
		Line({16, 17, 18, 19, 20, 21, 22, 23}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, false),
		Line({16, 17, 18, 19, 20, 21, 22, 23}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, false)
	};
	Page pages[] = {
		Page({lines[0], lines[1], lines[2], lines[0], lines[1], lines[2], lines[0], lines[1]}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, vec2(11, 15))
	};
	vec4 page_rgba = page_paper(UV, pages[0]);
	ALBEDO = page_rgba.rgb;
	ALPHA = page_rgba.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
