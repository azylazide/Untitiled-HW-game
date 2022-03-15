extends "res://src/Actors/Player/ActionStates/Alive.gd"

signal player_fired

func enter(_prev_info:={}) -> void:
	var spawner: Vector2 = owner.arrow_spawn.global_position
	emit_signal("player_fired", spawner)

func state_input(_event: InputEvent) -> void:
	.state_input(_event)
	if _event.is_action_released("attack"):
		state_machine.switch_states("Neutral")
