extends ActorBase

export(float) var COYOTE_TIME = 0.1

export(float) var JUMP_BUFFER_TIME = 0.1
export(float) var DASH_LENGTH = 2.0
export(float) var DASH_TIME = 0.2
export(float) var DASH_COOLDOWN_TIME = 0.2

export(float) var WALL_COOLDOWN_TIME = 0.2
export(float) var WALL_KICK_POWER = 2.5
export(float) var WALL_KICK_TIME = 0.5

enum {IDLE,WALK,FALL,JUMP}

onready var floor_cast:= $RayCast2D
onready var coyote_timer:= $coyote_timer
onready var jump_buffer_timer:= $jump_buffer_timer

onready var debugtext1:= $VBoxContainer/Label
onready var debugtext2:= $VBoxContainer/Label2
onready var debugtext3:= $VBoxContainer/Label3


onready var current_state:= IDLE 

onready var jump_gravity = Globals._gravity(JUMP_HEIGHT,MAX_WALK_TILE,GAP_LENGTH)
onready var fall_gravity = Globals._gravity(1.5*JUMP_HEIGHT,MAX_WALK_TILE,0.8*GAP_LENGTH)

onready var was_on_floor:= true
var on_floor: bool

var min_jump_force: float

func _ready() -> void:
	jump_force = Globals._jump_vel(MAX_WALK_TILE,JUMP_HEIGHT,GAP_LENGTH)
	min_jump_force = Globals._jump_vel(MAX_WALK_TILE,MIN_JUMP_HEIGHT,GAP_LENGTH/2.0)
	speed = MAX_WALK_TILE*Globals.TILE_UNITS
	coyote_timer.wait_time = COYOTE_TIME
	
	on_floor = check_floor()

func _physics_process(delta: float) -> void:
	
	debugtext1.text = "state: " + str(current_state)
	debugtext2.text = "coyote: " + ("on" if not coyote_timer.is_stopped() else "off")
	debugtext3.text = "is on floor: " + str(check_floor()) + "\nwas on floor: " + str(was_on_floor)
	
	match current_state:
		IDLE:
			var dir = get_direction()
			apply_gravity(delta)
			var snap = Vector2.DOWN*50
			
			was_on_floor = check_floor()
			velocity = move_and_slide_with_snap(velocity,snap,Vector2.UP)
			on_floor = check_floor()
			
			if dir != 0:
				current_state = WALK
			if not on_floor:
				if was_on_floor:
					coyote_timer.start()
				else:
					current_state = FALL
					
			if not jump_buffer_timer.is_stopped() and on_floor:
				jump_buffer_timer.stop()
				coyote_timer.stop()
				velocity.y = -jump_force
				current_state = JUMP
			
		WALK:
			var dir = get_direction()
			apply_gravity(delta)
			velocity.x = speed*dir
			var snap = Vector2.DOWN*50
			
			was_on_floor = check_floor()
			velocity = move_and_slide_with_snap(velocity,snap,Vector2.UP)
			on_floor = check_floor()
			
			if dir == 0 and on_floor:
				current_state = IDLE
				velocity.x = 0
			
			if not on_floor:
				if was_on_floor:
					coyote_timer.start()
				else:
					current_state = FALL
			
			if not jump_buffer_timer.is_stopped() and on_floor:
				jump_buffer_timer.stop()
				coyote_timer.stop()
				velocity.y = -jump_force
				current_state = JUMP
			
		FALL:
			var dir = get_direction()
			apply_gravity(delta)
			velocity.x = speed*dir
			var snap = Vector2.DOWN*50
			
			was_on_floor = check_floor()
			velocity = move_and_slide_with_snap(velocity,snap,Vector2.UP)
			on_floor = check_floor()
			
			if on_floor:
				current_state = IDLE
				velocity.x = 0
			
		JUMP:
			var dir = get_direction()
			apply_gravity(delta)
			velocity.x = speed*dir
			var snap = Vector2.ZERO
			
			was_on_floor = check_floor()
			velocity = move_and_slide_with_snap(velocity,snap,Vector2.UP)
			on_floor = check_floor()
			
			if velocity.y > 0:
				current_state = FALL


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		if [IDLE,WALK].has(current_state):
			if on_floor:
				coyote_timer.stop()
				current_state = JUMP
				velocity.y = -jump_force
		elif [FALL].has(current_state):
			if velocity.y > 0:
				jump_buffer_timer.start()
				
	elif event.is_action_released("jump"):
		if [JUMP].has(current_state):
			if velocity.y < min_jump_force:
				velocity.y = -min_jump_force
				current_state = FALL
	
func get_direction() -> float:
	return Input.get_axis("left","right")

func check_floor() -> bool:
	var output
	output = is_on_floor()
#	output = floor_cast.is_colliding()
	return output or not coyote_timer.is_stopped()

func apply_gravity(delta: float) -> void:
	if not coyote_timer.is_stopped():
		velocity.y = 0.0
		return
	
	if velocity.y < 0:
		velocity.y += jump_gravity*delta
	else:
		velocity.y += fall_gravity*delta
	
	velocity.y = min(velocity.y,MAX_FALL_TILE*Globals.TILE_UNITS)

