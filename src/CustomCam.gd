extends Node2D
class_name CustomCam

export(NodePath) var player_path
onready var player_node: ActorBase = get_node(player_path)
onready var screen_size: Vector2 = get_viewport().get_visible_rect().size

export(float) var x_offset_tiles = 0.8

export(float,0,1) var IDLE_SMOOTHING = 0.2
export(float,0,1) var WALK_SMOOTHING = 0.6
export(float,0,1) var JUMP_SMOOTHING = 0.1

onready var x_offset: float = x_offset_tiles*Globals.TILE_UNITS
onready var current_offset:= Vector2(x_offset,0)

var bbox_array = []

func _ready() -> void:
	#connect the detector to camera
	player_node.camera_bbox_detector.connect("area_entered",self,"on_CameraBBoxDetector_area_entered")
	player_node.camera_bbox_detector.connect("area_exited",self,"on_CameraBBoxDetector_area_exited")
	
	#get current offset
	var initial_face_dir: float = player_node.face_direction
	
	var initial_player_movement_state: int = player_node.current_movement_state
	
	#set initial position
	var canvas_transform: Transform2D = get_viewport().canvas_transform
	canvas_transform.origin = _new_canvas_transform(canvas_transform.origin,
													player_node.global_position,
													screen_size,
													initial_face_dir,
													initial_player_movement_state)
	
	#apply camera
	get_viewport().canvas_transform = canvas_transform

	pass

func _physics_process(delta: float) -> void:
	#get current offset
	var face_dir: float = player_node.face_direction
		
	var player_movement_state: int = player_node.current_movement_state
	
	var canvas_transform: Transform2D = get_viewport().canvas_transform
	
	canvas_transform.origin = _new_canvas_transform(canvas_transform.origin,
													player_node.global_position,
													screen_size,
													face_dir,
													player_movement_state)
	
	#clamp cam at edges when in bounds
	
	#apply camera
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


#might be a problem when detectors fire before camera is ready
func on_CameraBBoxDetector_area_entered(area: Area2D):
	print("enter")
	pass

func on_CameraBBoxDetector_area_exited(area: Area2D):
	print("exit")
	pass

func _get_offset(current_offset: Vector2, face_dir: float, additional: Vector2 = Vector2.ZERO) -> Vector2:
	if face_dir > 0:
		return Vector2(x_offset+additional.x,additional.y)
	elif face_dir < 0:
		return Vector2(-x_offset-additional.x,additional.y)
	else:
		return current_offset
	
func _new_canvas_transform(ct_o: Vector2, gp: Vector2, ss: Vector2, fc: float, 
							cs: int) -> Vector2:
	#separate x,y	
	var temp:= -gp + ss/2
	var new_x: float
	var new_y: float
	
	if player_node.previous_movement_state < 0:
		return temp
	
	match cs:
		player_node.MOVEMENT_STATES.IDLE:
			current_offset = _get_offset(current_offset,fc)
			
			new_x = lerp(ct_o.x,temp.x+current_offset.x,0.1)
			new_y = lerp(ct_o.y,temp.y,0.1)
			
		player_node.MOVEMENT_STATES.WALK:
			current_offset = _get_offset(current_offset,fc,Vector2(-3*Globals.TILE_UNITS,0))
			
			new_x = lerp(ct_o.x,temp.x+current_offset.x,0.1)
			new_y = lerp(ct_o.y,temp.y,0.1)
			
		player_node.MOVEMENT_STATES.FALL:
			if player_node.direction != 0:
				current_offset = _get_offset(current_offset,fc,Vector2(3*Globals.TILE_UNITS,-4.5*Globals.TILE_UNITS))
				
				new_x = lerp(ct_o.x,temp.x+current_offset.x,0.1)
			else:
				current_offset = _get_offset(current_offset,fc,Vector2(0,-4.5*Globals.TILE_UNITS))
				
				new_x = lerp(ct_o.x,temp.x,0.01)
				
			new_y = lerp(ct_o.y,temp.y+current_offset.y,0.05)
		player_node.MOVEMENT_STATES.JUMP:
			if player_node.direction != 0:
				current_offset = _get_offset(current_offset,fc,Vector2(3*Globals.TILE_UNITS,1.5*Globals.TILE_UNITS))
			else:
				current_offset = _get_offset(current_offset,fc,Vector2(0,1.5*Globals.TILE_UNITS))
			
			new_x = lerp(ct_o.x,temp.x+current_offset.x,0.05)
			new_y = lerp(ct_o.y,temp.y+current_offset.y,0.1)
		player_node.MOVEMENT_STATES.GDASH:
			current_offset = _get_offset(current_offset,fc,Vector2(3*Globals.TILE_UNITS,0))
			new_x = lerp(ct_o.x,temp.x+current_offset.x,0.1)
			new_y = lerp(ct_o.y,temp.y,0.1)
		player_node.MOVEMENT_STATES.ADASH:
			current_offset = _get_offset(current_offset,fc,Vector2(3*Globals.TILE_UNITS,0))
			new_x = lerp(ct_o.x,temp.x+current_offset.x,0.1)
			new_y = lerp(ct_o.y,temp.y,0.1)
		player_node.MOVEMENT_STATES.WALL:
			if player_node.velocity.y > 0:
				current_offset = _get_offset(current_offset,fc,Vector2(3*Globals.TILE_UNITS,-1.5*Globals.TILE_UNITS))
				new_y = lerp(ct_o.y,temp.y+current_offset.y,0.05)
			else:
				new_y = lerp(ct_o.y,temp.y,0.05)
			
			new_x = lerp(ct_o.x,temp.x+current_offset.x,0.05)
		
	return Vector2(new_x,new_y)
	
	pass