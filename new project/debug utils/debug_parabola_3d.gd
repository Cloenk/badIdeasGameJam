@tool
extends Node


func draw_3points(p1: Vector3, p2: Vector3, p3: Vector3, density: int = 10, extend: float = 0.0, color: Color = Color(0, 0, 0, 1), duration: float = 0):
	density = max(5, density)
	extend = max(0, extend)
	var t_start: float = -1 - extend
	var t_end: float = 1 + extend
	var points: PackedVector3Array
	points.resize(density * (1 + extend))
	#print("parabola point count: ", points.size())
	for i in range(0, density):
		var t: float = lerp(t_start, t_end, float(i) / float(density - 1))
		points[i] = t * t * ((p1 + p3) / 2.0 - p2) + 0.5 * t * (p3 - p1) + p2
	DebugDraw3D.draw_line_path(points, color, duration)

func draw_coefs(c1: float, cx: float, cx2: float, density: int = 10, min_x: float = 0.0, max_x: float = 2.0, xform: Transform3D = Transform3D.IDENTITY, color: Color = Color(0, 0, 0, 1), duration: float = 0):
	density = max(5, density)
	var sort_lo: float = min(min_x, max_x)
	var sort_hi: float = max(min_x, max_x)
	min_x = sort_lo
	max_x = sort_hi
	var points: PackedVector3Array
	points.resize(density * 0.5 * (max_x - min_x))
	#print("parabola point count: ", points.size())
	for i in range(0, density):
		var x: float = lerp(min_x, max_x, float(i) / float(density - 1))
		points[i] = Vector3(0, c1 + x * cx + x * x * cx2, -x) * xform
	DebugDraw3D.draw_line_path(points, color, duration)
