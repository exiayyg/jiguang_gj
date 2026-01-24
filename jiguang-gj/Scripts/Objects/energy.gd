extends "res://Scripts/Objects/object.gd"




func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.energy <= 90:
		body.energy += 10
	elif body.energy > 90 and body.energy < 100:
		body.energy = 100
	queue_free()
