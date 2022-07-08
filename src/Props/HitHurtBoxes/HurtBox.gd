extends Area2D
class_name HurtBox
#the area that is hazardous

var is_colliding:= false
var hitbox: HitBox

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if is_colliding:
		if hitbox.cooldown.is_stopped():
			hitbox.apply_damage(5)

func _on_HurtBox_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("Player"):
		hitbox = area
		is_colliding = true


func _on_HurtBox_area_exited(area: Area2D) -> void:
	is_colliding = false
