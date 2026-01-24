extends NodeState

@export var player: CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D 


func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	if $"../..".velocity.x == 0:
		animated_sprite_2d.play("idle")
		

func _on_next_transitions() -> void:
	if $"../..".velocity.x <= 0 or $"../..".velocity.x >= 0:
		animated_sprite_2d.play("startRun")
		transition.emit("Run")

func _on_enter() -> void:
	pass


func _on_exit() -> void:
	pass
