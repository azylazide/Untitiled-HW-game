extends "res://src/Actors/Player/ActionStates/Alive.gd"

func state_input(_event: InputEvent) -> void:
	.state_input(_event)
	if _event.is_action_pressed("attack")  and ["Idle","Run","GDash"].has(state_machine.observed_state):
		print("ground attack")
		state_machine.switch_states("Attack")
	if _event.is_action_pressed("attack")  and ["Jump","Fall","ADash"].has(state_machine.observed_state):
		print("aerial attack")
		state_machine.switch_states("Attack")
	if _event.is_action_pressed("attack")  and ["WallCling"].has(state_machine.observed_state):
		print("wall attack")
		state_machine.switch_states("Attack")
