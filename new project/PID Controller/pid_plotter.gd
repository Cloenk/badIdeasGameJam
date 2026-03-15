extends Node2D

@onready var line_2d: Line2D = $Line2D
@onready var line_2d2: Line2D = $Line2D2
@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var timer: Timer = $Timer
@onready var animatable_body_2d: AnimatableBody2D = $"physics scene/AnimatableBody2D"
@onready var ball: RigidBody2D = $"physics scene/RigidBody2D"

@export var pid: PIDController

var data: Array[float]
var data2: Array[float]
var target := 0.0


func _ready() -> void:
	print(data.resize(512))
	print(data.size())
	print(line_2d.points.resize(512))
	print(line_2d.points.size())
	print(data2.resize(512))
	print(data2.size())
	print(line_2d2.points.resize(512))
	print(line_2d2.points.size())
	timer.start()
	randomize()


func _on_timer_timeout() -> void:
	target = randf_range(-0.5, 0.5)
	var tween = get_tree().create_tween()
	tween.tween_property(animatable_body_2d, "rotation_degrees", randf_range(-80, 80), 1.0)
	timer.wait_time = randf_range(0.5, 3)

func _physics_process(delta: float) -> void:
	#if randf() > 0.99:
	var new_value = pid.update_1d(ball.position.y/360 - 1, delta)
	ball.apply_central_force(Vector2(1500 * new_value, 0))
	#print(new_value)
	data.push_back(clamp(1 - ball.position.y/360, -1, 1))
	data.pop_front()
	data2.push_back(clamp(new_value, -1, 1))
	data2.pop_front()
	#polygon_2d.position.y = (-target * 0.5 + 0.5) * 720
	for i in range(0, 512):
		line_2d.points[i] = Vector2(i * 2.5, (-data[i] * 0.5 + 0.5) * 720)
		line_2d2.points[i] = Vector2(i * 2.5, (-data2[i] * 0.5 + 0.5) * 720)
