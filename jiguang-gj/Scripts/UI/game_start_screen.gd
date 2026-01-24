extends Control


func _on_start_pressed() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(0.0, 0.0, 0.0), 1)
	await tween.finished
	get_tree().change_scene_to_file("res://Scenes/UI/manhua.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
