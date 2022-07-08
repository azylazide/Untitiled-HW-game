extends GameManager

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_kill"):
		$DebugLevel/Player.queue_free()
	pass
