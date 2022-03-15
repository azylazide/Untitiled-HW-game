extends Area2D

export(float) var xspeed = 10

var velocity:= Vector2.ZERO

func _ready() -> void:
	velocity.x = xspeed*Globals.TILE_UNITS

func _physics_process(delta: float) -> void:
	position += velocity*delta


func _on_Arrow_body_entered(body: Node) -> void:
	queue_free()
	pass # Replace with function body.
