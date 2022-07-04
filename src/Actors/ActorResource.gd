extends Resource
class_name ActorResource

export(float) var health = 100 setget set_health

func set_health(new_val: float) -> void:
	health = clamp(new_val, 0, 100)
