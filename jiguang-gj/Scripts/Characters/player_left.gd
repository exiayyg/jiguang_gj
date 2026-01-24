extends CharacterBody2D

@export var max_health: int = 100
@export var max_energy: int = 100
@export var health: int = 100
@export var energy: int = 100
@export var SPEED = 300.0
@export var JUMP_VELOCITY = -800.0

var is_player_left: bool = true

var hit_particle_scene: PackedScene = preload("res://Scenes/Objects/particle2.tscn")

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var marker: Marker2D = $Marker2D
@onready var rebound_cooldown: Timer = $Timer/rebound_cooldown

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

# 状态追踪
var is_moving: bool = false 
var jump_count: int = 0      
var was_in_air: bool = false 
var can_fire: bool = true
var can_sp: bool = true

@export var marker_base_offset_x: float = 0.0
var has_attack_fired: bool = false
var has_sp_attack_fired: bool = false 
var is_doing_special: bool = false

var guard: bool = false
var rebound: bool = false
var die: bool = false

signal fire(fire_pos: Vector2, fire_direction: Vector2)
signal sp_fire(fire_pos: Vector2, directions: Array) 
signal player_left_died

func _ready() -> void:
	$hud/hp.max_value = max_health
	$hud/mp.max_value = max_energy
	marker_base_offset_x = abs(marker.position.x)

func _physics_process(delta: float) -> void:
	if health <= 0:
		die = true
		velocity.x = 0
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		if sprite.animation != "die":
			sprite.play("die")
		else:
			if not sprite.is_playing():
				player_left_died.emit()
				set_physics_process(false)
		
		move_and_slide()
		return

	# --- 1. 特殊攻击拦截逻辑 ---
	var is_sp_attacking = sprite.animation == "sp_attack" and sprite.is_playing()
	if is_sp_attacking:
		if is_on_floor():
			velocity.x = 0
		else:
			velocity += get_gravity() * delta
			velocity.x = 0
			velocity.y *= 0.5
		
		if sprite.frame == 13 and not has_sp_attack_fired:
			sp_shoot_logic()
			has_sp_attack_fired = true
			
		move_and_slide()
		return

	if sprite.flip_h:
		marker.position.x = -marker_base_offset_x
	else:
		marker.position.x = marker_base_offset_x
	
	# --- 2. 攻击发射逻辑检测与动态调速 ---
	if sprite.animation == "attack":
		if sprite.frame == 7 and not has_attack_fired:
			shoot_logic()
			has_attack_fired = true
			sprite.speed_scale = 1.0 # 发射后恢复原速（后摇变回正常）
	elif sprite.animation == "attack_jump":
		if sprite.frame == 3 and not has_attack_fired:
			shoot_logic()
			has_attack_fired = true
			sprite.speed_scale = 1.0 # 发射后恢复原速
	else:
		# 非攻击状态下确保速度倍率为 1
		if sprite.speed_scale != 1.0:
			sprite.speed_scale = 1.0

	var is_ground_attacking = sprite.animation == "attack" and sprite.is_playing()
	var is_air_attacking = sprite.animation == "attack_jump" and sprite.is_playing()
	
	if is_ground_attacking: 
		velocity.x = 0
		move_and_slide() 
		return 

	if not is_on_floor():
		velocity += get_gravity() * delta
		if is_air_attacking: 
			velocity.y *= 0.5
		was_in_air = true
	else:
		if is_air_attacking:
			if not has_attack_fired:
				velocity.x = 0 
				velocity.y = 0
			else:
				handle_landing_sequence()
		else:
			if was_in_air:
				handle_landing_sequence()

	var is_landing = sprite.animation == "onFloor" and sprite.frame < sprite.sprite_frames.get_frame_count("onFloor") - 1
	var direction := Input.get_axis("Player_Left_left", "Player_Left_right")
	
	if is_landing:
		velocity.x = 0
	else:
		if not (is_on_floor() and is_air_attacking and not has_attack_fired):
			if direction:
				velocity.x = direction * SPEED
				sprite.flip_h = direction < 0
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)

	if Input.is_action_just_pressed("Player_Left_jump") and not is_landing and not is_air_attacking:
		if is_on_floor() or jump_count < 2:
			jump_real()

	handle_animations(direction)
	move_and_slide()
	
	if can_fire:
		if Input.is_action_just_pressed("Player_Left_Shoot") and energy >= 10:
			start_attack(false)
	
	if can_sp and not is_ground_attacking and not is_air_attacking:
		if Input.is_action_just_pressed("Player_Left_SpShoot") and energy >= 30:
			trigger_special_shoot()

