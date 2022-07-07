extends Area2D

onready var cooldown:= $Cooldown

func _ready() -> void:
	pass

func apply_damage(amount: float) -> void:
	cooldown.start()
	owner.damage(amount)
	pass
