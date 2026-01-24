extends NodeState

@export var player: CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D 


func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	if Input.is_action_just_pressed("Player_Left_left") or Input.is_action_just_pressed("Player_Left_right"):
		animated_sprite_2d.play("startRun")


func _on_next_transitions() -> void:
	if !animated_sprite_2d.is_playing():
		transition.emit("Run")


func _on_enter() -> void:
	pass


func _on_exit() -> void:
	animated_sprite_2d.stop()
