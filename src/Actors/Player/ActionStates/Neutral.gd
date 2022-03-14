extends "res://src/Actors/Player/ActionStates/Alive.gd"

func state_input(_event: InputEvent) -> void:
	.state_input(_event)
	if _event.is_action_pressed("attack"):
		state_machine.switch_states("Attack")
