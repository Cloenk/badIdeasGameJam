extends StatusEffect
class_name Panic_Effect

var damage: float

func _init() -> void:
	name = "panic"
	maxStacks = 5
	tickTime = 2
	effectLifeTime = 10
	damage = 0.5

func doStackEffect():
	damage += 0.5

func tick():
	host.reduceSanity(damage)
