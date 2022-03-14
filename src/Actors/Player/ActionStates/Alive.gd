extends State

func state_input(_event: InputEvent) -> void:
	#debug
	if _event.is_action_pressed("ui_cancel"):
		state_machine.switch_states("Death")
