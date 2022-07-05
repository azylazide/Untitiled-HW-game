tool

extends Area2D
class_name CameraBoundBox

func _ready():
	monitoring = false
	set_collision_layer_bit(0,false)
	set_collision_layer_bit(4,true)

