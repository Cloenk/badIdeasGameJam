extends Node3D


func _ready() -> void:
	LevelSwitcher.level_cmd("level", ["testing/test02", "0"])
