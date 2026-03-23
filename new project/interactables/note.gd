extends StaticBody3D

@onready var camera_3d: Camera3D = $rotate/tilt/Camera3D
@onready var plane: MeshInstance3D = $plane
@onready var sub_viewport: SubViewport = $SubViewport

var current_camera: Camera3D
#var curr_cam_original_gxform: Transform3D
var curr_cam_original_xform: Transform3D
var to_cam_pos: Vector3
var to_cam_gpos: Vector3
var to_cam_quat: Quaternion
var from_cam_pos: Vector3
var from_cam_gpos: Vector3
var from_cam_quat: Quaternion
var bez_point_pos: Vector3
var bez_point_gpos: Vector3
var original_fov: float

var interpolate: float = 0
var is_moving_cam: bool = false
var can_cancel: bool = false
var counter: float = 0.0
var counter_max: float = 2.0
var counter_scale: float = 1.0

var input_shim_id: int

func _ready() -> void:
	input_shim_id = self.get_rid().get_id()
	var plane_mat: StandardMaterial3D = plane.mesh.surface_get_material(0)
	plane_mat.albedo_texture = sub_viewport.get_texture()
	plane_mat.emission_texture = sub_viewport.get_texture()
	plane_mat.backlight_texture = sub_viewport.get_texture()
	#print(input_shim_id)

func click():
	#current_camera = get_viewport().get_camera_3d()
	#print("click")
	if GlobalReferences.camera != null:
		#print("GlobalReferences.camera is not null")
		current_camera = GlobalReferences.camera.active_camera
		if current_camera != null:
			#print("GlobalReferences.camera.active_camera is not null")
			GlobalReferences.camera.set_mode_freeze_captured()
			GlobalReferences.camera.input_shims[input_shim_id] = input_shim
			GlobalReferences.camera.can_call_click = false
			GlobalReferences.player.movement.can_move = false
			#curr_cam_original_gxform = current_camera.global_transform
			curr_cam_original_xform = current_camera.transform
			to_cam_pos = camera_3d.position
			to_cam_gpos = camera_3d.global_position
			to_cam_quat = Quaternion(camera_3d.global_transform.basis)
			from_cam_pos = current_camera.global_position - self.global_position
			from_cam_gpos = current_camera.global_position
			from_cam_quat = Quaternion(current_camera.global_transform.basis)
			bez_point_pos = to_cam_pos.normalized() * from_cam_pos.length()
			bez_point_gpos = bez_point_pos + self.global_position
			original_fov = current_camera.fov
			counter = 0
			counter_scale = 1.0
			can_cancel = false
			#var tween = create_tween()
			#tween.tween_property($".", "interpolate", 1, 4.0)
			#tween.parallel().tween_callback(f_can_cancel).set_delay(0.25)
			is_moving_cam = true

func f_can_cancel():
	can_cancel = true

func reset_curr_cam():
	if current_camera != null:
		#print("reset")
		counter = 0
		counter_scale = 1.0
		is_moving_cam = false
		#current_camera.global_transform = curr_cam_original_gxform
		current_camera.transform = curr_cam_original_xform
		GlobalReferences.camera.set_mode_move()
		GlobalReferences.camera.input_shims.erase(input_shim_id)
		GlobalReferences.camera.can_call_click = true
		GlobalReferences.player.movement.can_move = true
		current_camera.fov = original_fov

func input_shim(event):
	if event is InputEventMouseButton:
		if event.pressed and counter > 0.25:
			#print("input shim")
			#var temp_cam_pos  = to_cam_pos
			#var temp_cam_gpos = to_cam_gpos
			#var temp_cam_quat = to_cam_quat
			#to_cam_pos        = from_cam_pos
			#to_cam_gpos       = from_cam_gpos
			#to_cam_quat       = from_cam_quat
			#from_cam_pos      = temp_cam_pos
			#from_cam_gpos     = temp_cam_gpos
			#from_cam_quat     = temp_cam_quat
			#counter = 1.0
			counter_scale = -1.0
			#var tween = create_tween()
			#tween.tween_property($".", "interpolate", 1, 4.0)
			#tween.chain().tween_callback(reset_curr_cam)
			is_moving_cam = true

func _process(delta: float) -> void:
	if current_camera != null:
		if is_moving_cam:
			#print(counter)
			var next_counter = counter + delta * counter_scale
			if next_counter <= counter_max:# and next_counter >= 0:
				counter = next_counter
				interpolate = smoothstep(0, 1, counter / counter_max)
			if counter < 0:
				is_moving_cam = false
				reset_curr_cam()
			else:
				var bez_1 = lerp(from_cam_gpos, bez_point_gpos, interpolate)
				var bez_2 = lerp(bez_point_gpos, to_cam_gpos, interpolate)
				var interpolated_gpos = lerp(bez_1, bez_2, interpolate)
				var interpolated_quat = from_cam_quat.slerp(to_cam_quat, interpolate)
				var new_xform = Transform3D(Basis(interpolated_quat), interpolated_gpos)
				current_camera.global_transform = new_xform
				current_camera.fov = lerp(original_fov, camera_3d.fov, interpolate)


func _on_rich_text_label_finished() -> void:
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
