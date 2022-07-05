extends Camera2D

var defaults:= 10000000

func _ready() -> void:
	pass


func _on_CameraBBoxDetector_area_entered(area: Area2D) -> void:
	var collision_shape: CollisionShape2D = area.get_node("CollisionShape2D")
	var extents: Vector2 = collision_shape.shape.extents
	
	limit_left = collision_shape.global_position.x-extents.x
	limit_right = collision_shape.global_position.x+extents.x
	limit_top = collision_shape.global_position.y-extents.y
	limit_bottom = collision_shape.global_position.y+extents.y
	
	pass # Replace with function body.


func _on_CameraBBoxDetector_area_exited(area: Area2D) -> void:
	var collision_shape: CollisionShape2D = area.get_node("CollisionShape2D")

	limit_left = -defaults
	limit_right = defaults
	limit_top = -defaults
	limit_bottom = defaults
