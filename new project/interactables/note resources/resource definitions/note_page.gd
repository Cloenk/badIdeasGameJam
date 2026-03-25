@tool
extends Resource
class_name NotePage

## ID, Repeat. only the first 8 will be sent to the shader.
@export var lines: Array[Vector2i]:
	set(value):
		lines = value
		emit_changed()
@export var page_size: Vector2i = Vector2i(11, 15):
	set(value):
		page_size = value
		emit_changed()
@export var loop_lines: bool = false:
	set(value):
		loop_lines = value
		emit_changed()


static func from_separate(lines: Array[int], repeats: Array[int], use: int, width: int, height: int, loop: bool) -> NotePage:
	var res: NotePage = NotePage.new()
	res.lines = []
	for i in range(0, min(8, use, len(lines), len(repeats))):
		res.lines.append(Vector2i(lines[i], repeats[i]))
	res.page_size = Vector2i(width, height)
	res.loop_lines = loop
	return res

func get_page() -> NotePage:
	return self

func to_separate() -> Array:
	var res = [[], [], 0, 0, 0, self.loop_lines]
	for i in range(0, 8):
		res[0].append(0)
		res[1].append(0)
	for i in range(0, len(self.lines)):
		var pair = self.lines[i]
		res[0][i] = pair.x
		res[1][i] = pair.y
	res[2] = len(self.lines)
	res[3] = self.page_size.x
	res[4] = self.page_size.y
	return res
