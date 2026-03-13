@tool
extends Node3D


## Vertical stacking of raycasts pointed -Z
@export_range(0, 10, 1, "or_greater") var stack_count: int = 8:
	set(value):
		stack_count = value
		resize_arrays()

@export var stack_height: Vector3 = Vector3.UP

@export var direction: Vector3 = Vector3.FORWARD

## Useful to disable when not moving, in the air, or results would otherwise not be used
@export var enabled: bool = true

## Raycast distance forward (-Z)
@export_range(0, 10, 0.01, "or_greater") var distance: float = 1

## Collision mask for rays to check
@export_flags_3d_physics var collision_mask: int = 1

@export_tool_button("Update") var update_button = update


var hit_pos: PackedVector3Array
var hit_dist: PackedFloat32Array
#var fixup_outer_idx: PackedInt32Array
#var fixup_inner_idx: PackedInt32Array
var segment_calculated_normal: PackedVector2Array
func resize_arrays() -> void:
	hit_pos.resize(stack_count)
	hit_pos.fill(Vector3.ZERO)
	hit_dist.resize(stack_count)
	hit_dist.fill(-1)
	#fixup_outer_idx.resize(stack_count)
	#fixup_outer_idx.fill(-1)
	#fixup_inner_idx.resize(stack_count)
	#fixup_inner_idx.fill(-1)
	segment_calculated_normal.resize(stack_count - 1)
	segment_calculated_normal.fill(Vector2.UP)

func _ready() -> void:
	resize_arrays()

