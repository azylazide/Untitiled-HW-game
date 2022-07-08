extends ActorBase


enum MOVEMENT_STATES {IDLE,WALK}
export(MOVEMENT_STATES) var current_movement_state = MOVEMENT_STATES.IDLE

enum ACTION_STATES {NEUTRAL,ATTACK,DEAD}
export(ACTION_STATES) var current_action_state = ACTION_STATES.NEUTRAL

export(float,-1,1) var initial_direction = 1

var previous_movement_state:= -1
var previous_action_state:= -1
var previous_frame_movement_state:= -1
var next_movement_state:= -1

onready var left_edge_detector: RayCast2D = $EdgeDetectors/LeftEdge
onready var right_edge_detector: RayCast2D = $EdgeDetectors/RightEdge

onready var left_wall_detector: RayCast2D = $WallDetectors/LeftWall
onready var right_wall_detector: RayCast2D = $WallDetectors/RightWall

onready var gravity:= 15*Globals.TILE_UNITS

onready var debug_label:= $VBoxContainer/Label

func _ready() -> void:
	
	add_to_group("Enemies")
	
	direction = initial_direction
	speed = MAX_WALK_TILE*Globals.TILE_UNITS
	pass


func _physics_process(delta: float) -> void:
	right_wall_detector.force_raycast_update()
	left_wall_detector.force_raycast_update()
	right_edge_detector.force_raycast_update()
	left_edge_detector.force_raycast_update()
	
	debug_label.text = "LW: %s RW: %s\nLE: %s RE: %s" %[left_wall_detector.is_colliding(),
		right_wall_detector.is_colliding(),
		left_edge_detector.is_colliding(),
		right_edge_detector.is_colliding()]
	
	if direction > 0:
		if right_wall_detector.is_colliding():
			direction = -1
		elif not right_edge_detector.is_colliding():
			direction = -1
	elif direction < 0:
		if left_wall_detector.is_colliding():
			direction = 1
		elif not left_edge_detector.is_colliding():
			direction = 1
	
	if previous_frame_movement_state != current_movement_state:
		_enter_state(delta)
	next_movement_state = (_initial_state(delta) if previous_frame_movement_state == -1 
							else _run_state(delta))
	if next_movement_state != current_movement_state:
		_exit_state(delta,current_movement_state)
	change_movement_state(next_movement_state)

func _enter_state(delta: float) -> void:
	pass
	
func _initial_state(delta: float) -> int:
	match current_movement_state:
		MOVEMENT_STATES.IDLE:
			return MOVEMENT_STATES.IDLE
		MOVEMENT_STATES.WALK:
			velocity.x = speed*direction
			_apply_gravity(delta)
			velocity = move_and_slide_with_snap(velocity,Vector2.DOWN*50,Vector2.UP)
			return MOVEMENT_STATES.WALK
	return -1

func _run_state(delta: float) -> int:
	if current_action_state != ACTION_STATES.DEAD:
		match current_movement_state:
			MOVEMENT_STATES.IDLE:
				return MOVEMENT_STATES.IDLE
			MOVEMENT_STATES.WALK:
				velocity.x = lerp(velocity.x,speed*direction,0.05)
				_apply_gravity(delta)
				velocity = move_and_slide_with_snap(velocity,Vector2.DOWN*50,Vector2.UP)
				return MOVEMENT_STATES.WALK
	return -1

func _exit_state(delta: float, current_state: int) -> void:
	pass

func change_movement_state(next_state: int) -> void:
	previous_frame_movement_state = current_movement_state
	
	if next_state == current_movement_state:
		return
	
	previous_movement_state = current_movement_state
	current_movement_state = next_state


func _apply_gravity(delta: float) -> void:
	velocity.y += gravity*delta
