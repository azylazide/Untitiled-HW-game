extends ActorBase

export(float) var COYOTE_TIME = 0.1

export(float) var JUMP_BUFFER_TIME = 0.1
export(float) var DASH_LENGTH = 2.0
export(float) var DASH_TIME = 0.2
export(float) var DASH_COOLDOWN_TIME = 0.2

export(float) var WALL_COOLDOWN_TIME = 0.2
export(float) var WALL_KICK_POWER = 2.5
export(float) var WALL_KICK_TIME = 0.5

enum MOVEMENT_STATES {IDLE,WALK,FALL,JUMP,GDASH,ADASH,WALL}
export(MOVEMENT_STATES) var current_movement_state = MOVEMENT_STATES.IDLE

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

var previous_movement_state: int

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
	wall_jump_hold_timer.wait_time = 0.5
	
	face_direction = 1.0
	
	on_floor = check_floor()

func _physics_process(delta: float) -> void:
	
	debugtext1.text = "velocity: " + str(velocity) + "\nposition: " + str(global_position)
	debugtext2.text = "coyote: " + ("on" if not coyote_timer.is_stopped() else "off")
	debugtext3.text = "is on floor: " + str(on_floor) + "\nwas on floor: " + str(was_on_floor)
	debugtext4.text = "face dir: " + ("left" if face_direction < 0 else "right")
	debugtext5.text = "prev state: " + str(previous_movement_state) + "\ncurrent state: " + str(current_movement_state)
	debugtext6.text = "on wall: " + str(on_wall)
	debugtext7.text = "can ajump: " + str(can_ajump) + "\ncan adash: " + str(can_adash)
	
	match current_movement_state:
		MOVEMENT_STATES.IDLE:
			#-Setup-
			_ground_reset()
			var dir = get_direction()
			velocity.x = 0
			_apply_gravity(delta)
			var snap = Vector2.DOWN*50
			
			#-Movement-
			was_on_floor = check_floor()
			_apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			#-Transitions-
			#if moving
			if dir != 0:
				change_state(MOVEMENT_STATES.WALK)
				
			#if on air
			if not on_floor:
				#if was on floor, enable coyote time and not change state
				if was_on_floor:
					coyote_timer.start()
				else:
					change_state(MOVEMENT_STATES.FALL)
			
			#if pressed jumped previously and on floor
			if not jump_buffer_timer.is_stopped() and on_floor:
				jump_buffer_timer.stop()
				_enter_jump()
			
		MOVEMENT_STATES.WALK:
			#-Setup-
			_ground_reset()
			var dir = get_direction()
			_apply_gravity(delta)
			velocity.x = speed*dir
			var snap = Vector2.DOWN*50
			
			#-Movement-
			was_on_floor = check_floor()
			_apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			#-Transitions-
			#if not inputting directions
			if dir == 0 and on_floor:
				change_state(MOVEMENT_STATES.IDLE)
			
			#if on air
			if not on_floor:
				#if was on floor, enable coyote time and not change state
				if was_on_floor:
					coyote_timer.start()
				else:
					change_state(MOVEMENT_STATES.FALL)
			
			#if pressed jumped previously and on floor
			if not jump_buffer_timer.is_stopped() and on_floor:
				jump_buffer_timer.stop()
				_enter_jump()
			
		MOVEMENT_STATES.FALL:
			#-Setup-
			var dir = get_direction()
			_apply_gravity(delta)
			velocity.x = speed*dir
			var snap = Vector2.ZERO
			
			#-Movement-
			was_on_floor = check_floor()
			_apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			#-Transitions-
			#if against a wall
			if on_wall:
				if dir != 0:
					#if applying movement towards wall
					if wall_normal != Vector2.ZERO and dir*wall_normal.x < 0 and wall_cooldown_timer.is_stopped():
						change_state(MOVEMENT_STATES.WALL)
					elif wall_normal.x == 0:
						wall_normal.x = -dir
						#TODO
			
			#if landed
			if on_floor:
				change_state(MOVEMENT_STATES.IDLE)
			
		MOVEMENT_STATES.JUMP:
			#-Setup-
			var snap = Vector2.ZERO
			_apply_gravity(delta)
			if wall_jump_hold_timer.is_stopped():
				velocity.x = speed*get_direction()
			
			#-Movement-
			was_on_floor = check_floor()
			_apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			#-Transitions-
			#if peak of jump reached
			if velocity.y > 0:
				change_state(MOVEMENT_STATES.FALL)
		
		MOVEMENT_STATES.GDASH:
			#-Setup-
			var snap = Vector2.DOWN*50
			
			#-Movement-
			was_on_floor = check_floor()
			if was_on_floor and on_floor:
				_apply_gravity(delta)
			else:
				velocity.y = 0
			_apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			
			#-Transitions-
			#if left the ground
			if not on_floor:
				if was_on_floor:
					coyote_timer.wait_time = 0.08
					coyote_timer.start()
			
			#when dash ends
			if dash_timer.is_stopped():
				if on_floor:
					if get_direction() != 0:
						change_state(MOVEMENT_STATES.WALK)
					else:
						change_state(MOVEMENT_STATES.IDLE)
				elif not on_floor and not was_on_floor:
					change_state(MOVEMENT_STATES.FALL)
		
		MOVEMENT_STATES.ADASH:
			#-Setup-
			var snap = Vector2.ZERO
			
			#-Movement-
			was_on_floor = check_floor()
			_apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			#-Transitions-
			#when dash ends
			if dash_timer.is_stopped():
				if on_floor:
					if get_direction() != 0:
						change_state(MOVEMENT_STATES.WALK)
					else:
						change_state(MOVEMENT_STATES.IDLE)
				else:
					change_state(MOVEMENT_STATES.FALL)
		
		MOVEMENT_STATES.WALL:
			#-Setup-
			var snap = Vector2.ZERO
			
			#-Transition-
			#if moving away from wall
			if wall_slide_timer.is_stopped():
				if get_direction()*wall_normal.x > 0:
					change_state(MOVEMENT_STATES.FALL)
			
			velocity.y += 0.1*fall_gravity*delta
			velocity.y = min(velocity.y,0.5*MAX_FALL_TILE*Globals.TILE_UNITS) 
			
			#-Movement-
			was_on_floor = check_floor()
			_apply_movement(delta,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			#-Transitions-
			#if landed
			if on_floor:
				face_direction = sign(wall_normal.x)
				change_state(MOVEMENT_STATES.IDLE)
			
			#if wall ended
			if not on_wall:
				face_direction = sign(wall_normal.x)
				change_state(MOVEMENT_STATES.FALL)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		if [MOVEMENT_STATES.IDLE,MOVEMENT_STATES.WALK].has(current_movement_state):
			if on_floor:
				_enter_jump()
		elif [MOVEMENT_STATES.FALL].has(current_movement_state):
			if velocity.y > 0:
				jump_buffer_timer.start()
			if on_wall:
				_enter_jump()
			elif not on_wall and can_ajump:
				can_ajump = false
				jump_buffer_timer.stop()
				_enter_jump()
		elif [MOVEMENT_STATES.GDASH].has(current_movement_state):
			if not coyote_timer.is_stopped() or on_floor:
				_enter_jump()
		elif [MOVEMENT_STATES.WALL].has(current_movement_state):
			_enter_jump()
		
	elif event.is_action_released("jump"):
		if [MOVEMENT_STATES.JUMP].has(current_movement_state):
			if velocity.y < min_jump_force:
				velocity.y = -min_jump_force
				change_state(MOVEMENT_STATES.FALL)
	
	elif event.is_action_pressed("dash"):
		if [MOVEMENT_STATES.IDLE,MOVEMENT_STATES.WALK,MOVEMENT_STATES.GDASH].has(current_movement_state):
			if dash_cooldown_timer.is_stopped():
				_enter_gdash()
		elif [MOVEMENT_STATES.FALL,MOVEMENT_STATES.JUMP].has(current_movement_state):
			if dash_cooldown_timer.is_stopped() and can_adash:
				_enter_adash()
		elif [MOVEMENT_STATES.WALL].has(current_movement_state):
			face_direction = sign(wall_normal.x)
			_enter_adash()

#-HELPER FUNCTIONS-

#reset variables when landing
func _ground_reset() -> void:
	can_adash = true
	can_ajump = true

#record previous state and change current state
func change_state(next_state: int) -> void:
	previous_movement_state = current_movement_state
	current_movement_state = next_state

#check previous state before jump
func _enter_jump() -> void:
	coyote_timer.stop()
	change_state(MOVEMENT_STATES.JUMP)
	
	match previous_movement_state:
		MOVEMENT_STATES.FALL:
			if on_wall:
				if wall_normal != Vector2.ZERO and wall_cooldown_timer.is_stopped():
					wall_jump_hold_timer.start()
					face_direction = sign(wall_normal.x)
					velocity.x = wall_kick_force*face_direction
					velocity.y = -jump_force
			else:
				velocity.y = -jump_force*0.8
		MOVEMENT_STATES.GDASH:
			velocity.y = -jump_force*1.2
		MOVEMENT_STATES.WALL:
			wall_jump_hold_timer.start()
			face_direction = sign(wall_normal.x)
			velocity.x = wall_kick_force*face_direction
			velocity.y = -jump_force
		_:
			velocity.y = -jump_force

#necessary setup before transitioning to gdash
func _enter_gdash() -> void:
	dash_cooldown_timer.start()
	change_state(MOVEMENT_STATES.GDASH)
	velocity.x = dash_force*face_direction
	dash_timer.start()

#necessary setup before transitioning to gdash
func _enter_adash() -> void:
	dash_cooldown_timer.start()
	can_adash = false
	change_state(MOVEMENT_STATES.ADASH)
	velocity.x = dash_force*face_direction
	velocity.y = 0
	dash_timer.start()

#necessary setup before transitioning to wall
func _enter_wall() -> void:
	can_adash = true
	velocity.x = 0
	velocity.y = 0
	wall_cooldown_timer.start()
	wall_slide_timer.start()
	change_state(MOVEMENT_STATES.WALL)

#get current input direction
func get_direction() -> float:
	return Input.get_axis("left","right")

#check when on floor or coyote is enabled
func check_floor() -> bool:
	var output
	output = is_on_floor()
#	output = floor_cast.is_colliding() #might implement force ray cast update
	return output or not coyote_timer.is_stopped()

#check when against wall
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

#apply gravity according to current state condition
func _apply_gravity(delta: float) -> void:
	#if coyote active
	if not coyote_timer.is_stopped():
		velocity.y = 0.0
		return
	
	#if in the middle of a jump
	if velocity.y < 0:
		velocity.y += jump_gravity*delta
	#after peak of jump
	else:
		velocity.y += fall_gravity*delta
	
	#terminal velocity
	velocity.y = min(velocity.y,MAX_FALL_TILE*Globals.TILE_UNITS)

#apply movement and save face direction
func _apply_movement(delta: float, snap: Vector2) -> void:
	velocity = move_and_slide_with_snap(velocity,snap,Vector2.UP)
	
	if get_direction() == 0:
		return
	else:
		face_direction = -1 if get_direction() < 0 else 1
