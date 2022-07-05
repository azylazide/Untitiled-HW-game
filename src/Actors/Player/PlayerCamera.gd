extends Camera2D
#Requirements
#When idle
# player is near center of screen but camera biased to their facing by a subtle offset

#Up -> fixed camera interp
#Down -> almost a snap
#left/right -> slow for idle and wall jump, and fast for dashes

#Area2D as actor bounds

#"logic"
#
#put player in the center of the screen + left right bias
#flip bias by multiplying left/right with -1 based on face direction
#bias for down is arbitrary?
#	

#the bounds:
#	the camera looks at an array of bounds it has
#	bbox adds itself to the array when overlapping and removes itself when done
#		update the camera bounds
#

#bridge or boundary:
#	if boundary
#		limit is bounds of bbox
#	if bridge 
#		some limit is infinite in a specified direction of that bbox
#
#Note some boundaries are only for some direction

#Have bbox have a hierarchy of priority (bridges are higher)

#update loop
#	for every bbox in array
#		save bounds of the given direction (else infinite)
#		prioritize the boundary of bbox of higher priority
#		if same priority, prioritize the more constraining bbox
#
#	set the bounds

#lerps
#	vertical:
#	if the player is higher on the screen and falling
#		fast lerp
#	else smooth
#
#	horizontal:
#	if the player is too far from camera
#		snap
#	when idle
#		slow
#	when moving
#		faster
#	when walljump
#		first few secs of the wallkick, lerp is slow

var defaults:= 10000000

func _ready() -> void:
	pass


func _on_CameraBBoxDetector_area_entered(area: Area2D) -> void:
	var collision_shape: CollisionShape2D = area.get_node("CollisionShape2D")
	var extents: Vector2 = collision_shape.shape.extents
	
	limit_left = int(collision_shape.global_position.x-extents.x)
	limit_right = int(collision_shape.global_position.x+extents.x)
	limit_top = int(collision_shape.global_position.y-extents.y)
	limit_bottom = int(collision_shape.global_position.y+extents.y)
	
	pass # Replace with function body.


func _on_CameraBBoxDetector_area_exited(area: Area2D) -> void:
#	var collision_shape: CollisionShape2D = area.get_node("CollisionShape2D")

	limit_left = -defaults
	limit_right = defaults
	limit_top = -defaults
	limit_bottom = defaults
