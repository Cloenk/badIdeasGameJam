@tool
extends StaticBody3D

enum ButtonMode {
	TransformSerial,
	TransformRandom,
	Variable
}

@export_node_path("Node3D") var nodepath: NodePath

@export var mode: ButtonMode = ButtonMode.TransformSerial

@export var transform_relative: bool = false

@export var transforms: Array[Transform3D]

@export var show_all_transforms: bool

@export_group("Add New Transform")
#@export_tool_button("Add Transform")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var new_position: Vector3
@export_custom(PROPERTY_HINT_RANGE, "-360,360,0.1,or_greater,or_less,radians") var new_rotation: Vector3
@export_custom(PROPERTY_HINT_LINK, "") var new_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var rel_to_last: bool = false
@export var rel_from_this_position: bool = true
@export var rel_from_this_full: bool = false

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		# show marker to visualize transform to be added
		var new_basis: Basis
		var use_pos := new_position
		if rel_from_this_full:
			new_basis = (self.global_basis * Basis.from_euler(new_rotation)).orthonormalized().scaled_local(new_scale)
			use_pos = self.global_basis * new_position
		else:
			new_basis = Basis.from_euler(new_rotation).scaled_local(new_scale)
		var calc_xf_global: Transform3D = Transform3D(new_basis, use_pos + self.global_position)
		var calc_xf_relative: Transform3D = Transform3D(new_basis, use_pos)
		DebugDraw3D.draw_gizmo(calc_xf_global, DebugDraw3D.empty_color, true)
