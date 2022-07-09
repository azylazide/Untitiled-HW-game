extends Area2D

export(float) var xspeed = 50

var facing:= 1.0

var velocity:= Vector2.ZERO

onready var sprite:= $Sprite
onready var spawn_checker:= $SpawnChecker

func _ready() -> void:
	
	if facing >= 0:
		scale.x = 1
	else:
		scale.x = -1

	velocity.x = xspeed*facing*Globals.TILE_UNITS

func _physics_process(delta: float) -> void:
	#TODO check if colliding at spawn
	
	position += velocity*delta

#collided with body
func _on_Arrow_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		return
	queue_free()

#entered a hitbox
func _on_Arrow_area_entered(area: Area2D) -> void:
	_hurt_enemy(area)

func _hurt_enemy(area: Area2D) -> void:
	if area.owner.is_in_group("Enemies"):
		print(area.owner)
		area.apply_damage(50)
		queue_free()


func _on_VisibilityNotifier2D_screen_exited() -> void:
	queue_free()
	pass # Replace with function body.
