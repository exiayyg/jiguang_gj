extends "res://Scripts/Objects/object.gd"


func _on_area_2d_body_entered(body: Node2D) -> void:
	body.energy = clampi(body.energy + 25, 0, 100)
	queue_free()
