extends Area2D

@export var speed: float = 800.0
@export var direction: Vector2 = Vector2(-1, 0)
@export var damage: int = 10

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var hit_particle_scene = preload("res://Scenes/Objects/particle.tscn")

var is_bullet_right: bool = true

# --- 新增：碰撞锁，确保只检测首次碰撞 ---
var has_hit: bool = false

signal rebound_bullet(pos: Vector2, dire: Vector2)

func _process(delta: float) -> void:
	global_position += speed * direction * delta

func get_direction(fire_direction: Vector2):
	direction = fire_direction.normalized()
	# 让子弹贴图指向运动方向
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	# 如果已经碰撞过，直接拦截
	if has_hit:
		return
	
	if "is_player_left" in body:
		has_hit = true # 锁定状态
		if body.rebound:
			direction *= -1
			body.rebound = false
			# 注意：反弹逻辑可能需要重置 has_hit，但通常反弹后的子弹属于新逻辑
			# 这里保持 has_hit 为 true 并销毁旧子弹（play_sound_and_exit）是正确的
			rebound_bullet.emit(global_position, direction)
			play_sound_and_exit()
		else:
			body.hurt(damage - 3)
			spawn_hit_effect()
			play_sound_and_exit()
	
	elif "is_base_left" in body:
		has_hit = true # 锁定状态
		body.hurt(damage)
		spawn_hit_effect()
		play_sound_and_exit()

func _on_area_entered(area):
	# 如果已经碰撞过，直接拦截
	if has_hit:
		return

	if "is_bullet_left" in area:
		has_hit = true # 锁定状态
		spawn_hit_effect()
		play_sound_and_exit()

# --- 核心：处理音效遗言与彻底禁用碰撞 ---
func play_sound_and_exit():
	# 立即禁用碰撞，防止在 queue_free 延迟期间发生二次碰撞
	# 使用 set_deferred 是因为在碰撞回调中不允许直接修改物理状态
	$CollisionShape2D.set_deferred("disabled", true)
	
	if audio_stream_player:
		var main_scene = get_parent()
		remove_child(audio_stream_player)
		main_scene.add_child(audio_stream_player)
		audio_stream_player.play()
		audio_stream_player.finished.connect(audio_stream_player.queue_free)
	
	queue_free()

func spawn_hit_effect():
	if hit_particle_scene:
		var effect = hit_particle_scene.instantiate()
		
		# 传入方向让粒子反向喷射
		if "direction" in effect:
			effect.direction = -direction 
		
		effect.global_position = global_position
		effect.rotation = rotation
		effect.global_position += direction * 5
		
		get_parent().add_child(effect)
