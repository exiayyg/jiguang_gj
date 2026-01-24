extends NodeState

@export var player: CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D 

var direction: Vector2

func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	if Input.is_action_pressed("Player_Left_left"):
		direction = Vector2.LEFT
	elif Input.is_action_pressed("Player_Left_right"):
		direction = Vector2.RIGHT
	else :
		direction = Vector2.ZERO


func _on_next_transitions() -> void:
	if direction == Vector2.ZERO:
		animated_sprite_2d.play("stopRun")


func _on_enter() -> void:
	animated_sprite_2d.play("run")


func _on_exit() -> void:
	animated_sprite_2d.stop()
