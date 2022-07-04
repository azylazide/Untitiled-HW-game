extends Resource
class_name PlayerStats

export(float) var health = 100 setget set_health

enum ABILITIES {DASH,DJUMP,WALLCLIMB}
var ability_list = []

func set_health(new_val: float) -> void:
	health = clamp(new_val, 0, 100)
