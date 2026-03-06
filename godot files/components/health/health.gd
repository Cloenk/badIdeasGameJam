extends Node2D
class_name Health

@export var maxHp: float = 10
@export var damageTakenMultipler: float = 1
@export var healMultiplier: float = 1
@export var maxSanity: float = 10
@export var sanityReductionMultiplier: float = 1
@export var sanityAdditionMultiplier: float = 1

var hp: float = 0
var sanity: float = 0
var statusEffects: Array[StatusEffect]

func _ready() -> void:
	#set the hp and sanity to their max
	hp = maxHp
	sanity = maxSanity

func damage(amount: float): #damages the thingymajig
	amount *= damageTakenMultipler
	hp -= amount
	if hp <= 0:
		die()

func heal(amount: float): #your not gonna believe what this one does
	amount *= healMultiplier
	hp += amount
	if hp > maxHp:
		hp = maxHp

func die():
	#ded
	pass

func reduceSanity(amount: float): #same as damages but with sanity
	amount *= sanityReductionMultiplier
	sanity -= amount
	if sanity <= 0:
		#do something
		pass

func addSanity(amount: float): #same as heal but with sanity :o
	amount *= sanityAdditionMultiplier
	maxSanity += amount
	if maxSanity > maxSanity:
		maxSanity = maxSanity

func addStatusEffect(statusEffect: StatusEffect,stackAmount: float):
	for a in stackAmount:
		var existingEffect: StatusEffect
		for effect in statusEffects:
			if effect.name == statusEffect.name:
				existingEffect = effect
		if existingEffect:
			existingEffect.stack()
		else:
			statusEffects.append(statusEffect)
			statusEffect.host = self
			statusEffect.apply()

func removeStatusEffect(statusEffect: StatusEffect):
	statusEffect.remove()
	statusEffects.erase(statusEffect)
