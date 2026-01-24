extends CharacterBody2D

# --- 属性设置 ---
@export var max_health: int = 100
@export var max_energy: int = 100
@export var health: int = 100
@export var energy: int = 100
@export var SPEED = 300.0
@export var JUMP_VELOCITY = -800.0

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var marker: Marker2D = $Marker2D
@onready var rebound_cooldown: Timer = $Timer/rebound_cooldown
var die: bool = false
# 粒子场景：请确保 particle.tscn 里的 Angle Min/Max 已设为 0-360
var hit_particle_scene = preload("res://Scenes/Objects/particle.tscn")

var is_player_right: bool = true

var marker_base_offset_x: float = 0.0
var current_frame_index: int = 0

# --- 状态变量 ---
var is_moving: bool = false 
var jump_count: int = 0  
var was_in_air: bool = false 
var can_fire: bool = true
var can_sp: bool = true # 新增：特殊攻击冷却状态
var has_attack_fired: bool = false
var has_sp_attack_fired: bool = false # 特殊攻击发射标记

var guard: bool = false
var rebound: bool = false

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


# --- 信号 ---
signal fire(fire_pos: Vector2, fire_direction: Vector2)
signal sp_fire(fire_pos: Vector2, directions: Array)
signal player_right_died

func _ready() -> void:
	$hud/hp.max_value = max_health
	$hud/mp.max_value = max_energy
	marker_base_offset_x = abs(marker.position.x)

func _physics_process(delta: float) -> void:
	# --- 0. 死亡拦截：死亡后不接受任何输入 ---
	if health <= 0:
		die = true
		velocity.x = 0
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		if sprite.animation != "die":
			sprite.play("die")
		elif not sprite.is_playing():
			player_right_died.emit()
			set_physics_process(false) # 彻底停止物理处理
			
		move_and_slide()
		return # 直接返回，拦截所有后续镜像、攻击、移动检测逻辑

	# 1. 镜像处理
	if sprite.flip_h:
		marker.position.x = -marker_base_offset_x - 60
	else:
		marker.position.x = marker_base_offset_x

	# 2. 攻击帧检测逻辑
	check_attack_frames()

	# 3. 状态判定
	var is_attacking = sprite.animation == "attack" and sprite.is_playing()
	var is_air_attacking = sprite.animation == "attack_jump" and sprite.is_playing()
	var is_sp_attacking = sprite.animation == "sp_attack" and sprite.is_playing()

	# 4. 移动与重力处理
	if (is_attacking or is_sp_attacking) and is_on_floor():
		velocity.x = 0
	elif not is_on_floor():
		velocity += get_gravity() * delta
		if is_attacking or is_air_attacking or is_sp_attacking:
			velocity.y *= 0.5
			velocity.x *= 0.5
		was_in_air = true
	else:
		if was_in_air:
			handle_landing_sequence()

	# 5. 左右移动逻辑
	var is_landing = sprite.animation == "onFloor" and sprite.is_playing()
	var direction := Input.get_axis("Player_Right_left", "Player_Right_right")
	
	if not (is_attacking or is_sp_attacking or is_landing):
		if direction != 0:
			velocity.x = direction * SPEED
			sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# 6. 跳跃逻辑
	if Input.is_action_just_pressed("Player_Right_jump") and not is_landing and not is_sp_attacking:
		if is_on_floor() or jump_count < 2:
			jump_real()

	# 7. 动画与战斗输入
	handle_animations(direction)
	move_and_slide()
	
	if can_fire:
		if Input.is_action_just_pressed("Player_Right_Shoot") and energy >= 10:
			start_attack()
	
	if can_sp: # 使用独立冷却判断
		if Input.is_action_just_pressed("Player_Right_SpShoot") and energy >= 30:
			trigger_special_shoot()

# 检测动画具体帧并触发信号
func check_attack_frames():
	match sprite.animation:
		"attack":
			if sprite.frame >= 24 and not has_attack_fired:
				shoot_logic()
				has_attack_fired = true
		"attack_jump":
			if sprite.frame >= 3 and not has_attack_fired:
				shoot_logic()
				has_attack_fired = true
		"sp_attack":
			if sprite.frame >= 11 and not has_sp_attack_fired:
				sp_shoot_logic()
				has_sp_attack_fired = true

# 普通攻击启动
func start_attack():
	can_fire = false
	energy -= 10
	has_attack_fired = false 
	if not is_on_floor():
		sprite.play("attack_jump")
	else:
		sprite.play("attack")
	$Timer/Fire_Colldown.start()

# 特殊攻击启动
func trigger_special_shoot():
	can_sp = false # 消耗特殊攻击冷却
	energy -= 30
	has_sp_attack_fired = false
	sprite.play("sp_attack")
	
	if not is_on_floor():
		velocity.y *= 0.5 
		velocity.x = 0 # 类似左侧角色逻辑，空中释放时清除水平惯性
	
	$Timer/sp_Cooldown.start() # 使用独立计时器

func shoot_logic():
	audio_stream_player.play() 
	var bullet_dir = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	fire.emit(marker.global_position, bullet_dir)
	spawn_effect()

func sp_shoot_logic():
	audio_stream_player.play() 
	var base_dir = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	var dirs = [
		base_dir,
		base_dir.rotated(deg_to_rad(-10)),
		base_dir.rotated(deg_to_rad(10))
	]
	sp_fire.emit(marker.global_position, dirs)
	spawn_effect()

# 生成粒子
func spawn_effect():
	var effect = hit_particle_scene.instantiate()
	effect.global_position = marker.global_position
	get_parent().add_child(effect)

func handle_landing_sequence():
	sprite.play("onFloor")
	was_in_air = false
	jump_count = 0

func jump_real():
	velocity.y = JUMP_VELOCITY
	jump_count += 1
	is_moving = false 
	sprite.play("jump")
	sprite.frame = 0 

func handle_animations(direction: float):
	var currently_moving = direction != 0
	
	if sprite.animation == "die":
		return

	if sprite.animation in ["attack", "attack_jump", "sp_attack"]:
		if sprite.is_playing():
			return 
		else:
			if is_on_floor():
				if currently_moving: sprite.play("run")
				else: sprite.play("idle")
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
			if currently_moving: sprite.play("run")
			else: sprite.play("idle")
		return 

	if currently_moving:
		if sprite.animation != "run" and sprite.animation != "startRun":
			sprite.play("startRun")
			is_moving = true
		if sprite.animation == "startRun" and sprite.frame == sprite.sprite_frames.get_frame_count("startRun") - 1:
			sprite.play("run")
	else:
		if is_moving:
			sprite.play("stopRun")
			is_moving = false
		if sprite.animation == "stopRun" and sprite.frame == sprite.sprite_frames.get_frame_count("stopRun") - 1:
			sprite.play("idle")
		elif sprite.animation != "stopRun":
			sprite.play("idle")

func hurt(damage: int):
	if rebound: 
		pass
	elif guard:
		guard = false
	else: 
		if health > 0:
			$AnimationPlayer.play("hurt")
		if damage > 5:
			$AnimationPlayer.play("hurt")
			$AudioStreamPlayer2.play()
		health -= damage

func _on_fire_colldown_timeout() -> void:
	can_fire = true

func _on_sp_cooldown_timeout() -> void:
	can_sp = true # 特殊攻击冷却结束

func _on_rebound_cooldown_timeout() -> void:
	rebound = false
