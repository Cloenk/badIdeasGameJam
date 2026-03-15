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

@export_node_path("Node3D") var nodepath: NodePath

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
	debug_color = Color.from_ok_hsl(randf(), randf_range(0.8, 1.0), randf_range(0.2, 0.8))

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
