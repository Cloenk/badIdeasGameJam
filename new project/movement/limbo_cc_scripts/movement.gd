extends LimboHSM

@onready var charbody: RigidBody3D = $".."
@onready var camera: Node3D = $"../Camera"

@onready var idle: LimboState = $Idle
@onready var walk_run: LimboState = $WalkRun
@onready var crouch: LimboState = $Crouch
@onready var crawl: LimboState = $Crawl
@onready var wall_sneak: LimboState = $WallSneak
@onready var wall_sneak_crouch: LimboState = $WallSneakCrouch
@onready var hang_move: LimboState = $HangMove

@onready var freefall: LimboState = $Freefall
@onready var glide: LimboState = $Glide

@onready var fall_land: LimboState = $FallLand

@onready var ledge_climb: LimboState = $LedgeClimb

@export_category("PID")
var desired_velocity: Vector3
var desired_air_velocity: Vector3
@export var limit_fall_velocity: float = -1
@export var lateral_force_max: float = 2000
@export var lateral_force_pass: float = 500
@export var scale_pid_velo: float = 1000
@export var pid_velocity: PIDController = PIDController.new_pid(2, 0.1, 0.5, 2, 0.1)
#@export_range(0.001, 1, 0.001, "exp") var reduced_error_when_slowing_down: float = 0.25

@export_category("speeds")
@export var normal_walk_velocity: float = 1.75 # a little under 4 mph
@export var slow_walk_velocity: float = 1 # a little over 2 mph
@export var run_velocity: float = 3.5 # a little under 8 mph
@export var sprint_velocity: float = 7 # a little under 16 mph

## Normal ready function.
func _ready() -> void:
	add_transition(walk_run, crouch, &"crouch")
	add_transition(crouch, walk_run, &"uncrouch")
	add_transition(crouch, crawl, &"crawl")
	add_transition(crawl, crouch, &"uncrawl")
	add_transition(wall_sneak, wall_sneak_crouch, &"crouch")
	add_transition(wall_sneak_crouch, wall_sneak, &"uncrouch")
	add_transition(walk_run, wall_sneak, &"wall")
	add_transition(wall_sneak, walk_run, &"unwall")
	add_transition(crouch, wall_sneak_crouch, &"wall")
	add_transition(wall_sneak_crouch, crouch, &"unwall")
	add_transition(walk_run, hang_move, &"hang")
	add_transition(hang_move, walk_run, &"unhang")
	add_transition(walk_run, idle, &"idle")
	add_transition(idle, walk_run, &"unidle")
	
	add_transition(ANYSTATE, freefall, &"fall")
	add_transition(freefall, glide, &"glide")
	
	add_transition(freefall, fall_land, &"land")
	add_transition(glide, fall_land, &"land")
	
	add_transition(fall_land, idle, &"standup_idle")
	add_transition(fall_land, walk_run, &"standup_walk")
	add_transition(fall_land, crouch, &"standup_crouch")
	add_transition(fall_land, crawl, &"standup_crawl")
	
	add_transition(walk_run, ledge_climb, &"walking_ledgeclimb")
	add_transition(ledge_climb, walk_run, &"ledgeclimb_finish")
	
	initial_state = walk_run
	initialize(charbody)
	set_active(true)
	print("ready main")

## Called once, when state is initialized.
func _setup() -> void:
	pass

## Called when state is entered.
func _enter() -> void:
	print("enter main")

## Called when state is exited.
func _exit() -> void:
	print("exit main")

func smooth_force_clamp(vec: Vector3, mag_pass: float, mag_max: float) -> Vector3:
	if vec.length() < mag_pass:
		return vec
	else:
		var length = vec.length()
		var mag_diff = mag_max - mag_pass
		var len01 = (length - mag_pass) / mag_diff
		var clamp01 = 1.0 - 1.0 / (len01 + 1.0)
		return (clamp01 * mag_diff + mag_pass) * vec.normalized()

func reduced_error_when_going_too_fast(vel_want: Vector3, vel_is: Vector3, m: float) -> Vector3:
	var error = vel_want - vel_is
	return error# * Vector3(1, 0, 1)
	var i_norm = vel_is.normalized()
	var side = i_norm.dot(error)
	if side >= 0: # if going slower than desired, use normal error
		return error
	var inline = i_norm * side
	return (error - inline) + m * inline

var is_on_ground: bool
var ground_normal: Vector3
var ground_velocity: Vector3
var ground_friction: float

func _process(delta: float) -> void:
	DebugDraw3D.draw_arrow(camera.hold_position.global_position, camera.hold_position.global_position + ground_normal, Color.DARK_GOLDENROD, 0.2, true)
	DebugDraw3D.draw_arrow(camera.hold_position.global_position, camera.hold_position.global_position + ground_velocity, Color.MEDIUM_AQUAMARINE, 0.2, true)

func update_ground_state(delta: float) -> void:
	if is_on_ground:
		var state: PhysicsDirectBodyState3D = PhysicsServer3D.body_get_direct_state(charbody.get_rid())
		var temp_normal: Vector3
		var temp_velocity: Vector3
		var ground_count: int = 0
		for i in state.get_contact_count():
			var local_normal = state.get_contact_local_normal(i)
			if local_normal.angle_to(Vector3.UP) < deg_to_rad(50):
				ground_count += 1
				temp_normal += local_normal
				temp_velocity += state.get_contact_local_velocity_at_position(i)
		if ground_count > 0:
			ground_normal = ground_normal.lerp(temp_normal.normalized(), 0.2).normalized()
			ground_velocity = ground_velocity.slerp(ground_velocity / ground_count, 0.2)
	else:
		ground_normal = ground_normal.lerp(Vector3.UP, 0.2).normalized()
		ground_velocity = ground_velocity.slerp(Vector3.ZERO, 0.2)


func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if local_shape_index == 1:
		if body is RigidBody3D or body is StaticBody3D:
			if body.physics_material_override != null:
				ground_friction = body.physics_material_override.friction
				#print(ground_friction)
			else:
				ground_friction = 1
		if body is CSGShape3D:
			ground_friction = 1
			#print("csg, defaulting to ", ground_friction)
		is_on_ground = true
		#print("touch ground")

func _on_body_shape_exited(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if local_shape_index == 1:
		#print(get_contact_count())
		if charbody.get_contact_count() == 0:
			ground_friction = 0.1
			is_on_ground = false
		#print("leave ground")

func is_on_floor() -> bool:
	return is_on_ground

var was_previously_on_floor: bool = true
var wish_dir
## Called each frame when this state is active.
func _update(delta: float) -> void:
	update_ground_state(delta)
	var input_dir: Vector2 = Input.get_vector(&"left", &"right", &"up", &"down").normalized()
	wish_dir = camera.nodeRotate.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	if not is_on_ground:
		#print("not on floor")
		if was_previously_on_floor:
			dispatch(&"fall")
		was_previously_on_floor = false
	else:
		#print("on floor")
		if not was_previously_on_floor:
			pid_velocity.reset_3d()
			dispatch(&"land")
		was_previously_on_floor = true
		var pid_velo_output: Vector3 = pid_velocity.update_3d(desired_velocity - charbody.linear_velocity, delta)
		pid_velo_output = smooth_force_clamp(pid_velo_output * scale_pid_velo, lateral_force_pass, lateral_force_max)
		charbody.apply_central_force(pid_velo_output * ground_friction)
	#print(charbody.linear_velocity)
