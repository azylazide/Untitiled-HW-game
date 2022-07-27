extends Area2D
class_name HurtBox
#the area that is hazardous
#detects hitboxes

export(float) var damage = 5

var is_colliding:= false
var hitbox: HitBox

var overlapping_areas:= []

export(Array, String) var group_to_check

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	#basic damage logic
	if not overlapping_areas.empty():
		for hb in overlapping_areas:
			if hb.has_method("apply_damage"):
				if hb.has_node("Cooldown"):
					if hb.cooldown.is_stopped():
						hb.apply_damage(damage)
				else:
					hb.apply_damage(damage)
		
func _on_HurtBox_area_entered(area: Area2D) -> void:
	if group_to_check.empty():
		return
	
	#get non-internal group the area is in
	var area_groups:= []
	for g in area.owner.get_groups():
		if not g.begins_with("_"):
			area_groups.append(g)
	
	for g in area_groups:
		if group_to_check.has(g):
			overlapping_areas.append(area)
			break


func _on_HurtBox_area_exited(area: Area2D) -> void:
	#erases hb stored in overlap (silently fails when not found)
	overlapping_areas.erase(area)
