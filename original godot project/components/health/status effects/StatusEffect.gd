extends Resource
class_name StatusEffect

var host: Health
var name: String = "StatusName"
var maxStacks: int = 5
var stacks: int = 1
var tickTime: float = 0 #leave at 0 for no ticking
var tickTimer: Timer
var effectLifeTime: float = 5 #leave at 0 for inf lifetime
var lifetimeTimer: Timer

func apply():
	#apply the effect
	if tickTime != 0:
		tickTimer = Timer.new()
		host.add_child(tickTimer)
		tickTimer.one_shot = false
		tickTimer.timeout.connect(tick)
		tickTimer.start(tickTime)
	if effectLifeTime != 0:
		lifetimeTimer = Timer.new()
		host.add_child(lifetimeTimer)
		lifetimeTimer.timeout.connect(host.removeStatusEffect.bind(self))
		lifetimeTimer.start(effectLifeTime)

func stack():
	#this will be called instead of apply when the status effect is already applied to an object
	if stacks < maxStacks:
		stacks += 1
		doStackEffect()
	if effectLifeTime != 0:
		lifetimeTimer.start(effectLifeTime)

func doStackEffect():
	#do the actual effect of stacking
	pass

func tick():
	#do something
	pass

func removeStack():
	#remove a stack of the effect
	if effectLifeTime != 0:
		stacks -= 1
		lifetimeTimer.start(effectLifeTime)

func remove():
	#remove the effect
	if is_instance_valid(tickTimer):
		tickTimer.queue_free()
	if is_instance_valid(lifetimeTimer):
		lifetimeTimer.queue_free()

func _to_string() -> String:
	return str(name," ",stacks)
