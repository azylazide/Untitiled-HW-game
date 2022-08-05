extends ActorBase

export(float) var COYOTE_TIME = 0.1

export(float) var JUMP_BUFFER_TIME = 0.1
export(float) var DASH_LENGTH = 2.0
export(float) var DASH_TIME = 0.2
export(float) var DASH_COOLDOWN_TIME = 0.2

export(float) var WALL_COOLDOWN_TIME = 0.2
export(float) var WALL_KICK_POWER = 2.5
export(float) var WALL_KICK_TIME = 0.5

export(float) var AUTO_TIME = 0.15

export(int, -1,1) var INITIAL_DIRECTION:= 1

enum MOVEMENT_STATES {IDLE,WALK,FALL,JUMP,GDASH,ADASH,WALL}
export(MOVEMENT_STATES) var current_movement_state = MOVEMENT_STATES.IDLE

enum ACTION_STATES {NEUTRAL,ATTACK,STAGGER,DEAD,AUTO}
export(ACTION_STATES) var current_action_state = ACTION_STATES.AUTO

onready var floor_cast:= $RayCast2D
onready var left_raycast:= $WallRays/LeftRay
onready var right_raycast:= $WallRays/RightRay

onready var coyote_timer:= $Timers/CoyoteTimer

onready var jump_buffer_timer:= $Timers/JumpBufferTimer

onready var wall_slide_timer:= $Timers/WallSlideTimer
onready var wall_cooldown_timer:= $Timers/WallCooldownTimer
onready var wall_jump_hold_timer:= $Timers/WallJumpHoldTimer

onready var dash_timer:= $Timers/DashTimer
onready var dash_cooldown_timer:= $Timers/DashCooldownTimer

onready var auto_timer:= $Timers/AutoTimer

onready var camera_bbox_detector:= $CameraBBoxDetector
onready var camera_center:= $CameraCenter

onready var particle_pivot:= $ParticlePivot
onready var dash_particle_emitter:= $ParticlePivot/DashParticles

onready var debugtext1:= $CanvasLayer/VBoxContainer/Label
onready var debugtext2:= $CanvasLayer/VBoxContainer/Label2
onready var debugtext3:= $CanvasLayer/VBoxContainer/Label3
onready var debugtext4:= $CanvasLayer/VBoxContainer/Label4
onready var debugtext5:= $CanvasLayer/VBoxContainer/Label5
onready var debugtext6:= $CanvasLayer/VBoxContainer/Label6
onready var debugtext7:= $CanvasLayer/VBoxContainer/Label7  
onready var debugtext8:= $CanvasLayer/VBoxContainer/Label8 

onready var jump_gravity = Globals._gravity(JUMP_HEIGHT,MAX_WALK_TILE,GAP_LENGTH)
onready var fall_gravity = Globals._gravity(1.5*JUMP_HEIGHT,MAX_WALK_TILE,0.8*GAP_LENGTH)

onready var was_on_floor:= true
onready var can_adash:= true
onready var can_ajump:= true

onready var wall_normal:= Vector2.ZERO

onready var sprite:= $Sprite
onready var arrow_spawn_point:= $ArrowSpawnPoint

onready var arrow_scn:= preload("res://src/Projectiles/Arrows.tscn")

var on_floor: bool
var on_wall: bool

var min_jump_force: float
var dash_force: float
var wall_kick_force: float

var previous_movement_state:= -1
var next_movement_state:= -1
var previous_frame_movement_state:= -1
var previous_action_state:= -1
var next_action_state:= -1
var previous_frame_action_state:= -1

signal movement_changed()
signal action_changed()
signal player_updated()
signal arrow_spawned()


