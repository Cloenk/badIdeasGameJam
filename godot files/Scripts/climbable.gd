extends Area2D

@export var player = CharacterBody2D;

signal player_entered_area;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent().find_child("Player")
	pass # Replace with function body.
	
