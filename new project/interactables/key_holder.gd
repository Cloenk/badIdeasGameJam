extends Node


var keys: Dictionary[String, Key]

func add_key(name: String, value: Key):
	if keys.has(name):
		keys[name] = value.replace(keys[name].value)
	else:
		keys[name] = value.replace(0)

func has_key(name: String) -> bool:
	return keys.has(name)

func get_key_value_or_0(name: String) -> int:
	if keys.has(name):
		return keys[name].value
	else:
		return 0

func clear_key(name: String):
	keys[name] = Key.new()

func delete_key(name: String):
	keys.erase(name)
