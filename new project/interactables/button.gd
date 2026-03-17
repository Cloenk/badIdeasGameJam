@tool
extends StaticBody3D
enum ButtonMode {
## cycles thru the transforms in the list
	TransformSerial,
## randomly picks a transform from the list
	TransformRandom,
## blends between all paths from either start to end or end to start depending on its state
	TransformBlendpath,
## cyclically picks from the list to set a variable on the selected node
	VariableSerial,
## randomly picks from the list to set a variable on the selected node
	VariableRandom,
## blends thru the list to set a variable on the selected node
	VariableBlend,
}

var has_valid_nodepath: bool = false
@export_node_path("Node3D") var nodepath: NodePath:
	set(value):
		if value.get_name_count() > 0:
			print("connected to " + value.get_concatenated_names())
			has_valid_nodepath = true
			nodepath = value.slice(0, value.get_name_count())

@export var mode: ButtonMode = ButtonMode.TransformSerial

@export var transform_relative_position: bool = false

@export var transforms: Array[Transform3D]

@export var show_all_transforms: bool

@export_group("Add New Transform")
@export_tool_button("Add Transform") var add_transform_button = make_transform
@export var preview_to_add: bool = false
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var new_position: Vector3
@export_custom(PROPERTY_HINT_RANGE, "-360,360,0.1,or_greater,or_less,radians") var new_rotation: Vector3
@export_custom(PROPERTY_HINT_LINK, "") var new_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var rel_to_last: bool = false
## set to id of index to be relative to, or -1 to use last
@export var rel_to_previous: int = -1
@export var rel_from_this_position: bool = true
@export var rel_from_this_rotation: bool = false

var is_running: bool = false
var preview: bool = false
var apply_if_valid: bool = false
var reset_transform: bool = false

var serial_index: int = 0
var serial_last_index: int = 0
var serial_index_preview: int = 0
var serial_last_index_preview: int = 0

var blend_index: int = 0
var blend_last_index: int = 0

var last_quat: Quaternion
var next_quat: Quaternion
var last_pos: Vector3
var next_pos: Vector3
var last_scale: Vector3
var next_scale: Vector3
var original_transform: Transform3D
var current_transform: Transform3D

var accumulator: float = 0
var increment: float = 0
var inc_count: int = 1
var run_count: int = 0

