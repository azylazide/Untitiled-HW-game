extends WorldManager

var pause = false

func _ready() -> void:
	SignalBus.connect("projectile_spawned",self,"spawn_arrow")
	pass

func spawn_arrow(arrow_scn: PackedScene, spawn_point: Position2D, facing: float) -> void:
	var arrow = arrow_scn.instance()
	arrow.global_position = spawn_point.global_position
	arrow.facing = facing
	
	#check if location is occupied
	var space: Physics2DDirectSpaceState = get_world_2d().direct_space_state
	var shape_query:= Physics2DShapeQueryParameters.new()
	var spawn_checker = arrow.get_node("SpawnChecker/CollisionShape2D")
	shape_query.set_shape(spawn_checker.shape)
	shape_query.transform.origin = arrow.transform.origin
	shape_query.transform.origin.x += spawn_checker.position.x*sign(facing)
	shape_query.set_collision_layer(1)
	var intersecting_shapes:= space.intersect_shape(shape_query,20)
	if intersecting_shapes.empty():
		add_child(arrow)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var player = $Player
		player.heal(50)
	if event.is_action_pressed("debug_kill"):
		var player = $Player
		player.damage(100)