func update(exclude: Array = []) -> Array[Vector3]:
	# get distances
	# remove underhangs (if a lower raycast sticks out further than ones above, it should be ignored, with its value set to the interpolation of the valid ones to either side
	# find the furthest out segment which has a slope higher than the desired slope for the given speed, but within the maximum step length
	# check the height of the next segment out
	# check the slope of the start to the step top
	#no clue how this is supposed to work
	#DebugDraw3D.new_scoped_config().set_thickness(0.05)
	DebugDraw3D.clear_all()
	var stack_offset: Vector3 = stack_height / stack_count
	var space_state = get_world_3d().direct_space_state
	for i in stack_count:
		var start_pos = self.global_position + stack_offset * i
		var end_pos = start_pos + direction * distance
		var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
		query.hit_from_inside = true
		query.exclude = exclude
		var result = space_state.intersect_ray(query)
		var pos = result.get("position")
		var did_hit = true
		if pos == null:
			did_hit = false
			pos = start_pos + direction * distance + direction * (i+1) * 0.25
			DebugDraw3D.draw_line(end_pos, pos, Color.RED, 30)
		hit_pos[i] = pos
		hit_dist[i] = pos.distance_to(start_pos)
		DebugDraw3D.draw_line_hit(start_pos, end_pos, hit_pos[i], did_hit, 0.05, Color.PURPLE, Color.DARK_RED, 30)
	
	var last_valid_distance = hit_dist[len(hit_dist) - 1]
	var last_valid_idx = len(hit_dist) - 1
	var first_valid_distance = 0
	var first_valid_idx = -1
	for i in range(len(hit_dist) - 2, -1, -1):
		if hit_dist[i] <= last_valid_distance:
			last_valid_distance = hit_dist[i]
			last_valid_idx = i
		# to use interpolated undershoot:
		# uncomment everything after this to the debug draw lines
		# comment out the following line
		# move the second line to the end of the last loop
		# uncomment the lines higher in the script relating to fixup arrays
		hit_dist[i] = hit_dist[last_valid_idx]
		hit_pos[i] = self.global_position + stack_offset * i + direction * hit_dist[i] + Vector3(0.1, 0, 0)
			#fixup_outer_idx[i] = -1
		#else:
			#hit_dist[i] = -1
			#fixup_outer_idx[i] = last_valid_idx
	#for i in range(0, len(hit_dist)):
		#if hit_dist[i] < 0:
			#fixup_inner_idx[i] = first_valid_idx
		#else:
			#fixup_inner_idx[i] = -1
			#first_valid_idx = i
	#for i in range(0, len(hit_dist)):
		#if fixup_outer_idx[i] >= 0:
			#hit_dist[i] = hit_dist[fixup_outer_idx[i]]
		#if fixup_outer_idx[i] != fixup_inner_idx[i]:
			#var blend_factor: float = (float(i) - fixup_inner_idx[i]) / (fixup_outer_idx[i] - fixup_inner_idx[i])
			#hit_dist[i] = lerp(hit_dist[fixup_inner_idx[i]], hit_dist[fixup_outer_idx[i]], blend_factor)
			##DebugDraw3D.draw_line(direction * hit_dist[i] + Vector3(0.2, 0, 0), direction * hit_dist[i] + Vector3(0.2, blend_factor, 0), Color.LIME_GREEN, 30)
	DebugDraw3D.draw_line_path(PackedVector3Array(hit_pos), Color.DARK_TURQUOISE, 30)
	var stack_step_height = stack_height.length() / stack_count
	var check_after: Array[int] = [0] # indices
	var check_after_write_idx: int = 0
	var has_been_facing_up: bool = true
	for i in range(0, len(segment_calculated_normal)): # one less
		var p1: Vector2 = Vector2(hit_dist[i], stack_step_height * i)
		var p2: Vector2 = Vector2(hit_dist[i + 1], stack_step_height * (i + 1))
		segment_calculated_normal[i] = (p2 - p1).normalized()
		segment_calculated_normal[i] = Vector2(segment_calculated_normal[i].y, segment_calculated_normal[i].x)
		var facing_up: bool = segment_calculated_normal[i].y > 0.8
		print(segment_calculated_normal[i])
		var avg_pos: Vector3 = (hit_pos[i] + hit_pos[i + 1]) * 0.5
		DebugDraw3D.draw_arrow(avg_pos, avg_pos + 0.25 * Vector3(0, segment_calculated_normal[i].y, segment_calculated_normal[i].x), Color.LIGHT_SALMON if facing_up else Color.DARK_ORANGE, 0.01, false, 30)
		print(i, " ", facing_up)
		if not facing_up:
			has_been_facing_up = false
			check_after[check_after_write_idx] = i + 1
		else:
			if not has_been_facing_up:
				check_after_write_idx += 1
				check_after.append(0)
			has_been_facing_up = true
		print(check_after)
	if len(check_after) > 1 and check_after[len(check_after) - 1] == 0:
		check_after.pop_back()
	print(check_after)
	var result: Array[Vector3]
	for n in check_after:
		var raycast_out: float
		print(n, " ", len(hit_dist))
		if n >= len(hit_dist) - 1:
			raycast_out = hit_dist[len(hit_dist) - 1] + 0.1
		else:
			raycast_out = hit_dist[n] + clamp((hit_dist[n + 1] - hit_dist[n]) * 0.1, 0.005, 0.1) # 0.1 m is about half the length of a human foot. min is to prevent floating point errors
		#var raycast_out = lerp(hit_dist[n], hit_dist[n + 1], 0.1)
		var raycast_end: Vector3 = self.global_position + raycast_out * direction
		var raycast_start: Vector3 = raycast_end + stack_height
		var query = PhysicsRayQueryParameters3D.create(raycast_start, raycast_end)
		query.hit_from_inside = true
		query.exclude = exclude
		var top_down_check = space_state.intersect_ray(query)
		var pos = top_down_check.get("position")
		if (raycast_start - pos).length() > 0.01: # 0.01 m is a bit over a third of an inch
			# also check that pos is higher than (on stack_height axis) the height (not dist) of hit_dist[n]
			result.append(pos)
		print(raycast_start - pos)
		DebugDraw3D.draw_arrow(raycast_start + Vector3(0.1, 0, 0), pos + Vector3(0.1, 0, 0), Color.GOLDENROD, 0.05, false, 30)
		DebugParabola3D.draw_3points(Vector3(0.2, 0, 0), pos * Vector3(0, 0.5, 0.5) + Vector3(0.2, 1, 0), pos + Vector3(0.2, 0, 0), 10, 0, Color.TEAL, 30)
	return result

func project_to_parametric_plane(p: Vector3, v1: Vector3, v2: Vector3) -> Vector2:
	var x: float = p.dot(v1)
	var y: float = p.dot(v2)
	# x * v1 + y * v2
	return Vector2(x, y)

func orthonormalize_parametric_vectors(up_ish: Vector3, forward_ish: Vector3) -> Array[Vector3]:
	var forward: Vector3 = (forward_ish * Vector3(1, 0, 1)).normalized()
	var up: Vector3 = (up_ish - (up_ish.dot(forward) * forward)).normalized()
	return [up, forward]

func orthonormalize_parametric_forward(forward_ish: Vector3) -> Vector3:
	return (forward_ish * Vector3(1, 0, 1)).normalized()

func jump_calc_one_internal(start_vel: float, end: Vector2, gravity: float = -9.8) -> Dictionary:
	var up_vel: float = end.y * start_vel / end.x - 0.5 * gravity * end.x / start_vel
	var max_height: float = -0.5 * up_vel * up_vel / gravity
	var max_pos: float = -up_vel * start_vel / gravity
	var res: Dictionary
	res["is_after_max"] = end.x > max_pos
	res["max_height"] = max_height
	res["up_vel"] = up_vel
	res["fall_amount"] = max_height - end.y
	return res
