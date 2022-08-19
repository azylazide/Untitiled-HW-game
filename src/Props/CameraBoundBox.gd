tool

extends Area2D
class_name CameraBoundBox

export(bool) var limit_left = true
export(bool) var limit_top = true
export(bool) var limit_right = true
export(bool) var limit_bottom = true

export(int) var priority_level = 0

func _init():
	monitoring = false
	set_collision_layer_bit(0,false)
	set_collision_layer_bit(4,true)

