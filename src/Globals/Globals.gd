extends Node

#size of tile units in px/tile
const TILE_UNITS:= 64.0

enum move_states {IDLE,WALK,FALL,JUMP,GDASH,ADASH,WALL}
enum action_states {NEUTRAL,ATTACK,STAGGER,DEAD,AUTO}

#static helper functions
func _gravity(h: float, vx: float, x: float) -> float:
	var output: float = 2*(h*TILE_UNITS*pow(vx*TILE_UNITS,2))/(pow(x*TILE_UNITS/2.0,2))
	return output

func _jump_vel(walk_length: float, h: float, x: float) -> float:
	var output: float = (2*h*TILE_UNITS*walk_length*TILE_UNITS)/(x*TILE_UNITS/2.0)
	return output

func _dash_speed(dash_length: float, dash_time: float) -> float:
	return dash_length*TILE_UNITS/dash_time
	
func _wall_kick(wall_kick_power: float, wall_kick_time: float):
	return wall_kick_power*TILE_UNITS/wall_kick_time

func player_move_state_name(state: int) -> String:
	
	match state:
		move_states.IDLE:
			return "IDLE"
		move_states.WALK:
			return "WALK"
		move_states.FALL:
			return "FALL"
		move_states.JUMP:
			return "JUMP"
		move_states.GDASH:
			return "GDASH"
		move_states.ADASH:
			return "ADASH"
		move_states.WALL:
			return "WALL"
	return ""

func player_action_state_name(state: int) -> String:
	
	match state:
		action_states.NEUTRAL:
			return "NEUTRAL"
		action_states.ATTACK:
			return "ATTACK"
		action_states.STAGGER:
			return "STAGGER"
		action_states.DEAD:
			return "DEAD"
		action_states.AUTO:
			return "AUTO"
	return ""