func _ready() -> void:
	add_to_group("Player")
	
	
	jump_force = Globals._jump_vel(MAX_WALK_TILE,JUMP_HEIGHT,GAP_LENGTH)
	min_jump_force = Globals._jump_vel(MAX_WALK_TILE,MIN_JUMP_HEIGHT,GAP_LENGTH/2.0)
	wall_kick_force = Globals._wall_kick(WALL_KICK_POWER,WALL_KICK_TIME)
	
	speed = MAX_WALK_TILE*Globals.TILE_UNITS
	
	coyote_timer.wait_time = COYOTE_TIME
	
	jump_buffer_timer.wait_time = JUMP_BUFFER_TIME
	
	dash_timer.wait_time = DASH_TIME
	dash_cooldown_timer.wait_time = DASH_COOLDOWN_TIME
	dash_force = Globals._dash_speed(DASH_LENGTH,DASH_TIME)
	
	wall_slide_timer.wait_time = 0.1
	wall_cooldown_timer.wait_time = WALL_COOLDOWN_TIME
	wall_jump_hold_timer.wait_time = 0.5
	
	auto_timer.wait_time = AUTO_TIME
	auto_timer.start()
	
	dash_particle_emitter.lifetime = DASH_TIME*2
	
	face_direction = 1.0
	
	on_floor = check_floor()

	connect("death",self,"die")


func _debug_text() -> void:
	debugtext1.text = "velocity: (%f,%f)" %[velocity.x,velocity.y] + "\nposition: (%f,%f)" %[global_position.x,global_position.y]
	debugtext2.text = "coyote: " + ("on" if not coyote_timer.is_stopped() else "off")
	debugtext3.text = "is on floor: " + str(on_floor) + "\nwas on floor: " + str(was_on_floor)
	debugtext4.text = "face dir: " + ("left" if face_direction < 0 else "right")
	debugtext5.text = ("MOVEMENT STATES\nprev state: %s\ncurrent state: %s\n(next: %s)\nACTION STATES\nprev state: %s\ncurrent state: %s\n(next %s)" 
						%[Globals.player_move_state_name(previous_movement_state),
						Globals.player_move_state_name(current_movement_state),
						Globals.player_move_state_name(next_movement_state),
						Globals.player_action_state_name(previous_action_state),
						Globals.player_action_state_name(current_action_state),
						Globals.player_action_state_name(next_action_state)])
	debugtext6.text = "on wall: " + str(on_wall)
	debugtext7.text = "can ajump: " + str(can_ajump) + "\ncan adash: " + str(can_adash)
	debugtext8.text = "Health: " + str(actor_stats.health)


func _physics_process(delta: float) -> void:
	_debug_text()

	#MOVEMENT STATEMACHINE
	_movement_statemachine(delta)
	
	#ACTION STATEMACHINE
	_action_statemachine(delta)

	#After movement changes

	_face_direction_changes()

	#make particle direction opposite of movement
	if velocity.x > 0:
		dash_particle_emitter.process_material.set_direction(Vector3(-particle_pivot.scale.x,0,0))
	elif velocity.x < 0:
		dash_particle_emitter.process_material.set_direction(Vector3(particle_pivot.scale.x,0,0))
	
	emit_signal("player_updated",
				face_direction,
				velocity,
				previous_movement_state,
				current_movement_state,
				camera_center.global_position)

func _movement_statemachine(delta) -> void:
	if previous_frame_movement_state != current_movement_state:
		_enter_movement_state(delta)
	next_movement_state = (_initial_movement_state(delta) if previous_frame_movement_state == -1 
							else _run_movement_state(delta))
	if next_movement_state != current_movement_state:
		_exit_movement_state(delta,current_movement_state)
	change_movement_state(next_movement_state)
	
func _action_statemachine(delta) -> void:
	if previous_frame_action_state != current_action_state:
		_enter_action_state(delta)
	next_action_state = (_initial_action_state(delta) if previous_frame_action_state == -1 
							else _run_action_state(delta))
	if next_action_state != current_action_state:
		_exit_action_state(delta,current_action_state)
	change_action_state(next_action_state)

