extends Area3D

@export var playerbody : RigidBody3D;
var contains_player_body = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if get_overlapping_bodies().has(playerbody):
		if !contains_player_body:
			body_entered.emit();
			contains_player_body = true;
	else:
		if contains_player_body:
			contains_player_body = false;
			body_exited.emit();
	pass