@export_group("Action")
@export_tool_button("Preview Transform Gizmo") var preview_transform_gizmo_button = transform_button_function.bind(ButtonEditorButtons.PreviewTransformGizmo)
@export_tool_button("Preview Transform Object") var preview_transform_object_button = transform_button_function.bind(ButtonEditorButtons.PreviewTransformObject)
@export_tool_button("Transform Object") var transform_object_button = transform_button_function.bind(ButtonEditorButtons.TransformObject)
enum ButtonEditorButtons {
	PreviewTransformGizmo,
	PreviewTransformObject,
	TransformObject
}
func transform_button_function(which_button: ButtonEditorButtons):
	print(which_button)
	if has_valid_nodepath:
		var was_running = is_running
		accumulator = 0
		run_count = 0
		is_running = true
		match which_button:
			ButtonEditorButtons.PreviewTransformGizmo:
				preview = true
				apply_if_valid = false
				reset_transform = false
			ButtonEditorButtons.PreviewTransformObject:
				preview = true
				apply_if_valid = true
				reset_transform = true
			ButtonEditorButtons.TransformObject:
				preview = false
				apply_if_valid = true
				reset_transform = false
		increment = 1.0 / (blendtime * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
		inc_count = 1 + (blendtime * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
		if not was_running:
			original_transform = get_node(nodepath).global_transform
		var serial_or_random: bool = false
		match which_button:
			ButtonEditorButtons.PreviewTransformGizmo, ButtonEditorButtons.PreviewTransformObject:
				if mode == ButtonMode.TransformSerial or mode == ButtonMode.VariableSerial:
					serial_or_random = true
					serial_index_preview += 1
					if serial_index_preview >= len(transforms):
						serial_index_preview = 0
					serial_last_index_preview = serial_index_preview - 1
					if serial_last_index_preview < 0:
						serial_last_index_preview = len(transforms) - 1
				elif mode == ButtonMode.TransformRandom or mode == ButtonMode.VariableRandom:
					serial_or_random = true
					var next_idx = -1
					for i in range(0, 100):
						next_idx = randi_range(0, len(transforms) - 1)
						if (next_idx != serial_last_index_preview) and (next_idx != serial_index_preview):
							break
					serial_last_index_preview = serial_index_preview
					serial_index_preview = next_idx
				print(serial_last_index_preview, " -> ", serial_index_preview)
			ButtonEditorButtons.TransformObject:
				if mode == ButtonMode.TransformSerial or mode == ButtonMode.VariableSerial:
					serial_or_random = true
					serial_index += 1
					if serial_index >= len(transforms):
						serial_index = 0
					serial_last_index = serial_index - 1
					if serial_last_index < 0:
						serial_last_index = len(transforms) - 1
				elif mode == ButtonMode.TransformRandom or mode == ButtonMode.VariableRandom:
					serial_or_random = true
					var next_idx = -1
					for i in range(0, 100):
						next_idx = randi_range(0, len(transforms) - 1)
						if (next_idx != serial_last_index) and (next_idx != serial_index):
							break
					serial_last_index = serial_index
					serial_index = next_idx
				print(serial_last_index, " -> ", serial_index)
		if serial_or_random:
			var last_transform: Transform3D
			var next_transform: Transform3D
			match which_button:
				ButtonEditorButtons.PreviewTransformGizmo, ButtonEditorButtons.PreviewTransformObject:
					last_transform = transforms[serial_last_index_preview]
					next_transform = transforms[serial_index_preview]
				ButtonEditorButtons.TransformObject:
					last_transform = transforms[serial_last_index]
					next_transform = transforms[serial_index]
			if was_running:
				last_transform = current_transform
			last_quat = Quaternion(last_transform.basis.orthonormalized())
			next_quat = Quaternion(next_transform.basis.orthonormalized())
			last_pos = last_transform.origin
			next_pos = next_transform.origin
			last_scale = last_transform.basis.get_scale()
			next_scale = next_transform.basis.get_scale()
@export var blendtime: float = 2
@export var stepped: bool = false
@export var steps: int = 5

var debug_color: Color = Color.MAGENTA

func make_transform(append: bool = true):
	# show marker to visualize transform to be added
	var new_basis: Basis
	var show_pos := new_position
	var rel_pos := new_position
	var calc_xf_global: Transform3D
	if not rel_to_last:
		if rel_from_this_rotation:
			new_basis = (self.global_basis * Basis.from_euler(new_rotation)).orthonormalized().scaled_local(new_scale)
			show_pos = self.global_basis * new_position
			rel_pos = show_pos
		else:
			new_basis = Basis.from_euler(new_rotation).scaled_local(new_scale)
		calc_xf_global = Transform3D(new_basis, show_pos)
	else:
		var last_transform: Transform3D
		if (rel_to_previous < 0) or (rel_to_previous >= len(transforms)):
			last_transform = transforms[len(transforms) - 1].orthonormalized()
		else:
			last_transform = transforms[rel_to_previous].orthonormalized()
		calc_xf_global = Transform3D((last_transform.basis * Basis.from_euler(new_rotation)).orthonormalized().scaled_local(new_scale), last_transform.origin + last_transform.basis * new_position)
	
	# drawing
	var drawtime := 0.0
	if append:
		drawtime = 5
	if rel_from_this_position or rel_to_last:
		var calc_xf_relative: Transform3D = calc_xf_global.translated(self.global_position)
		DebugDraw3D.draw_gizmo(calc_xf_relative, DebugDraw3D.empty_color, true, drawtime)
	else:
		DebugDraw3D.draw_gizmo(calc_xf_global, DebugDraw3D.empty_color, true, drawtime)
	
	# writing
	if append:
		if transform_relative_position:
			if rel_from_this_position or rel_to_last:
				transforms.append(calc_xf_global)
			else:
				transforms.append(calc_xf_global.translated(-self.global_position))
		else:
			if rel_from_this_position or rel_to_last:
				transforms.append(calc_xf_global.translated(-self.global_position))
			else:
				transforms.append(calc_xf_global)
		notify_property_list_changed()

func _ready() -> void:
	debug_color = Color.from_ok_hsl(randf(), randf_range(0.8, 1.0), randf_range(0.2, 0.9))

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if preview_to_add:
			make_transform(false)
		if show_all_transforms:
			for xf in transforms:
				var xf_draw := xf
				if transform_relative_position:
					xf_draw = xf_draw.translated(self.global_position)
				DebugDraw3D.draw_gizmo(xf_draw, DebugDraw3D.empty_color, true)
				DebugDraw3D.draw_line(self.global_position, xf_draw.origin, debug_color)

func stepped_01(x: float, steps: int) -> float:
	return min(1, floor(float(steps) * x) / (steps - 1))

## returns true when finished
func transform_action(last_quat: Quaternion, next_quat: Quaternion, last_pos: Vector3, next_pos: Vector3, time01: float, apply: bool = true) -> bool:
	var blend_factor = time01
	if stepped:
		blend_factor = stepped_01(time01, steps)
	var blended_quat = last_quat.slerp(next_quat, blend_factor)
	var blended_pos = last_pos.lerp(next_pos, blend_factor)
	var blended_scale = last_scale.lerp(next_scale, blend_factor)
	current_transform = Transform3D(Basis(blended_quat).scaled(blended_scale), blended_pos)
	var use_transform = current_transform
	if transform_relative_position:
		use_transform = current_transform.translated(self.global_position)
	if apply:
		get_node(nodepath).global_transform = use_transform
	else:
		DebugDraw3D.draw_gizmo(use_transform, DebugDraw3D.empty_color, true)
		DebugDraw3D.draw_line(self.global_position, use_transform.origin, debug_color)
	return false

func transform_action_finished():
	pass

func _physics_process(delta: float) -> void:
	if is_running:
		#print(accumulator)
		#ButtonMode.TransformBlendpath:
			#last_transform = transforms[blend_last_index]
			#next_transform = transforms[blend_index]
		if (preview and Engine.is_editor_hint()) or not preview:
			transform_action(last_quat, next_quat, last_pos, next_pos, accumulator, apply_if_valid)
		if run_count >= inc_count:
			# done
			print("finished")
			run_count = 0
			is_running = false
			if reset_transform:
				get_node(nodepath).global_transform = original_transform
		accumulator += increment
		run_count += 1
