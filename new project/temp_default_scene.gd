extends Node3D

@export var levelname : String;

func _ready() -> void:
	if levelname == "": levelname = "test02"
	LevelSwitcher.level_cmd("level", ["testing/" + levelname, "0"])