func handle_landing_sequence():
	sprite.play("onFloor")
	was_in_air = false
	jump_count = 0

func start_attack(is_special: bool):
	can_fire = false
	energy -= 10
	has_attack_fired = false 
	
	# 实现前摇缩短的关键：启动时播放速度翻倍
	sprite.speed_scale = 2.0
	
	if not is_on_floor():
		sprite.play("attack_jump")
		velocity.y *= 0.5
	else:
		sprite.play("attack")
		
	$Timer/Fire_Cooldown.start()

func trigger_special_shoot():
	can_sp = false
	energy -= 30
	has_sp_attack_fired = false
	sprite.speed_scale = 1.0 # 特殊攻击不享受前摇加速
	
	if not is_on_floor():
		velocity.x = 0 
		velocity.y *= 0.5
		
	sprite.play("sp_attack")
	$Timer/sp_Cooldown.start()

func shoot_logic():
	audio_stream_player.play() 
	var bullet_dir = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	fire.emit(marker.global_position, bullet_dir)
	
	var effect = hit_particle_scene.instantiate()
	effect.global_position = marker.global_position
	get_parent().add_child(effect)

func sp_shoot_logic():
	audio_stream_player.play() 
	var base_dir = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	var dirs = [base_dir, base_dir.rotated(deg_to_rad(-10)), base_dir.rotated(deg_to_rad(10))]
	sp_fire.emit(marker.global_position, dirs)

func jump_real():
	velocity.y = JUMP_VELOCITY
	jump_count += 1
	is_moving = false 
	sprite.play("jump")
	sprite.frame = 0 

func handle_animations(direction: float):
	var currently_moving = direction != 0
	if sprite.animation == "die": return

	if sprite.animation in ["attack", "attack_jump", "sp_attack"]:
		if sprite.is_playing(): return 
		else:
			sprite.speed_scale = 1.0 # 动画结束后强制重置
			if is_on_floor():
				was_in_air = false
				jump_count = 0
				if currently_moving:
					sprite.play("startRun")
					is_moving = true
				else:
					sprite.play("idle")
					is_moving = false
			else:
				sprite.play("down")
			return
	
	if not is_on_floor():
		if velocity.y < 0:
			if sprite.animation != "jump": sprite.play("jump")
		else:
			if sprite.animation == "jump":
				if sprite.frame == sprite.sprite_frames.get_frame_count("jump") - 1:
					sprite.play("down")
			elif sprite.animation != "down":
				sprite.play("down")
		return 

	if sprite.animation == "onFloor":
		if sprite.frame == sprite.sprite_frames.get_frame_count("onFloor") - 1:
			if currently_moving:
				sprite.play("startRun")
				is_moving = true
			else:
				sprite.play("idle")
				is_moving = false
		return 

	if currently_moving and not is_moving:
		sprite.play("startRun")
		is_moving = true
	elif not currently_moving and is_moving:
		sprite.play("stopRun")
		is_moving = false
	
	if sprite.animation == "startRun":
		if sprite.frame == sprite.sprite_frames.get_frame_count("startRun") - 1:
			sprite.play("run")
	elif sprite.animation == "stopRun":
		if sprite.frame == sprite.sprite_frames.get_frame_count("stopRun") - 1:
			sprite.play("idle")
	elif sprite.animation == "run" or sprite.animation == "idle":
		if currently_moving and sprite.animation != "run": sprite.play("run")
		elif not currently_moving and sprite.animation != "idle": sprite.play("idle")

func hurt(damage: int):
	if rebound: pass
	elif guard: guard = false
	else:
		if health > 0: $AnimationPlayer.play("hurt")
		if damage > 5:
			$AnimationPlayer.play("hurt")
			$AudioStreamPlayer2.play()
		health -= damage

func _on_fire_cooldown_timeout() -> void:
	can_fire = true

func _on_sp_cooldown_timeout() -> void:
	can_sp = true

func _on_rebound_cooldown_timeout() -> void:
	rebound = false
