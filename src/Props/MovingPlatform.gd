extends Position2D

onready var platform:= $MovingPlatform
onready var tween:= $Tween

const idle_time:= 1.5
export var move_to_pos:= Vector2.RIGHT*(10*Globals.TILE_UNITS)
export var speed:= 2*Globals.TILE_UNITS

var follow:= Vector2.ZERO

func _ready() -> void:
	_init_tween()

func _physics_process(delta: float) -> void:
	platform.position = platform.position.linear_interpolate(follow,0.075)

func _init_tween() -> void:
	var duration = move_to_pos.length()/speed
	tween.interpolate_property(self,"follow",Vector2.ZERO,move_to_pos,duration,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,idle_time) 
	tween.interpolate_property(self,"follow",move_to_pos,Vector2.ZERO,duration,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,duration+idle_time*2)
	tween.start()
	pass
