#General script for actors in the game
#eg. the player, enemies
class_name ActorBase

extends KinematicBody2D

export(Resource) var player_stats

export(float) var MAX_FALL_TILE = 15.0
export(float) var MAX_WALK_TILE = 6.25
export(float) var JUMP_HEIGHT = 5.5
export(float) var MIN_JUMP_HEIGHT = 0.5
export(float) var GAP_LENGTH = 12.5

var velocity:= Vector2.ZERO
var speed: float
var direction: float
var face_direction: float
var jump_force: float

var health: float

func _process(delta: float) -> void:
	health = player_stats.health
	print(health)
