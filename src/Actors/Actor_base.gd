#General script for actors in the game
#eg. the player, enemies
class_name ActorBase

extends KinematicBody2D

export(Resource) var actor_stats

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

signal death()

func _process(delta: float) -> void:
	if actor_stats.health == 0:
		emit_signal("death")
		#replace with logic to tell the inherited classes to die
		queue_free()
	pass

func damage(amount: float) -> void:
	actor_stats.health -= amount

func heal(amount: float) -> void:
	actor_stats.health += amount
