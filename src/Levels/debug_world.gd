extends WorldManager

onready var arrow_scn:= preload("res://src/Projectiles/Arrows.tscn")

var pause = false

func _ready() -> void:
#	$player/ActionSM/Alive/Attack.connect("player_fired", self, "spawn_arrow")
	pass

func spawn_arrow(pos) -> void:
	var arrow = arrow_scn.instance()
	arrow.position = pos
	add_child(arrow)
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var playerstats = $Player.player_stats
		print(playerstats.get_property_list())
