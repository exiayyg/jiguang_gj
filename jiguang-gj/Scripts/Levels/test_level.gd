extends Node2D

# --- 音乐循环逻辑 ---
@onready var bgm_player: AudioStreamPlayer = $AudioStreamPlayer2
var is_looping: bool = false
var loop_start_time: float = 2.44 

var left_bullets_scene: PackedScene = preload("res://Scenes/Bullets/left_bullet.tscn")
var righr_bullets_scene: PackedScene = preload("res://Scenes/Bullets/right_bullet.tscn")

var energy_ball_scene: PackedScene = preload("res://Scenes/Objects/energy.tscn")
var rebound_ball_scene: PackedScene = preload("res://Scenes/Objects/rebound.tscn")
var guard_ball_scene: PackedScene = preload("res://Scenes/Objects/guard.tscn")
var health_ball_scene: PackedScene = preload("res://Scenes/Objects/health.tscn")

var can_create_object: bool = true

var left_ava: Texture2D = preload("res://Assets/BackGround/赤焰胜利画面.png")
var right_ava: Texture2D = preload("res://Assets/BackGround/白雪胜利结算画面.png")
var left_eva: Texture2D = preload("res://Assets/BackGround/优化图片 (赤焰).png")
var right_eva: Texture2D = preload("res://Assets/BackGround/优化图片（白雪）.png")

var right_base_die: bool = false
var left_base_die: bool = false
var die_time_left: bool = false
var die_time_right: bool = false

@onready var player_left: CharacterBody2D = $Player/PlayerLeft
@onready var player_right: CharacterBody2D = $Player/Player_Right
@onready var base_left: StaticBody2D = $Base/Base_Left
@onready var base_right: StaticBody2D = $Base/Base_Right

func _ready() -> void:
	player_left.global_position = $Mark/Left_point.global_position
	player_right.global_position = $Mark/Right_point.global_position
	base_left.global_position = $Mark/base_left.global_position
	base_right.global_position = $Mark/base_right.global_position
	
	#if bgm_player:
		#bgm_player.play()
	
	if not player_left.sp_fire.is_connected(_on_player_left_sp_fire):
		player_left.sp_fire.connect(_on_player_left_sp_fire)
	if not player_right.sp_fire.is_connected(_on_player_right_sp_fire):
		player_right.sp_fire.connect(_on_player_right_sp_fire)
	
	player_left.fire.connect(_on_player_left_fire)
	player_right.fire.connect(_on_player_right_fire)

func _process(_delta: float) -> void:
	#if bgm_player and bgm_player.playing:
		#var current_pos = bgm_player.get_playback_position()
		#var stream_length = bgm_player.stream.get_length()
		#if current_pos >= stream_length - 0.02:
			#bgm_player.seek(loop_start_time)
	$Node/AudioStreamPlayer2.play()

func _physics_process(_delta: float) -> void:
	if can_create_object:
		create_objects()
		can_create_object = false
		$Objects/Timer.start()
	
	#if die_time_left:
		#player_left.hurt(5)
		#die_time_left = false
		#$Base/Left.start()
		
	#if die_time_right:
		#player_right.hurt(5)
		#die_time_right = false
		#$Base/Right.start()

func _on_player_left_sp_fire(fire_pos: Vector2, directions: Array) -> void:
	for i in range(directions.size()):
		var bullet = left_bullets_scene.instantiate()
		bullet.global_position = fire_pos
		$Left_Bullets.add_child(bullet)
		bullet.get_direction(directions[i])
		if bullet.has_signal("rebound_bullet"):
			bullet.rebound_bullet.connect(_on_left_bullet_rebound)

func _on_player_right_sp_fire(fire_pos: Vector2, directions: Array) -> void:
	for i in range(directions.size()):
		var bullet = righr_bullets_scene.instantiate()
		bullet.global_position = fire_pos
		$Right_Bullets.add_child(bullet)
		bullet.get_direction(directions[i])
		if bullet.has_signal("rebound_bullet"):
			bullet.rebound_bullet.connect(_on_right_bullet_rebound)

func _on_player_left_fire(fire_pos: Vector2, fire_direction: Vector2) -> void:
	var bullet = left_bullets_scene.instantiate()
	bullet.global_position = fire_pos
	$Left_Bullets.add_child(bullet)
	bullet.get_direction(fire_direction)
	bullet.rebound_bullet.connect(_on_left_bullet_rebound)

func _on_player_right_fire(fire_pos: Vector2, fire_direction: Vector2) -> void:
	var bullet = righr_bullets_scene.instantiate()
	bullet.global_position = fire_pos
	$Right_Bullets.add_child(bullet)
	bullet.get_direction(fire_direction)
	bullet.rebound_bullet.connect(_on_right_bullet_rebound)

func _on_left_bullet_rebound(pos: Vector2, dir: Vector2) -> void:
	var bullet = righr_bullets_scene.instantiate()
	bullet.global_position = pos
	$Right_Bullets.add_child(bullet)
	bullet.get_direction(dir)
	bullet.rebound_bullet.connect(_on_right_bullet_rebound)

func _on_right_bullet_rebound(pos: Vector2, dir: Vector2) -> void:
	var bullet = left_bullets_scene.instantiate()
	bullet.global_position = pos
	$Left_Bullets.add_child(bullet)
	bullet.get_direction(dir)
	bullet.rebound_bullet.connect(_on_left_bullet_rebound)

# --- 修改后的生成逻辑 ---
func create_objects():
	var random_range: Vector2 = Vector2(randf_range(340, 1580), -100)
	var object: Node
	
	if left_base_die and right_base_die:
		object = energy_ball_scene.instantiate()
	else:
		var random_select = randi_range(0, 3) # 确保是 0, 1, 2, 3
		match random_select:
			0: object = energy_ball_scene.instantiate()
			1: object = guard_ball_scene.instantiate()
			2: object = rebound_ball_scene.instantiate()
			3: 
				if health_ball_scene: # 安全检查
					object = health_ball_scene.instantiate()
				else:
					object = energy_ball_scene.instantiate() # 备选方案
		
	if object:
		object.global_position = random_range
		$Objects.add_child(object)

func GameEvaluate():
	get_tree().change_scene_to_file("res://Scenes/UI/game_evaluate.tscn")

func _on_timer_timeout() -> void:
	can_create_object = true

func _on_base_left_left_base_died() -> void:
	left_base_die = true
	if right_base_die:
		$Objects/Timer.wait_time = 2
	$Base/Left.start()

func _on_base_right_right_base_died() -> void:
	right_base_die = true
	if left_base_die:
		$Objects/Timer.wait_time = 2
	$Base/Right.start()

func _on_left_timeout() -> void: 
	die_time_left = true
func _on_right_timeout() -> void: 
	die_time_right = true

func _on_player_left_player_left_died(): 
	Global.ava = right_ava; Global.eva = right_eva; Global.winner = 1
	GameEvaluate()
	
func _on_player_right_player_right_died(): 
	Global.ava = left_ava; Global.eva = left_eva; Global.winner = 2
	GameEvaluate()
