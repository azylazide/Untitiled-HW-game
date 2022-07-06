extends Node2D
class_name CustomCam

export(NodePath) var player_path
onready var player_node: ActorBase = get_node(player_path)
onready var screen_size: Vector2 = get_viewport().get_visible_rect().size

export(Vector2) var offset = Vector2.ZERO

var bbox_array = []

func _ready() -> void:
	player_node.camera_bbox_detector.connect("area_entered",self,"on_CameraBBoxDetector_area_entered")
	player_node.camera_bbox_detector.connect("area_exited",self,"on_CameraBBoxDetector_area_exited")

	var canvas_transform: Transform2D = get_viewport().canvas_transform
	canvas_transform.origin = -player_node.global_position + screen_size/2
	get_viewport().canvas_transform = canvas_transform

	pass

func _process(delta: float) -> void:
	var canvas_transform: Transform2D = get_viewport().canvas_transform
	canvas_transform.origin = -player_node.global_position + screen_size/2
	
	#clamp cam at edges when in bounds
	
	get_viewport().canvas_transform = canvas_transform
	pass

func _get_bounds(delta: float) -> void:
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
		
			pass
			
#			left_array.append(int(collision.global_position.x-extents.x) if area.limit_left else left_limit)
#			top_array.append(int(collision.global_position.y-extents.y) if area.limit_top else top_limit)
#			right_array.append(int(collision.global_position.x+extents.x) if area.limit_right else right_limit)
#			bottom_array.append(int(collision.global_position.y+extents.y) if area.limit_bottom else bottom_limit)
			
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
#		limit_left = temp_left
#		limit_top = temp_top
#		limit_right = temp_right
#		limit_bottom = temp_bottom
		
		pass
		
	else:
		#set defaults
#		limit_left = left_limit
#		limit_top = top_limit
#		limit_right = right_limit
#		limit_bottom = bottom_limit
		
		pass

func on_CameraBBoxDetector_area_entered(area: Area2D):
	print("enter")
	pass

func on_CameraBBoxDetector_area_exited(area: Area2D):
	print("exit")
	pass
