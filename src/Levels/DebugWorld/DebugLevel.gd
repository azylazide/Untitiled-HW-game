extends WorldManager

onready var arrow_scn:= preload("res://src/Projectiles/Arrows.tscn")

var pause = false

func _ready() -> void:
	$Player.connect("arrow_spawned",self,"spawn_arrow")
	pass

func spawn_arrow(spawn_point: Position2D, facing: float) -> void:
	var arrow = arrow_scn.instance()
	arrow.global_position = spawn_point.global_position
	arrow.facing = facing
	add_child(arrow)
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var player = $Player
		player.heal(50)
	if event.is_action_pressed("debug_kill"):
		var player = $Player
		player.damage(100)
