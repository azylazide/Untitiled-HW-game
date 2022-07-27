extends Area2D
class_name HitBox
#The area that receives damage
#Detected by hurtboxes

export(float) var cooldown_time:= 1.2
onready var cooldown:= $Cooldown

func _ready() -> void:
	cooldown.wait_time = cooldown_time
	pass

func apply_damage(amount: float) -> void:
	if owner.has_method("damage"):
		cooldown.start()
		owner.damage(amount)
	pass
