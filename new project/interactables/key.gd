extends Resource
class_name Key


@export var value: int
enum ReplaceMode {Replace, Max, Min, Add, Subtract, SubtractRev, Multiply, MultiplyIfNotZero, Divide, Blend}
@export var replace_mode: ReplaceMode = ReplaceMode.Replace
@export var blend_fac: float

func replace(old: int) -> Key:
	var newval = 0
	match replace_mode:
		ReplaceMode.Replace:
			newval = value
		ReplaceMode.Max:
			newval = max(old, value)
		ReplaceMode.Min:
			newval = min(old, value)
		ReplaceMode.Add:
			newval = old + value
		ReplaceMode.Subtract:
			newval = old - value
		ReplaceMode.SubtractRev:
			newval = value - old
		ReplaceMode.Multiply:
			newval = old * value
		ReplaceMode.MultiplyIfNotZero:
			if old != 0:
				newval = old * value
			else:
				newval = value
		ReplaceMode.Divide:
			if value != 0:
				newval = int(round(float(old) / float(value)))
			else:
				newval = 0
		ReplaceMode.Blend:
			newval = lerp(old, value, blend_fac)
	var res = Key.new()
	res.value = newval
	res.replace_mode = self.replace_mode
	res.blend_fac = self.blend_fac
	return res
