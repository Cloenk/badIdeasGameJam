@tool
extends NotePage
class_name NotePageSelector

@export var collection: NotePageCollection:
	set(value):
		collection = value
		emit_changed()
@export var variation: int:
	set(value):
		variation = value
		emit_changed()
@export_range(0, 2, 1) var hole_count: int:
	set(value):
		hole_count = value
		emit_changed()
@export_range(0, 2, 1) var color: int:
	set(value):
		color = value
		emit_changed()

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE & PROPERTY_USAGE_INTERNAL) var setlast: bool = true:
	set(value):
		collection.connect("changed", page_changed)

func page_changed():
	emit_changed()

#func _init() -> void:
	#if collection == null:
		#await collection
	#collection.connect("changed", page_changed)

func get_page() -> NotePage:
	var selected: NotePage = collection.select_page(variation, hole_count, color)
	while selected is NotePageCollection:
		selected = selected.select_page(variation, hole_count, color)
	return selected
