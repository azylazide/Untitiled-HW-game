extends Area2D
class_name CameraBoundBox

onready var BBox = $CollisionShape2D
var shape: RectangleShape2D
var extents: Vector2
var tl: Vector2
var tr: Vector2
var bl: Vector2
var br: Vector2

signal CameraBoundBox_entered(tl,tr,bl,br)
signal CameraBoundBox_exited()

func _ready():
	shape = BBox.shape
	extents = shape.extents
	tl = position+Vector2(-extents.x,-extents.y)
	tr = position+Vector2(extents.x,-extents.y)
	bl = position+Vector2(-extents.x,extents.y)
	br = position+Vector2(extents.x,extents.y)
	
	connect("body_entered",self,"_on_CameraBoundBox_body_entered")
	connect("body_exited",self,"_on_CameraBoundBox_body_exited")
	pass

func _on_CameraBoundBox_body_entered(body: Node) -> void:
	emit_signal("CameraBoundBox_entered",tl,tr,bl,br)
	pass # Replace with function body.

func _on_CameraBoundBox_body_exited(body: Node) -> void:
	emit_signal("CameraBoundBox_exited")
	pass # Replace with function body.
