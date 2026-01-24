extends "res://Scripts/Objects/object.gd"


func _on_area_2d_body_entered(body: Node2D) -> void:
	body.rebound = true
	body.rebound_cooldown.start()
	queue_free()
