extends LimboState

## Called once, when state is initialized.
func _setup() -> void:
	pass

## Called when state is entered.
func _enter() -> void:
	print("enter crawl")

## Called when state is exited.
func _exit() -> void:
	print("exit crawl")

## Called each frame when this state is active.
func _update(delta: float) -> void:
	pass
