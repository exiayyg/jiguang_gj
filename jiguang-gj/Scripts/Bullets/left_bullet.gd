extends Area2D

@export var speed: float = 800.0
@export var direction: Vector2 = Vector2(1, 0)
@export var damage: int = 10

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var hit_particle_scene: PackedScene = preload("res://Scenes/Objects/particle2.tscn")

signal rebound_bullet(pos: Vector2, dire: Vector2)

var is_bullet_left: bool = true

# --- 新增：确保只检测首次碰撞的标记 ---
var has_hit: bool = false

func _process(delta: float) -> void:
	global_position += speed * direction * delta

func get_direction(fire_direction: Vector2):
	direction = fire_direction.normalized()
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	# 如果已经发生过碰撞，直接拦截
	if has_hit:
		return
	
	if "is_player_right" in body:
		has_hit = true # 标记已碰撞
		if body.rebound:
			direction *= -1
			body.rebound = false
			rebound_bullet.emit(global_position, direction)
			play_sound_and_exit()
			return 
		else:
			body.hurt(damage - 3)
			spawn_hit_effect()
			play_sound_and_exit()
	
	elif "is_base_right" in body:
		has_hit = true # 标记已碰撞
		body.hurt(damage)
		spawn_hit_effect()
		play_sound_and_exit()

func _on_area_entered(area):
	# 如果已经发生过碰撞，直接拦截
	if has_hit:
		return
		
	if "is_bullet_right" in area:
		has_hit = true # 标记已碰撞
		spawn_hit_effect()
		play_sound_and_exit()

# --- 专门处理“遗言”音效的方法 ---
func play_sound_and_exit():
	# 禁用碰撞形状，确保物理引擎不再计算此子弹
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
		
		# 传入粒子方向（反向散射）
		if "direction" in effect:
			effect.direction = -direction
		
		effect.global_position = global_position 
		effect.rotation = rotation 
		effect.global_position += direction * 5 
		get_parent().add_child(effect)
