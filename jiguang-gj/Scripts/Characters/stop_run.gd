extends NodeState

@export var player: CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D 

var can_break: bool = true

func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	pass
		
	

func _on_next_transitions() -> void:
	if !animated_sprite_2d.is_playing():
		transition.emit("idle")


func _on_enter() -> void:
	animated_sprite_2d.play("stopRun")


func _on_exit() -> void:
	animated_sprite_2d.stop()
