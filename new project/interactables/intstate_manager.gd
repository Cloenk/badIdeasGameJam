extends Node


var keys: Dictionary[String, IntState]

func set_key(name: String, value: IntState):
	if keys.has(name):
		keys[name] = value.replace(keys[name].value)
	else:
		keys[name] = value.replace(0)

func has_key(name: String) -> bool:
	return keys.has(name)

func key_above_zero(name: String) -> bool:
	if keys.has(name):
		return keys[name].value > 0
	else:
		return false

func get_key_value_or_0(name: String) -> int:
	if keys.has(name):
		return keys[name].value
	else:
		return 0

func clear_key(name: String):
	keys[name] = IntState.new()

func delete_key(name: String):
	keys.erase(name)
