@tool
extends NotePage
class_name NotePageCollection


@export var pages: Array[NotePage]:
	set(value):
		pages = value
		emit_changed()
enum NotePageCollectionMode {Variations, HoleCount, LineColor}
@export var list_mode: NotePageCollectionMode = NotePageCollectionMode.Variations:
	set(value):
		list_mode = value
		emit_changed()

func page_changed():
	emit_changed()

func _init() -> void:
	for page in pages:
		page.connect("changed", page_changed)


static func oneoff(page: NotePage) -> NotePageCollection:
	var res: NotePageCollection = NotePageCollection.new()
	res.pages = [page]
	res.list_mode = NotePageCollection.NotePageCollectionMode.Variations
	return res

static func variations(pages: Array[NotePage]) -> NotePageCollection:
	var res: NotePageCollection = NotePageCollection.new()
	res.pages = pages
	res.list_mode = NotePageCollection.NotePageCollectionMode.Variations
	return res

static func holes(pages: Array[NotePage]) -> NotePageCollection:
	var res: NotePageCollection = NotePageCollection.new()
	res.pages = pages
	res.list_mode = NotePageCollection.NotePageCollectionMode.HoleCount
	return res

static func colors(pages: Array[NotePage]) -> NotePageCollection:
	var res: NotePageCollection = NotePageCollection.new()
	res.pages = pages
	res.list_mode = NotePageCollection.NotePageCollectionMode.LineColor
	return res

func get_page() -> NotePage:
	return pages[0]

func select_page(var_idx: int, hole_count: int, line_color: int) -> NotePage:
	match list_mode:
		NotePageCollectionMode.Variations:
			return pages[clamp(var_idx, 0, len(pages))]
		NotePageCollectionMode.HoleCount:
			return pages[clamp(hole_count, 0, len(pages))]
		NotePageCollectionMode.LineColor:
			return pages[clamp(line_color, 0, len(pages))]
	return NotePage.new()

static func basic_page(top: int, hole: int, middle: int) -> NotePageCollection:
	return NotePageCollection.holes([
		NotePage.from_separate([top, middle, middle, middle, middle, middle, middle, middle], [1, 1, 1, 1, 1, 1, 1, 1], 2, 11, 15, false),
		NotePage.from_separate([top, middle, hole, middle, hole, middle, middle, middle], [1, 2, 1, 7, 1, 1, 1, 1], 6, 11, 15, false),
		NotePage.from_separate([top, middle, hole, middle, hole, middle, hole, middle], [1, 1, 1, 4, 1, 4, 1, 1], 8, 11, 15, false)
	])

static func alternating_page(a: int, b: int, num_a: int, num_b: int, width: int, height: int) -> NotePageCollection:
	return NotePageCollection.variations([
		NotePage.from_separate([a, b, a, b, a, b, a, b], [num_a, num_b, 1, 1, 1, 1, 1, 1], 2, width, height, true),
		NotePage.from_separate([b, a, b, a, b, a, b, a], [num_b, num_a, 1, 1, 1, 1, 1, 1], 2, width, height, true)
	])
