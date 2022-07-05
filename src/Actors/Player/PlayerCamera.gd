extends Camera2D

var bbox_array = []
var defaults:= 10000000
var left_limit:= -defaults 
var top_limit:= -defaults 
var right_limit:= defaults 
var bottom_limit:= defaults 

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

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	
	#when intersecting
	if not bbox_array.empty():
		var left_array:= []
		var top_array:= []
		var right_array:= []
		var bottom_array:= []
		
		var priorities:= []
		
		#save limits of each area in bbox array
		for area in bbox_array:
			var collision: CollisionShape2D = area.get_node("CollisionShape2D")
			var shape: RectangleShape2D = collision.shape
			var extents: Vector2 = shape.extents
		
			left_array.append(int(collision.global_position.x-extents.x) if area.limit_left else -defaults)
			top_array.append(int(collision.global_position.y-extents.y) if area.limit_top else -defaults)
			right_array.append(int(collision.global_position.x+extents.x) if area.limit_right else -defaults)
			bottom_array.append(int(collision.global_position.y+extents.y) if area.limit_bottom else -defaults)
			
			priorities.append(area.priority_level)
		
		#find the highest priority area
		var max_priority: int = priorities.max()
		
		#set temp limits
		var temp_left: int = left_array[priorities.find(max_priority)]
		var temp_top: int = top_array[priorities.find(max_priority)]
		var temp_right: int = right_array[priorities.find(max_priority)]
		var temp_bottom: int = bottom_array[priorities.find(max_priority)]
		
		#for duplicate high priority
		if priorities.count(max_priority) > 1:
			var max_indices = []
			for i in priorities.size():
				if priorities[i] == max_priority:
					max_indices.append(i)
			
			#compare which has smaller constraint
			#and set it as new temp limit
			for i in max_indices:
				if temp_left < left_array[i]:
					temp_left = left_array[i]
				if temp_top < top_array[i]:
					temp_top = top_array[i]
				if temp_right < right_array[i]:
					temp_right = right_array[i]
				if temp_bottom < bottom_array[i]:
					temp_bottom = bottom_array[i]
		
		#set temp limit as limit
		limit_left = temp_left
		limit_top = temp_top
		limit_right = temp_right
		limit_bottom = temp_bottom
	
	else:
		#set defaults
		limit_left = left_limit
		limit_top = top_limit
		limit_right = right_limit
		limit_bottom = bottom_limit
	

func _on_CameraBBoxDetector_area_entered(area: CameraBoundBox) -> void:
	#add to array
	bbox_array.append(area)
	pass


func _on_CameraBBoxDetector_area_exited(area: CameraBoundBox) -> void:
	#remove from array
	bbox_array.erase(area)
	pass