func _unhandled_input(event: InputEvent) -> void:
	
	if not [ACTION_STATES.STAGGER,ACTION_STATES.DEAD,ACTION_STATES.AUTO].has(current_action_state):
		match current_movement_state:
			MOVEMENT_STATES.IDLE:
				if event.is_action_pressed("jump"):
					if on_floor:
						change_movement_state(MOVEMENT_STATES.JUMP)
				if event.is_action_pressed("dash"):
					if dash_cooldown_timer.is_stopped():
						change_movement_state(MOVEMENT_STATES.GDASH)
					
			MOVEMENT_STATES.WALK:
				if event.is_action_pressed("jump"):
					if on_floor:
						change_movement_state(MOVEMENT_STATES.JUMP)
				if event.is_action_pressed("dash"):
					if dash_cooldown_timer.is_stopped():
						change_movement_state(MOVEMENT_STATES.GDASH)
			MOVEMENT_STATES.FALL:
				if event.is_action_pressed("jump"):
					if velocity.y > 0:
						jump_buffer_timer.start()
					if on_wall:
						change_movement_state(MOVEMENT_STATES.JUMP)
					elif not on_wall and can_ajump:
						can_ajump = false
						jump_buffer_timer.stop()
						change_movement_state(MOVEMENT_STATES.JUMP)
				if event.is_action_pressed("dash"):
					if dash_cooldown_timer.is_stopped() and can_adash:
						change_movement_state(MOVEMENT_STATES.ADASH)
			MOVEMENT_STATES.JUMP:
				if event.is_action_released("jump"):
					if velocity.y < min_jump_force:
						velocity.y = -min_jump_force
						change_movement_state(MOVEMENT_STATES.FALL)
				if event.is_action_pressed("dash"):
					if dash_cooldown_timer.is_stopped() and can_adash:
						change_movement_state(MOVEMENT_STATES.ADASH)
			
			MOVEMENT_STATES.GDASH:
				if event.is_action_pressed("jump"):
					if not coyote_timer.is_stopped() or on_floor:
						change_movement_state(MOVEMENT_STATES.JUMP)
				if event.is_action_pressed("dash"):
					if dash_cooldown_timer.is_stopped():
						change_movement_state(MOVEMENT_STATES.GDASH)
			
			MOVEMENT_STATES.ADASH:
				pass
			
			MOVEMENT_STATES.WALL:
				if event.is_action_pressed("jump"):
					change_movement_state(MOVEMENT_STATES.JUMP)
				if event.is_action_pressed("dash"):
					face_direction = sign(wall_normal.x)
					change_movement_state(MOVEMENT_STATES.ADASH)
		
		match current_action_state:
			ACTION_STATES.NEUTRAL:
				if event.is_action_pressed("attack"):
					change_action_state(ACTION_STATES.ATTACK)

func _enter_movement_state(delta: float) -> void:
	if not [ACTION_STATES.DEAD,ACTION_STATES.STAGGER,ACTION_STATES.AUTO].has(current_action_state):
		match current_movement_state:
			MOVEMENT_STATES.IDLE:
				_ground_reset()
				return
				
			MOVEMENT_STATES.WALK:
				_ground_reset()
				return
				
			MOVEMENT_STATES.FALL:
				return
				
			MOVEMENT_STATES.JUMP:
				coyote_timer.stop()
				_enter_jump()
				return
			
			MOVEMENT_STATES.GDASH:
				dash_particle_emitter.emitting = true
				dash_cooldown_timer.start()
				velocity.x = dash_force*face_direction
				dash_timer.start()
				return
			
			MOVEMENT_STATES.ADASH:
				dash_particle_emitter.emitting = true
				dash_cooldown_timer.start()
				can_adash = false
				velocity.x = dash_force*face_direction
				velocity.y = 0
				dash_timer.start()
				return
			
			MOVEMENT_STATES.WALL:
				can_adash = true
				velocity.x = 0
				velocity.y = 0
				wall_cooldown_timer.start()
				wall_slide_timer.start()
				return


func _enter_action_state(delta: float) -> void:
	pass

