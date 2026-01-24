extends Area2D

@export var speed: float = 800.0
@export var direction: Vector2 = Vector2(1, 0)
@export var damage: int = 10

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer



var hit_particle_scene: PackedScene = preload("res://Scenes/Objects/particle2.tscn")


signal rebound_bullet(pos: Vector2, dire: Vector2)

var is_bullet_left: bool = true

func _process(delta: float) -> void:
	global_position += speed * direction * delta

func get_direction(fire_direction: Vector2):
	direction = fire_direction.normalized()
	# 让子弹贴图旋转至飞行方向
	rotation = direction.angle()
	print(direction, "    ", rotation)
	# 如果贴图水平镜像有问题，可以在此根据 direction.x 调整 flip_v/h

func _on_body_entered(body: Node2D) -> void:
	if "is_player_right" in body:
		if body.rebound:
			direction *= -1
			body.rebound = false
			rebound_bullet.emit(global_position, direction)
			audio_stream_player.play()
			queue_free()
		else:
			body.hurt(damage - 3)
			spawn_hit_effect()
			audio_stream_player.play()
			queue_free()
	
	if "is_base_right" in body:
		body.hurt(damage)
		spawn_hit_effect()
		audio_stream_player.play()
		queue_free()

func _on_area_entered(area):
	if "is_bullet_right" in area:
		spawn_hit_effect()
		audio_stream_player.play()
		queue_free()



func spawn_hit_effect():
	var effect = hit_particle_scene.instantiate()
	effect.global_position = $CollisionShape2D.global_position
	
	# 如果子弹图片是水平向右的，self.rotation 就是速度方向
	effect.rotation = $CollisionShape2D.rotation 
	
	# 稍微把粒子往子弹飞行方向的前方挪一点，防止陷在墙里
	effect.global_position += transform.x * 5 
	
	get_parent().add_child(effect)
