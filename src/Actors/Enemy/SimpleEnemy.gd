extends ActorBase


enum MOVEMENT_STATES {IDLE,WALK}
export(MOVEMENT_STATES) var current_movement_state = MOVEMENT_STATES.IDLE

enum ACTION_STATES {NEUTRAL,ATTACK,DEAD}
export(ACTION_STATES) var current_action_state = ACTION_STATES.NEUTRAL

var previous_movement_state:= -1
var previous_action_state:= -1

func _ready() -> void:
	speed = MAX_WALK_TILE*Globals.TILE_UNITS
	pass


func _physics_process(delta: float) -> void:
	
	match current_movement_state:
		MOVEMENT_STATES.IDLE:
			pass
		
		MOVEMENT_STATES.WALK:
			velocity.x = speed
			move_and_slide(velocity)
			pass
	
	
	pass
