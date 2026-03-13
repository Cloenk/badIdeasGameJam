extends Node


func level_cmd(cmd_name: String, args: PackedStringArray):
	if cmd_name == "level":
		if !args.size():
			GsomConsole.log("The current scene is '[b]%s[/b]'." % [
				GsomConsole.__color(GsomConsole.COLOR_VALUE, GsomConsole.get_tree().current_scene.scene_file_path),
			])
			return
		
		# `map [name]` syntax below
		var map_name: String = "res://levels/" + args[0]
		if !ResourceLoader.exists(map_name):
			map_name += ".tscn"
		if !ResourceLoader.exists(map_name):
			GsomConsole.error("Level '[b]%s[/b]' doesn't exist." % GsomConsole.__color(GsomConsole.COLOR_ERROR, args[0]))
			return
		
		GsomConsole.log("Loading level '[b]%s[/b]'..." % GsomConsole.__color(Color("34d6a9ff").to_html(), map_name))
		
		GsomConsole.get_tree().change_scene_to_file(map_name)
		# if post processing is implemented, may need to change this to queue_free()-ing and then add_child(scene.instantiate())-ing
		
		await GsomConsole.get_tree().scene_changed
		#consider making a dedicated command for this
		var spawns = GsomConsole.get_tree().get_nodes_in_group("Spawnpoint")
		var spawn_index = 0
		if args.size() > 1:
			spawn_index = args[1].to_int()
		spawn_index = min(spawn_index, len(spawns))
		var character = load("res://movement/limbo_cc.tscn").instantiate()
		GsomConsole.get_tree().current_scene.add_child(character)
		character.position = spawns[0].position
		
		GsomConsole.hide()


func _ready() -> void:
	GsomConsole.called_cmd.connect(level_cmd)
	GsomConsole.register_cmd("level", "Loads a level and spawns the player at the selected spawn point.")
