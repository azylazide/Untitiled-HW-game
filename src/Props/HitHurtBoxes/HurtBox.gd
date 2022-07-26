extends Area2D
class_name HurtBox
#the area that is hazardous

var is_colliding:= false
var hitbox: HitBox

var overlapping_areas:= []

var group_to_check:= []

signal HurtBox_entered
signal HurtBox_exited

func _ready() -> void:
	connect("area_entered",self,"_on_HurtBox_area_entered")
	connect("area_exited",self,"_on_HurtBox_area_exited")

func _physics_process(delta: float) -> void:
	if is_colliding:
		if hitbox.cooldown.is_stopped():
			hitbox.apply_damage(5)

func _on_HurtBox_area_entered(area: Area2D) -> void:
	
	#get non-internal group the area is in
	var area_groups:= []
	for g in area.owner.get_groups():
		if not g.begins_with("_"):
			area_groups.push_back(g)
	
	if not is_colliding:
		hitbox = area
		is_colliding = true
	emit_signal("HurtBox_entered",area,area_groups)


func _on_HurtBox_area_exited(area: Area2D) -> void:
	emit_signal("HurtBox_exited",area)
	is_colliding = false
