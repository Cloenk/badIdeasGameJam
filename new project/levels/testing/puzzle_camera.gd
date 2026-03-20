extends Camera3D

var player_in_area = false;
var previouscam = null;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_in_area:
		if Input.is_action_just_pressed(&"interact"):
			if !current:
				var viewport = get_viewport();
				previouscam = viewport.get_camera_3d();
				make_current();
			else:
				current = false;
				previouscam.current = true;
	pass


func _on_puzzle_activation_area_body_entered(body: Node3D) -> void:
	print(body)
	pass # Replace with function body.


func _on_puzzle_activation_area_body_exited(body: Node3D) -> void:
	print(body)
	pass # Replace with function body.
