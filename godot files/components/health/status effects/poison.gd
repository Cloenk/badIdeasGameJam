extends StatusEffect
class_name Poison_Effect

var damagePercent: float

func _init() -> void:
	name = "poison"
	maxStacks = 3
	tickTime = 1
	damagePercent = 0.05

func doStackEffect():
	damagePercent += 0.05

func removeStack():
	super()
	damagePercent -= 0.05

func tick():
	host.damage(host.maxHp * damagePercent)
