extends StateMachine


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	owner.get_node("VBoxContainer/Label11").text = "Action state: " + current_state.name
	._process(delta)
