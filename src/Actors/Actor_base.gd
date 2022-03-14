#General script for actors in the game
#eg. the player, enemies
class_name ActorBase

extends KinematicBody2D

export(float) var MAX_FALL_TILE = 15.0
export(float) var MAX_WALK_TILE = 6.25
export(float) var JUMP_HEIGHT = 5.5

var velocity:= Vector2.ZERO
var direction: float
var face_direction: float
var jump_force: float

