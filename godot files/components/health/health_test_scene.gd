extends Node2D

@onready var hp_label: Label = $hpLabel
@onready var health: Health = $Health
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	health.addStatusEffect(Poison_Effect.new(),3)
	health.addStatusEffect(Bleed_Effect.new(),3)
	health.addStatusEffect(Panic_Effect.new(),5)
	health.addStatusEffect(ForbiddenKnowledge_Effect.new(),5)
	health.addStatusEffect(Crippled_Effect.new(),5)
	health.addStatusEffect(Manic_Effect.new(),5)

func _process(delta: float) -> void:
	hp_label.text = str(health.hp)
	status_label.text = str("status effects: ",health.statusEffects)

func _on_damage_button_pressed() -> void:
	health.damage(1)
func _on_heal_button_pressed() -> void:
	health.heal(1)
