extends StatusEffect
class_name Bleed_Effect

var damage: float

func _init() -> void:
	name = "bleed"
	maxStacks = 3
	tickTime = 2
	effectLifeTime = 10
	damage = 1

func doStackEffect():
	damage += 1

func tick():
	host.damage(damage)
