extends Control

func _ready() -> void:
	$TextureRect.texture = Global.ava
	$TextureRect2.texture = Global.eva
	if Global.winner == 1:
		$snow.play()
	else:
		$fire.play()

func _on_start_pressed() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(0.0, 0.0, 0.0), 1)
	await tween.finished
	get_tree().change_scene_to_file("res://Scenes/Levels/test_level.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
