extends Position2D

onready var platform:= $MovingPlatform
onready var tween:= $Tween

const idle_time:= 1.5
export var move_to_pos:= Vector2.RIGHT*(10)
export var speed:= 2

var follow:= Vector2.ZERO
var _move_to_pos: Vector2
var _speed: float

func _ready() -> void:
	_speed = speed*Globals.TILE_UNITS
	_move_to_pos = move_to_pos*Globals.TILE_UNITS
	_init_tween()

func _physics_process(delta: float) -> void:
	platform.position = platform.position.linear_interpolate(follow,0.075)

func _init_tween() -> void:
	var duration = _move_to_pos.length()/_speed
	tween.interpolate_property(self,"follow",Vector2.ZERO,_move_to_pos,duration,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,idle_time) 
	tween.interpolate_property(self,"follow",_move_to_pos,Vector2.ZERO,duration,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,duration+idle_time*2)
	tween.start()
	pass
