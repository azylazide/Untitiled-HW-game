extends ActorBase

export(float) var COYOTE_TIME = 0.1

export(float) var JUMP_BUFFER_TIME = 0.1
export(float) var DASH_LENGTH = 2.0
export(float) var DASH_TIME = 0.2
export(float) var DASH_COOLDOWN_TIME = 0.2

export(float) var WALL_COOLDOWN_TIME = 0.2
export(float) var WALL_KICK_POWER = 2.5
export(float) var WALL_KICK_TIME = 0.5

enum {IDLE,WALK,FALL,JUMP,GDASH,ADASH,WALL}

onready var floor_cast:= $RayCast2D
onready var left_raycast:= $WallRays/LeftRay
onready var right_raycast:= $WallRays/RightRay

onready var coyote_timer:= $CoyoteTimer
onready var jump_buffer_timer:= $JumpBufferTimer
onready var wall_slide_timer:= $WallSlideTimer
onready var wall_cooldown_timer:= $WallCooldownTimer
onready var wall_jump_hold_timer:= $WallJumpHoldTimer
onready var dash_timer:= $DashTimer
onready var dash_cooldown_timer:= $DashCooldownTimer


onready var debugtext1:= $VBoxContainer/Label
onready var debugtext2:= $VBoxContainer/Label2
onready var debugtext3:= $VBoxContainer/Label3
onready var debugtext4:= $VBoxContainer/Label4
onready var debugtext5:= $VBoxContainer/Label5
onready var debugtext6:= $VBoxContainer/Label6
onready var debugtext7:= $VBoxContainer/Label7


onready var current_state:= IDLE 

onready var jump_gravity = Globals._gravity(JUMP_HEIGHT,MAX_WALK_TILE,GAP_LENGTH)
onready var fall_gravity = Globals._gravity(1.5*JUMP_HEIGHT,MAX_WALK_TILE,0.8*GAP_LENGTH)

onready var was_on_floor:= true
onready var can_adash:= true
onready var can_ajump:= true

onready var wall_normal:= Vector2.ZERO

var on_floor: bool
var on_wall: bool

var min_jump_force: float
var dash_force: float
var wall_kick_force: float

var previous_state: int

func _ready() -> void:
	jump_force = Globals._jump_vel(MAX_WALK_TILE,JUMP_HEIGHT,GAP_LENGTH)
	min_jump_force = Globals._jump_vel(MAX_WALK_TILE,MIN_JUMP_HEIGHT,GAP_LENGTH/2.0)
	wall_kick_force = Globals._wall_kick(WALL_KICK_POWER,WALL_KICK_TIME)
	
	speed = MAX_WALK_TILE*Globals.TILE_UNITS
	
	coyote_timer.wait_time = COYOTE_TIME
	
	dash_timer.wait_time = DASH_TIME
	dash_cooldown_timer.wait_time = DASH_COOLDOWN_TIME
	dash_force = Globals._dash_speed(DASH_LENGTH,DASH_TIME)
	
	wall_slide_timer.wait_time = 0.1
	wall_cooldown_timer.wait_time = WALL_COOLDOWN_TIME
	wall_jump_hold_timer.wait_time = 2
	
	face_direction = 1.0
	
	on_floor = check_floor()

