extends LimboState

@onready var camera: Node3D = $"../../Camera"

## Called once, when state is initialized.
func _setup() -> void:
	pass

## Called when state is entered.
func _enter() -> void:
	print("enter walkrun")

## Called when state is exited.
func _exit() -> void:
	print("exit walkrun")

## Called each frame when this state is active.
func _update(delta: float) -> void:
	#rotate.basis = camera.nodeRotate.basis
	if Input.is_action_pressed("run"):
		get_root().desired_velocity = get_root().wish_dir * get_root().run_velocity
	else:
		get_root().desired_velocity = get_root().wish_dir * get_root().normal_walk_velocity
	#agent.apply_central_force(wish_dir * 1000)
	if Input.is_action_just_pressed(&"jump"):
		#agent.linear_velocity *= 5
		agent.apply_central_impulse(100 * get_root().wish_dir * get_root().ground_friction + 100 * get_root().ground_normal + 200 * Vector3.UP)
		get_root().desired_velocity += get_root().wish_dir + get_root().ground_normal
	#agent.move_and_slide()
	if Input.is_action_just_pressed("climb"):
		dispatch(&"walking_ledgeclimb")