func _initial_movement_state(delta: float) -> int:
	
	match current_movement_state:
		#when idle
		MOVEMENT_STATES.IDLE:
			#-Setup-
			var dir = get_direction()
			velocity.x = 0
			_apply_gravity(delta)
			var snap = Vector2.DOWN*50
			
			#-Movement-
			was_on_floor = check_floor()
			_apply_movement(delta,dir,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			#-Transitions-
			#if moving
			if dir != 0:
				return MOVEMENT_STATES.WALK
				
			#if on air
			if not on_floor:
				#if was on floor, enable coyote time and not change state
				if was_on_floor:
					coyote_timer.start()
				else:
					return MOVEMENT_STATES.FALL
			
			return MOVEMENT_STATES.IDLE
		
		#when walk
		MOVEMENT_STATES.WALK:
			#apply initial walk
			#-Setup-
			var dir = INITIAL_DIRECTION
			_apply_gravity(delta)
			velocity.x = speed*dir
			var snap = Vector2.DOWN*50
			
			#-Movement-
			was_on_floor = check_floor()
			_apply_movement(delta,dir,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			#-Transitions-
			#if player control off
			if auto_timer.is_stopped() and on_floor:
				return MOVEMENT_STATES.IDLE
			
			#if on air
			if not on_floor:
				#if was on floor, enable coyote time and not change state
				if was_on_floor:
					coyote_timer.start()
				else:
					return MOVEMENT_STATES.FALL
			
			return MOVEMENT_STATES.WALK
		
		#when fall
		MOVEMENT_STATES.FALL:
			#-Setup-
			var dir = get_direction()
			_apply_gravity(delta)
			velocity.x = speed*dir
			var snap = Vector2.ZERO
			
			#-Movement-
			was_on_floor = check_floor()
			_apply_movement(delta,dir,snap)
			on_floor = check_floor()
			on_wall = check_wall()
			
			#-Transitions-
			#if against a wall
			if on_wall:
				if dir != 0:
					#if applying movement towards wall
					if wall_normal != Vector2.ZERO and dir*wall_normal.x < 0 and wall_cooldown_timer.is_stopped():
						return MOVEMENT_STATES.WALL
					elif wall_normal.x == 0:
						wall_normal.x = -dir
						#TODO
			
			#if landed
			if on_floor:
				return MOVEMENT_STATES.IDLE
			
			return MOVEMENT_STATES.FALL
			
		#when jump
		MOVEMENT_STATES.JUMP:
			#initial launch
			var dir:= INITIAL_DIRECTION
			if not auto_timer.is_stopped():
				velocity.y = -jump_force
			var snap = Vector2.ZERO
			_apply_gravity(delta)
			was_on_floor = check_floor()
			_apply_movement(delta,dir,snap)
			on_floor = check_floor()
			
			if velocity.y > 0:
				return MOVEMENT_STATES.FALL
			
			return MOVEMENT_STATES.JUMP
	
	return -2


func _initial_action_state(delta: float) -> int:
	return ACTION_STATES.NEUTRAL

func _run_movement_state(delta: float) -> int:

	if not [ACTION_STATES.DEAD,ACTION_STATES.STAGGER,ACTION_STATES.AUTO].has(current_action_state):
		match current_movement_state:
			MOVEMENT_STATES.IDLE:
				#-Setup-
				var dir = get_direction()
				velocity.x = 0
				_apply_gravity(delta)
				var snap = Vector2.DOWN*50
				
				#-Movement-
				was_on_floor = check_floor()
				_apply_movement(delta,dir,snap)
				on_floor = check_floor()
				on_wall = check_wall()
				
				#-Transitions-
				#if moving
				if dir != 0:
					return MOVEMENT_STATES.WALK
					
				#if on air
				if not on_floor:
					#if was on floor, enable coyote time and not change state
					if was_on_floor:
						coyote_timer.start()
					else:
						return MOVEMENT_STATES.FALL
				
				#if pressed jumped previously and on floor
				if not jump_buffer_timer.is_stopped() and on_floor:
					jump_buffer_timer.stop()
					return MOVEMENT_STATES.JUMP
				
				return MOVEMENT_STATES.IDLE
				
			MOVEMENT_STATES.WALK:
				#-Setup-
				var dir = get_direction()
				_apply_gravity(delta)
				velocity.x = speed*dir
				var snap = Vector2.DOWN*50
				
				#-Movement-
				was_on_floor = check_floor()
				_apply_movement(delta,dir,snap)
				on_floor = check_floor()
				on_wall = check_wall()
				
				#-Transitions-
				#if not inputting directions
				if dir == 0 and on_floor:
					return MOVEMENT_STATES.IDLE
				
				#if on air
				if not on_floor:
					#if was on floor, enable coyote time and not change state
					if was_on_floor:
						coyote_timer.start()
					else:
						return MOVEMENT_STATES.FALL
				
				#if pressed jumped previously and on floor
				if not jump_buffer_timer.is_stopped() and on_floor:
					jump_buffer_timer.stop()
					return MOVEMENT_STATES.JUMP
				
				return MOVEMENT_STATES.WALK
				
			MOVEMENT_STATES.FALL:
				#-Setup-
				var dir = get_direction()
				_apply_gravity(delta)
				velocity.x = speed*dir
				var snap = Vector2.ZERO
				
				#-Movement-
				was_on_floor = check_floor()
				_apply_movement(delta,dir,snap)
				on_floor = check_floor()
				on_wall = check_wall()
				
				#-Transitions-
				#if against a wall
				if on_wall:
					if dir != 0:
						#if applying movement towards wall
						if wall_normal != Vector2.ZERO and dir*wall_normal.x < 0 and wall_cooldown_timer.is_stopped():
							return MOVEMENT_STATES.WALL
						elif wall_normal.x == 0:
							wall_normal.x = -dir
							#TODO
				
				#if landed
				if on_floor:
					return MOVEMENT_STATES.IDLE
				
				return MOVEMENT_STATES.FALL
				
			MOVEMENT_STATES.JUMP:
				#-Setup-
				var snap = Vector2.ZERO
				_apply_gravity(delta)
				var dir = get_direction()
				if wall_jump_hold_timer.is_stopped():
					velocity.x = speed*dir
				
				#-Movement-
				was_on_floor = check_floor()
				_apply_movement(delta,dir,snap)
				on_floor = check_floor()
				on_wall = check_wall()
				
				#-Transitions-
				#if peak of jump reached
				if velocity.y > 0:
					return MOVEMENT_STATES.FALL
				
				return MOVEMENT_STATES.JUMP
			
			MOVEMENT_STATES.GDASH:
				#-Setup-
				var snap = Vector2.DOWN*50
				var dir = get_direction()
				#-Movement-
				was_on_floor = check_floor()
				if was_on_floor and on_floor:
					_apply_gravity(delta)
				else:
					velocity.y = 0
				_apply_movement(delta,dir,snap)
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
							return MOVEMENT_STATES.WALK
						else:
							return MOVEMENT_STATES.IDLE
					elif not on_floor and not was_on_floor:
						return MOVEMENT_STATES.FALL
				
				return MOVEMENT_STATES.GDASH
			
			MOVEMENT_STATES.ADASH:
				#-Setup-
				var snap = Vector2.ZERO
				var dir = get_direction()
				#-Movement-
				was_on_floor = check_floor()
				_apply_movement(delta,dir,snap)
				on_floor = check_floor()
				on_wall = check_wall()
				
				#-Transitions-
				#when dash ends
				if dash_timer.is_stopped():
					if on_floor:
						if get_direction() != 0:
							return MOVEMENT_STATES.WALK
						else:
							return MOVEMENT_STATES.IDLE
					else:
						return MOVEMENT_STATES.FALL
				
				return MOVEMENT_STATES.ADASH
			
			MOVEMENT_STATES.WALL:
				#-Setup-
				var snap = -1.5*Globals.TILE_UNITS*wall_normal
				var dir = get_direction()
				velocity.y += 0.1*fall_gravity*delta
				velocity.y = min(velocity.y,0.5*MAX_FALL_TILE*Globals.TILE_UNITS) 
				
				#-Movement-
				was_on_floor = check_floor()
				_apply_movement(delta,dir,snap)
				on_floor = check_floor()
				on_wall = check_wall()
				
				#-Transitions-
				#if moving away from wall
				if wall_slide_timer.is_stopped():
					if get_direction()*wall_normal.x > 0:
						return MOVEMENT_STATES.FALL
				
				#if landed
				if on_floor:
					face_direction = sign(wall_normal.x)
					return MOVEMENT_STATES.IDLE
				
				#if wall ended
				if not on_wall:
					face_direction = sign(wall_normal.x)
					return MOVEMENT_STATES.FALL
				
				#if still on wall
				face_direction = sign(wall_normal.x)
				
				return MOVEMENT_STATES.WALL
	
	#TODO add "ragdoll" when dead
	return -2

func _run_action_state(delta: float) -> int:
	match current_action_state:
		ACTION_STATES.NEUTRAL:
			return ACTION_STATES.NEUTRAL
		ACTION_STATES.ATTACK:
			#wait for shoot animation to fire
			emit_signal("arrow_spawned",arrow_scn,arrow_spawn_point,face_direction)
			return ACTION_STATES.NEUTRAL
		ACTION_STATES.STAGGER:
			
			return ACTION_STATES.NEUTRAL
		ACTION_STATES.DEAD:
			print("should dead")
			
			#wait for death animation ends
			#emit signal dead
			#then queue free
			queue_free()
			#continue ragdoll
			return ACTION_STATES.DEAD
		ACTION_STATES.AUTO:
			#when control must be relinquished
			return ACTION_STATES.NEUTRAL
	return -2

func _exit_action_state(delta: float, current: int) -> void:
	pass

func _exit_movement_state(delta: float, current: int) -> void:
	pass

func die() -> void:
	change_action_state(ACTION_STATES.DEAD)


#-HELPER FUNCTIONS-

#reset variables when landing
func _ground_reset() -> void:
	can_adash = true
	can_ajump = true

#record previous state and change current state
func change_movement_state(next_state: int) -> void:
	previous_frame_movement_state = current_movement_state
	
	if next_state == current_movement_state:
		return
	
	validate_ability(next_state)
	
	previous_movement_state = current_movement_state
	current_movement_state = next_state
	emit_signal("movement_changed",next_state)

#record previous state and change current state
func change_action_state(next_state: int) -> void:
	previous_frame_action_state = current_action_state
	
	if next_state == current_action_state:
		return
	
	previous_action_state = current_action_state
	current_action_state = next_state
	emit_signal("action_changed",next_state)


#check previous state before jump
func _enter_jump() -> void:
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

func validate_ability(next_state: int) -> bool:
	#ability flags
	#DASH DJUMP WALLCLIMB
	var ability_flags: int = actor_stats.move_ability_flags
	match next_state:
		MOVEMENT_STATES.GDASH:
			if ability_flags & 0b100:
				print("should be able to gdash")
		MOVEMENT_STATES.ADASH:
			if ability_flags & 0b100:
				print("should be able to adash")
		MOVEMENT_STATES.JUMP:
			if previous_movement_state == MOVEMENT_STATES.FALL:
				if ability_flags & 0b010:
					print("should be able to djump")
			elif previous_movement_state == MOVEMENT_STATES.WALL:
				if ability_flags & 0b001:
					print("should be able to wjump")
		MOVEMENT_STATES.WALL:
			if ability_flags & 0b001:
				print("should be able to wslide")
	return true

#get current input direction
func get_direction() -> float:
	return Input.get_axis("left","right")

func _face_direction_changes() -> void:
	#debug sprite
	if face_direction > 0:
		sprite.flip_h = false
		arrow_spawn_point.position.x = abs(arrow_spawn_point.position.x)
		particle_pivot.scale.x = 1
	elif face_direction < 0:
		sprite.flip_h = true
		arrow_spawn_point.position.x = -abs(arrow_spawn_point.position.x)
		particle_pivot.scale.x = -1

#check when on floor or coyote is enabled
func check_floor() -> bool:
	var output
	output = is_on_floor()
#	floor_cast.force_raycast_update()
#	output = floor_cast.is_colliding()
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
func _apply_movement(delta: float, dir: float, snap: Vector2) -> void:
	velocity = move_and_slide_with_snap(velocity,snap,Vector2.UP)
	
	if dir == 0:
		return
	else:
		face_direction = -1 if dir < 0 else 1
