extends Node2D
class_name CustomCam

export(NodePath) var player_path
onready var player_node: ActorBase = get_node(player_path)
onready var screen_size: Vector2 = get_viewport().get_visible_rect().size

export(float) var x_offset_tiles = 0.8
export(float) var down_bias_tiles = 0.8

export(float,0,1) var IDLE_SMOOTHING = 0.2
export(float,0,1) var WALK_SMOOTHING = 0.6
export(float,0,1) var JUMP_SMOOTHING = 0.1

onready var x_offset: float = x_offset_tiles*Globals.TILE_UNITS
onready var down_offset: float = down_bias_tiles*Globals.TILE_UNITS
onready var current_offset:= Vector2(x_offset,0)

var bbox_array = []
var bridge_inf:= 10000000

func _ready() -> void:
	#connect the detector to camera
	player_node.camera_bbox_detector.connect("area_entered",self,"on_CameraBBoxDetector_area_entered")
	player_node.camera_bbox_detector.connect("area_exited",self,"on_CameraBBoxDetector_area_exited")
	
	var canvas_transform: Transform2D = get_viewport().canvas_transform
	var new_transform:= _update_transform(canvas_transform)
	
	#apply camera
	get_viewport().canvas_transform = new_transform

	pass

func _physics_process(delta: float) -> void:

	var canvas_transform: Transform2D = get_viewport().canvas_transform
	var new_transform:= _update_transform(canvas_transform)
	#clamp cam at edges when in bounds
	new_transform = _clamp_on_bounds(new_transform)
	#apply camera
	get_viewport().canvas_transform = new_transform
	pass

func _update_transform(canvas_transform: Transform2D) -> Transform2D:
	var face_dir: float = player_node.face_direction
		
	var player_movement_state: int = player_node.current_movement_state
	
	canvas_transform.origin = _new_canvas_transform(canvas_transform.origin,
													player_node.global_position,
													screen_size,
													face_dir,
													player_movement_state)

	return canvas_transform

func _clamp_on_bounds(transform: Transform2D) -> Transform2D:
	var old_transform:= get_viewport().canvas_transform
	var old_origin:= old_transform.origin
	var left_limit:= -bridge_inf
	var top_limit:= -bridge_inf
	var right_limit:= bridge_inf
	var bottom_limit:= bridge_inf
	
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
			
			left_array.append(int(collision.global_position.x-extents.x) if area.limit_left else left_limit)
			top_array.append(int(collision.global_position.y-extents.y) if area.limit_top else top_limit)
			right_array.append(int(collision.global_position.x+extents.x) if area.limit_right else right_limit)
			bottom_array.append(int(collision.global_position.y+extents.y) if area.limit_bottom else bottom_limit)
			
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
				if abs(temp_left) < abs(left_array[i]):
					temp_left = left_array[i]
				if abs(temp_top) < abs(top_array[i]):
					temp_top = top_array[i]
				if abs(temp_right) < abs(right_array[i]):
					temp_right = right_array[i]
				if abs(temp_bottom) < abs(bottom_array[i]):
					temp_bottom = bottom_array[i]
		
		#set temp limit as limit
		#NOTE: -left/top edge is max; -right/bottom+screen is min
		transform.origin.x = clamp(transform.origin.x,
									-temp_right+screen_size.x,
									-temp_left)
		transform.origin.y = clamp(transform.origin.y,
									-temp_bottom+screen_size.y,
									-temp_top)
#		print("L: %f, R: %f\nT: %f, B: %f\nCamera: (%f,%f)" 
#				%[temp_left,
#					temp_right,
#					temp_top,
#					temp_bottom,
#					transform.origin.x,
#					transform.origin.y])
		pass
		
	else:
		#set defaults
		#NOTE: -left/top edge is max; -right/bottom+screen is min
		transform.origin.x = clamp(transform.origin.x,
									-bridge_inf,
									bridge_inf)
		transform.origin.y = clamp(transform.origin.y,
									-bridge_inf,
									bridge_inf)
#		print("Camera: (%f,%f)" %[transform.origin.x,
#								transform.origin.y])
		
		pass
	return transform

#might be a problem when detectors fire before camera is ready
func on_CameraBBoxDetector_area_entered(area: Area2D):
	bbox_array.append(area)
	pass

func on_CameraBBoxDetector_area_exited(area: Area2D):
	bbox_array.erase(area)
	pass

func _get_offset(current_offset: Vector2, face_dir: float, is_down: bool) -> Vector2:
	var y_offset:= 0.0
	if is_down:
		y_offset = down_offset
	
	return Vector2.ZERO
	
	if face_dir > 0:
		return Vector2(-x_offset,-y_offset)
	elif face_dir < 0:
		return Vector2(x_offset,-y_offset)
	else:
		return current_offset
	
func _new_canvas_transform(ct_o: Vector2, gp: Vector2, ss: Vector2, fc: float, 
							cs: int) -> Vector2:
	#separate x,y	
	var temp:= -gp + ss/2 + _get_offset(current_offset,fc,false)
	var new_x:= temp.x
	var new_y:= temp.y
	
	var previous_movement_state: int = player_node.previous_movement_state
	
	
	
	if previous_movement_state < 0:
		return temp
		
	return Vector2(new_x,new_y)
	
	pass
