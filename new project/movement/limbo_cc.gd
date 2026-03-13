extends RigidBody3D

@onready var movement: LimboHSM = $Movement
@onready var camera: Node3D = $Camera
@onready var faceforward: Node3D = $Faceforward

func _physics_process(delta: float) -> void:
	movement.update(delta)

func _process(delta: float) -> void:
	faceforward.basis = camera.nodeRotate.basis
