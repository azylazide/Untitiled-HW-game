extends Node

var pause:= false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_pause"):
		get_tree().paused = true
	if event.is_action_released("debug_pause"):
		get_tree().paused = false
