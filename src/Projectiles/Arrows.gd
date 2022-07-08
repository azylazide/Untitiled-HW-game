extends Area2D

export(float) var xspeed = 10

var velocity:= Vector2.ZERO

func _ready() -> void:
	velocity.x = xspeed*Globals.TILE_UNITS

func _physics_process(delta: float) -> void:
	position += velocity*delta

#collided with body
func _on_Arrow_body_entered(body: Node) -> void:
	queue_free()

#entered a hitbox
func _on_Arrow_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("Enemies"):
		print(area.owner)
		area.apply_damage(50)
		queue_free()


