extends WorldManager

onready var arrow_scn:= preload("res://src/Projectiles/Arrows.tscn")

var pause = false

func _ready() -> void:
	$player/ActionSM/Alive/Attack.connect("player_fired", self, "spawn_arrow")
	pass

func spawn_arrow(pos) -> void:
	var arrow = arrow_scn.instance()
	arrow.position = pos
	add_child(arrow)
	pass

