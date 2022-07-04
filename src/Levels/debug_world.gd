extends WorldManager

onready var arrow_scn:= preload("res://src/Projectiles/Arrows.tscn")
onready var camera_bounds = $CameraBounds

var pause = false

var player_camera: Camera2D


func _ready() -> void:
#	$player/ActionSM/Alive/Attack.connect("player_fired", self, "spawn_arrow")
	player_camera = $Player.camera
	pass

func spawn_arrow(pos) -> void:
	var arrow = arrow_scn.instance()
	arrow.position = pos
	add_child(arrow)
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var player = $Player
		player.damage(50)





func _on_CameraBoundBox_CameraBoundBox_entered(tl,tr,bl,br) -> void:
	print("coords: "+"%s,%s,%s,%s" % [tl,tr,bl,br])
	pass # Replace with function body.