func _physics_process(delta: float) -> void:
	
	debugtext1.text = "state: " + str(current_state)
	debugtext2.text = "coyote: " + ("on" if not coyote_timer.is_stopped() else "off")
	debugtext3.text = "is on floor: " + str(on_floor) + "\nwas on floor: " + str(was_on_floor)
	debugtext4.text = "face dir: " + ("left" if face_direction < 0 else "right")
	debugtext5.text = "prev state: " + str(previous_state) + "\ncurrent state: " + str(current_state)
	debugtext6.text = "on wall: " + str(on_wall)
	debugtext7.text = "can ajump: " + str(can_ajump) + "\ncan adash: " + str(can_adash)
	
	match current_state:
		IDLE:
			ground_reset()
			var dir = get_direction()
			velocity.x = 0
			apply_gravity(delta)
			var snap = Vector2.DOWN*50
			
			was_on_floor = check_floor()
			apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			if dir != 0:
				current_state = WALK
			if not on_floor:
				if was_on_floor:
					coyote_timer.start()
				else:
					change_state(FALL)
					
			if not jump_buffer_timer.is_stopped() and on_floor:
				jump_buffer_timer.stop()
				enter_jump()
			
		WALK:
			ground_reset()
			var dir = get_direction()
			apply_gravity(delta)
			velocity.x = speed*dir
			var snap = Vector2.DOWN*50
			
			was_on_floor = check_floor()
			apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			if dir == 0 and on_floor:
				change_state(IDLE)
			
			if not on_floor:
				if was_on_floor:
					coyote_timer.start()
				else:
					change_state(FALL)
			
			if not jump_buffer_timer.is_stopped() and on_floor:
				jump_buffer_timer.stop()
				enter_jump()
			
		FALL:
			var dir = get_direction()
			apply_gravity(delta)
			velocity.x = speed*dir
			var snap = Vector2.DOWN*50
			
			was_on_floor = check_floor()
			apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			if on_wall:
				if dir != 0:
					if wall_normal != Vector2.ZERO and dir*wall_normal.x < 0 and wall_cooldown_timer.is_stopped():
						change_state(WALL)
					elif wall_normal.x == 0:
						wall_normal.x = -dir
						#TODO
			
			if on_floor:
				change_state(IDLE)
			
		JUMP:
			var dir = get_direction()
			apply_gravity(delta)
			if wall_jump_hold_timer.is_stopped():
				velocity.x = speed*dir
			var snap = Vector2.ZERO
			
			was_on_floor = check_floor()
			apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			if velocity.y > 0:
				change_state(FALL)
		
		GDASH:
			var snap = Vector2.DOWN*50
			was_on_floor = check_floor()
			if was_on_floor and on_floor:
				apply_gravity(delta)
			else:
				velocity.y = 0
			apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			if not on_floor:
				if was_on_floor:
					coyote_timer.wait_time = 0.08
					coyote_timer.start()
			
			if dash_timer.is_stopped():
				if on_floor:
					if get_direction() != 0:
						change_state(WALK)
					else:
						change_state(IDLE)
				elif not on_floor and not was_on_floor:
					change_state(FALL)
		
		ADASH:
			var snap = Vector2.DOWN*50
			was_on_floor = check_floor()
			apply_movement(delta,snap)
			on_wall = check_wall()
			
			if dash_timer.is_stopped():
				if on_floor:
					if get_direction() != 0:
						change_state(WALK)
					else:
						change_state(IDLE)
				else:
					change_state(FALL)
		
		WALL:
			var snap = Vector2.ZERO
			if wall_slide_timer.is_stopped():
				if get_direction()*wall_normal.x > 0:
					change_state(FALL)
			
			velocity.y += 0.1*fall_gravity*delta
			velocity.y = min(velocity.y,0.5*MAX_FALL_TILE*Globals.TILE_UNITS) 
			
			was_on_floor = check_floor()
			apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			if on_floor:
				face_direction = sign(wall_normal.x)
				change_state(IDLE)
			if not on_wall:
				face_direction = sign(wall_normal.x)
				change_state(FALL)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		if [IDLE,WALK].has(current_state):
			if on_floor:
				enter_jump()
		elif [FALL].has(current_state):
			if velocity.y > 0:
				jump_buffer_timer.start()
			if on_wall:
				enter_jump()
			elif not on_wall and can_ajump:
				can_ajump = false
				jump_buffer_timer.stop()
				enter_jump()
		elif [GDASH].has(current_state):
			if not coyote_timer.is_stopped() or on_floor:
				enter_jump()
		elif [WALL].has(current_state):
			enter_jump()
		
	elif event.is_action_released("jump"):
		if [JUMP].has(current_state):
			if velocity.y < min_jump_force:
				velocity.y = -min_jump_force
				change_state(FALL)
	
	elif event.is_action_pressed("dash"):
		if [IDLE,WALK,GDASH].has(current_state):
			if dash_cooldown_timer.is_stopped():
				enter_gdash()
		elif [FALL,JUMP].has(current_state):
			if dash_cooldown_timer.is_stopped() and can_adash:
				enter_adash()
		elif [WALL].has(current_state):
			face_direction = sign(wall_normal.x)
			enter_adash()

func ground_reset() -> void:
	can_adash = true
	can_ajump = true

func change_state(next_state: int) -> void:
	previous_state = current_state
	current_state = next_state

func enter_jump() -> void:
	coyote_timer.stop()
	change_state(JUMP)
	
	match previous_state:
		FALL:
			if on_wall:
				if wall_normal != Vector2.ZERO and wall_cooldown_timer.is_stopped():
					wall_jump_hold_timer.start()
					face_direction = sign(wall_normal.x)
					velocity.x = wall_kick_force*face_direction
					velocity.y = -jump_force
			else:
				velocity.y = -jump_force*0.8
		GDASH:
			velocity.y = -jump_force*1.2
		WALL:
			wall_jump_hold_timer.start()
			velocity.x = wall_kick_force*face_direction
			velocity.y = -jump_force
		_:
			velocity.y = -jump_force

func enter_gdash() -> void:
	dash_cooldown_timer.start()
	change_state(GDASH)
	velocity.x = dash_force*face_direction
	dash_timer.start()

func enter_adash() -> void:
	dash_cooldown_timer.start()
	can_adash = false
	change_state(ADASH)
	velocity.x = dash_force*face_direction
	velocity.y = 0
	dash_timer.start()
	
func enter_wall() -> void:
	can_adash = true
	velocity.x = 0
	velocity.y = 0
	wall_cooldown_timer.start()
	wall_slide_timer.start()
	change_state(WALL)

func get_direction() -> float:
	return Input.get_axis("left","right")

func check_floor() -> bool:
	var output
	output = is_on_floor()
#	output = floor_cast.is_colliding()
	return output or not coyote_timer.is_stopped()

func check_wall() -> bool:
	var left: bool = left_raycast.is_colliding()
	var right: bool = right_raycast.is_colliding()
	
	#check if player is close to two walls
	if left and right:
		wall_normal = Vector2.ZERO
		return true
	#check left
	elif left:
		wall_normal = left_raycast.get_collision_normal()
		#TO DO: check for valid wall angle
		return true
	#check right
	elif right:
		wall_normal = right_raycast.get_collision_normal()
		#TO DO: check for valid wall angle
		return true
	#no wall
	else:
		return false

func apply_gravity(delta: float) -> void:
	if not coyote_timer.is_stopped():
		velocity.y = 0.0
		return
	
	if velocity.y < 0:
		velocity.y += jump_gravity*delta
	else:
		velocity.y += fall_gravity*delta
	
	velocity.y = min(velocity.y,MAX_FALL_TILE*Globals.TILE_UNITS)

func apply_movement(delta: float, snap: Vector2) -> void:
	velocity = move_and_slide_with_snap(velocity,snap,Vector2.UP)
	
	if get_direction() == 0:
		return
	else:
		face_direction = -1 if get_direction() < 0 else 1
