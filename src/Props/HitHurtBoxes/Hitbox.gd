extends Area2D
class_name HitBox
#The area that receives damage

export(float) var cooldown_time:= 1.2
onready var cooldown:= $Cooldown

func _ready() -> void:
	cooldown.wait_time = cooldown_time
	pass

func apply_damage(amount: float) -> void:
	cooldown.start()
	owner.damage(amount)
	pass
