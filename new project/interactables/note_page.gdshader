shader_type spatial;
render_mode unshaded;

uniform sampler2D paper_atlas : repeat_enable;//, filter_nearest;
uniform int paper_color_select : hint_range(0, 4, 1) = 0;
uniform sampler2D paper_mult_overlay : filter_linear;
uniform float paper_mult_amount = 0;
uniform vec2 paper_mult_shift = vec2(0, 0);

uniform int paper_rotate : hint_range(0, 3, 1) = 0;
uniform bool paper_flip_x = false;
uniform bool paper_flip_y = false;
uniform int[8] page_lines;
uniform int[8] page_lines_repeat;
uniform int page_lines_use = 8;
uniform ivec2 page_size = ivec2(11, 15);
uniform bool page_loop;

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
	ivec2 page_size;
	bool loop;
	//bvec paper_cut_half_lrtb = bvec4(false, false, false, false);
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
	vec2 tile_pos = vec2(float(tile % 16), float(tile / 16 + color * 4)) / 16.0;
	return texture(paper_atlas, (uv_scaled + tile_pos) * vec2(1.0, 0.5));
}

int page_tile_index(Page page, ivec2 pos) {
	int line_index = -1;
	int line_accum = 0;
	if (!page.loop) {
		int line_total = 0;
		for (int i = 0; i < page.lines_use; i++) {
			if (page.line_repeat[i] > 0) {
				line_total += page.line_repeat[i];
			}
		}
		int line_remainder = page.page_size.x - line_total;
		//int neg_widths[8] = {0, 0, 0, 0, 0, 0, 0, 0};
		//int line_remainder_decrement = line_remainder;
		for (int i = 0; i < page.lines_use; i++) {
			if (page.line_repeat[i] <= 0) {
				line_accum += line_remainder;
			} else {
				line_accum += page.line_repeat[i];
			}
			if (pos.y < line_accum) {
				line_index = i;
				break;
			}
		}
		if (line_index < 0) {
			line_index = page.lines_use - 1;
		}
	} else {
		for (int i = 0; i < page.page_size.y; i++) {
			int idx = i % page.lines_use;
			if (page.line_repeat[idx] <= 0) {
				line_accum += 1;
			} else {
				line_accum += page.line_repeat[idx];
			}
			if (pos.y < line_accum) {
				line_index = idx;
				break;
			}
		}
	}
	Line line = page.lines[line_index];
	int tile_index = -1;
	int tile_accum = 0;
	int pos_x = pos.x;
	if (line.repeat_all) {
		pos_x = pos_x % line.tiles_use;
	}
	int tile_total = 0;
	for (int i = 0; i < line.tiles_use; i++) {
		if (line.tile_repeat[i] > 0) {
			tile_total += line.tile_repeat[i];
		}
	}
	int tile_remainder = page.page_size.x - tile_total;
	for (int i = 0; i < line.tiles_use; i++) {
		if (line.tile_repeat[i] <= 0) {
			tile_accum += tile_remainder;
		} else {
			tile_accum += line.tile_repeat[i];
		}
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

vec4 page_paper(vec2 uv, Page page, bool flipx, bool flipy, int rotate) {
	float page_scale = exp2(ceil(log2(float(max(page.page_size.x, page.page_size.y)))));
	vec2 page_offset = 0.5 * (vec2(page_scale) - vec2(page.page_size));
	vec2 uv_use = uv;
	if (flipx) {
		uv.x = 1.0 - uv.x;
	}
	if (flipy) {
		uv.y = 1.0 - uv.y;
	}
	if (rotate >= 1) {
		uv = vec2(uv.y, 1.0 - uv.x);
	}
	if (rotate >= 2) {
		uv = vec2(uv.y, 1.0 - uv.x);
	}
	if (rotate >= 3) {
		uv = vec2(uv.y, 1.0 - uv.x);
	}
	vec2 uv_page_scale = uv * page_scale - page_offset;
	vec2 uv_page_scale_clamped = clamp(uv_page_scale, vec2(0.0), vec2(page.page_size));
	float inside = (uv_page_scale.x >= 0.0 ? 1.0 : 0.0) * (uv_page_scale.x <= vec2(page.page_size).x ? 1.0 : 0.0) * (uv_page_scale.y >= 0.0 ? 1.0 : 0.0) * (uv_page_scale.y <= vec2(page.page_size).y ? 1.0 : 0.0);
	vec2 frac_uv = fract(uv_page_scale_clamped);
	//return vec4(frac_uv, inside, 1.0);
	ivec2 int_uv = ivec2(floor(uv_page_scale_clamped));
	int tile_index = page_tile_index(page, int_uv);
	//return vec4(float(tile_index) / 10.0, float(tile_index) / 10.0 - 1.0, float(tile_index) / 10.0 - 2.0, 1.0);
	vec4 tile = paper_tile(frac_uv, tile_index, paper_color_select);
	tile.a *= inside;
	return tile;
}

vec2 rotate(vec2 vert, float angle) {
	float s = sin(angle);
	float c = cos(angle);

	// [cos - sin, sin + cos]
	return vec2(vert.x * c - vert.y * s, vert.x * s + vert.y * c );
}

vec3 inv_mult(vec3 input, float scale) {
	return vec3(1.0) - (vec3(1.0) - input) * scale;
}

Page basic_page(Line top, Line hole, Line middle, int hole_count) {
	if (hole_count <= 2) {
		return Page({top, middle, hole, middle, hole, middle, middle, middle}, {1, 2, 1, 7, 1, 1, 1, 1}, 6, ivec2(11, 15), false);
	} else {
		return Page({top, middle, hole, middle, hole, middle, hole, middle}, {1, 1, 1, 4, 1, 4, 1, 1}, 8, ivec2(11, 15), false);
	}
}

const Line lines[] = {
		Line({12, 13, 12, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black vert only hole
		Line({12, 12, 12, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black vert only
		Line({14, 15, 14, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // pink vert only hole
		Line({14, 14, 14, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // pink vert only
		Line({41, 42, 41, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue vert only hole
		Line({41, 41, 41, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue vert only
		Line({28, 29, 28, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // big grid black across black down hole
		Line({28, 28, 28, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // big grid black across black down
		Line({30, 31, 30, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // big grid black across pink down hole
		Line({30, 30, 30, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // big grid black across pink down
		Line({8, 9, 8, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // big grid blue across blue down hole
		Line({8, 8, 8, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // big grid blue across blue down
		Line({11, 11, 11, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // big grid blue across pink down hole
		Line({11, 11, 11, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // big grid blue across pink down
		Line({44, 45, 44, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // big grid pink across black down hole
		Line({44, 44, 44, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // big grid pink across black down
		Line({46, 47, 46, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // big grid pink across pink down hole
		Line({46, 46, 46, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // big grid pink across pink down
		Line({0, 16, 0, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // plain hole
		Line({0, 0, 0, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // plain
		Line({1, 3, 1, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black small grid hole
		Line({1, 1, 1, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black small grid
		Line({2, 4, 2, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue small grid hole
		Line({2, 2, 2, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue small grid
		Line({27, 43, 27, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // pink small grid hole
		Line({27, 27, 27, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // pink small grid
		Line({33, 34, 35, 3, 4, 5, 6, 9}, {1, 0, 1, 1, 1, 1, 1, 1}, 3, false), // green bars green
		Line({33, 0, 35, 3, 4, 5, 6, 9}, {1, 0, 1, 1, 1, 1, 1, 1}, 3, false), // green bars plain
		Line({48, 49, 50, 3, 4, 5, 6, 9}, {1, -1, 1, 1, 1, 1, 1, 1}, 3, false), // red outline page top
		Line({54, 0, 55, 3, 4, 5, 6, 9}, {1, -1, 1, 1, 1, 1, 1, 1}, 3, false), // red outline page side
		Line({54, 56, 55, 3, 4, 5, 6, 9}, {1, -1, 1, 1, 1, 1, 1, 1}, 3, false), // red outline page side with lines
		Line({51, 52, 53, 3, 4, 5, 6, 9}, {1, -1, 1, 1, 1, 1, 1, 1}, 3, false), // red outline page bottom
		Line({17, 20, 1, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black small grid with no vertical on first two hole
		Line({17, 19, 1, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black small grid with no vertical on first two
		Line({23, 40, 2, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue small grid with no vertical on first two hole
		Line({23, 39, 2, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue small grid with no vertical on first two
		Line({36, 38, 2, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // pink small grid with no vertical on first two hole
		Line({36, 37, 2, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // pink small grid with no vertical on first two
		Line({28, 29, 1, 28, 4, 5, 6, 9}, {1, 1, -1, 1, 1, 1, 1, 1}, 4, false), // black small grid with big grid on first two hole
		Line({28, 28, 1, 28, 4, 5, 6, 9}, {1, 1, -1, 1, 1, 1, 1, 1}, 4, false), // black small grid with big grid on first two
		Line({8, 9, 2, 8, 4, 5, 6, 9}, {1, 1, -1, 1, 1, 1, 1, 1}, 4, false), // blue small grid with big grid on first two hole
		Line({8, 8, 2, 8, 4, 5, 6, 9}, {1, 1, -1, 1, 1, 1, 1, 1}, 4, false), // blue small grid with big grid on first two
		Line({46, 47, 27, 8, 4, 5, 6, 9}, {1, 1, -1, 1, 1, 1, 1, 1}, 4, false), // pink small grid with big grid on first two hole
		Line({46, 46, 27, 8, 4, 5, 6, 9}, {1, 1, -1, 1, 1, 1, 1, 1}, 4, false), // pink small grid with big grid on first two
		Line({17, 20, 17, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black double horiz black vert by hole, has hole
		Line({17, 19, 17, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black double horiz black vert by hole
		Line({17, 22, 17, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black double horiz pink vert by hole, has hole
		Line({17, 21, 17, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black double horiz pink vert by hole
		Line({23, 40, 23, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue double horiz blue vert by hole, has hole
		Line({23, 39, 23, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue double horiz blue vert by hole
		Line({23, 26, 23, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue double horiz pink vert by hole, has hole
		Line({23, 25, 23, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue double horiz pink vert by hole
		Line({0, 13, 5, 0, 4, 5, 6, 9}, {1, 1, -1, 1, 1, 1, 1, 1}, 4, false), // black plus grid with vertical by hole, has hole
		Line({0, 12, 5, 0, 4, 5, 6, 9}, {1, 1, -1, 1, 1, 1, 1, 1}, 4, false), // black plus grid with vertical by hole
		Line({0, 42, 6, 0, 4, 5, 6, 9}, {1, 1, -1, 1, 1, 1, 1, 1}, 4, false), // blue plus grid with vertical by hole, has hole
		Line({0, 41, 6, 0, 4, 5, 6, 9}, {1, 1, -1, 1, 1, 1, 1, 1}, 4, false), // blue plus grid with vertical by hole
		Line({0, 15, 7, 0, 4, 5, 6, 9}, {1, 1, -1, 1, 1, 1, 1, 1}, 4, false), // pink plus grid with vertical by hole, has hole
		Line({0, 14, 7, 0, 4, 5, 6, 9}, {1, 1, -1, 1, 1, 1, 1, 1}, 4, false),  // pink plus grid with vertical by hole
		Line({58, 59, 58, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black single horiz only hole
		Line({58, 58, 58, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black single horiz only
		Line({60, 61, 60, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // pink single horiz only hole
		Line({60, 60, 60, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // pink single horiz only
		Line({62, 63, 62, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue single horiz only hole
		Line({62, 62, 62, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue single horiz only
		Line({17, 18, 17, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black double horiz, has hole
		Line({17, 17, 17, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // black double horiz
		Line({23, 24, 23, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false), // blue double horiz, has hole
		Line({23, 23, 23, 3, 4, 5, 6, 9}, {1, 1, 1, 1, 1, 1, 1, 1}, 3, false)  // blue double horiz
	};

void fragment() {
	//Page pages[] = {
		//// demo pages to show all the lines
		//Page({lines[0], lines[1], lines[2], lines[3], lines[4], lines[5], lines[6], lines[7]}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, ivec2(11, 15)),
		//Page({lines[8], lines[9], lines[10], lines[11], lines[12], lines[13], lines[14], lines[15]}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, ivec2(11, 15)),
		//Page({lines[16], lines[17], lines[18], lines[19], lines[20], lines[21], lines[22], lines[23]}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, ivec2(11, 15)),
		//Page({lines[24], lines[25], lines[26], lines[27], lines[28], lines[29], lines[30], lines[31]}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, ivec2(11, 15)),
		//Page({lines[32], lines[33], lines[34], lines[35], lines[36], lines[37], lines[38], lines[39]}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, ivec2(11, 15)),
		//Page({lines[40], lines[41], lines[42], lines[43], lines[44], lines[45], lines[46], lines[47]}, {1, 1, 1, 1, 1, 1, 1, 1}, 8, ivec2(11, 15)),
		//// pages to use actually changing to passing the page in
		//basic_page(lines[1], lines[0], lines[1], 2), // black vert only
		//basic_page(lines[1], lines[0], lines[1], 3),
		//basic_page(lines[3], lines[2], lines[3], 2), // pink vert only
		//basic_page(lines[3], lines[2], lines[3], 3),
		//basic_page(lines[5], lines[4], lines[5], 2), // blue vert only
		//basic_page(lines[5], lines[4], lines[5], 3)
	//};
	//Page green_alternate = Page({lines[27], lines[26], lines[0], lines[0], lines[0], lines[0], lines[0], lines[0]}, {1, 1, 1, 1, 1, 1, 1, 1}, 2, ivec2(16, 13), true);
	Line[8] line_array = {
		lines[page_lines[0]],
		lines[page_lines[1]],
		lines[page_lines[2]],
		lines[page_lines[3]],
		lines[page_lines[4]],
		lines[page_lines[5]],
		lines[page_lines[6]],
		lines[page_lines[7]]
	};
	Page input = Page(line_array, page_lines_repeat, page_lines_use, page_size, page_loop);
	//vec4 page_rgba = page_paper(UV, basic_page(lines[1], lines[0], lines[1], 2), paper_flip.x, paper_flip.y, paper_rotate);
	vec4 page_rgba = page_paper(UV, input, paper_flip_x, paper_flip_y, paper_rotate);
	vec3 page_mult1 = inv_mult(texture(paper_mult_overlay, rotate(UV * 0.7 * 1.47 + vec2(0.5, 0.3) + paper_mult_shift, 1.5)).rgb, paper_mult_amount);
	vec3 page_mult2 = inv_mult(texture(paper_mult_overlay, rotate(UV * 0.7 * 1.93 + vec2(0.5, 0.7) + paper_mult_shift.yx, 0.7)).rgb, paper_mult_amount * 0.6);
	vec3 page_mult3 = inv_mult(texture(paper_mult_overlay, rotate(UV * 0.7 * 2.51 + vec2(0.5) - paper_mult_shift, 1.222)).rgb, paper_mult_amount * 0.2);
	ALBEDO = page_rgba.rgb * page_mult1 * page_mult2 * page_mult3;
	ALPHA = page_rgba.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
