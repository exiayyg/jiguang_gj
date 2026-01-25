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
	
	if not player_left.sp_fire.is_connected(_on_player_left_sp_fire):
		player_left.sp_fire.connect(_on_player_left_sp_fire)
	if not player_right.sp_fire.is_connected(_on_player_right_sp_fire):
		player_right.sp_fire.connect(_on_player_right_sp_fire)
	
	player_left.fire.connect(_on_player_left_fire)
	player_right.fire.connect(_on_player_right_fire)

func _process(_delta: float) -> void:
	# 修复：原代码物理处理中有 play() 可能导致音效重叠，建议放在 ready 启动
	# $Node/AudioStreamPlayer2.play() 
	pass

func _physics_process(_delta: float) -> void:
	if can_create_object:
		create_objects()
		can_create_object = false
		$Objects/Timer.start()

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

# --- 核心逻辑：掉落概率调整 ---
func create_objects():
	var random_pos: Vector2 = Vector2(randf_range(340, 1580), -100)
	var object: Node = null
	
	# 1. 双方基地都被摧毁：只掉落能量球
	if left_base_die and right_base_die:
		object = energy_ball_scene.instantiate()
	
	# 2. 仅有一方基地被摧毁：能量球掉落概率翻倍
	elif left_base_die or right_base_die:
		# 原概率：能量 1/4 (25%)，其他 3/4 (75%)
		# 翻倍后：能量 2/5 (40%) 或者更简单的权重判断：
		var rand_val = randi_range(0, 6) # 生成 0-4 (共5个数字)
		match rand_val:
			0, 1, 2, 3: object = energy_ball_scene.instantiate() # 2/5 概率 (40%)
			4: object = guard_ball_scene.instantiate()
			5: object = rebound_ball_scene.instantiate()
			6: object = health_ball_scene.instantiate() if health_ball_scene else energy_ball_scene.instantiate()
	
	# 3. 双方基地都在：平均掉落
	else:
		var random_select = randi_range(0, 3) 
		match random_select:
			0: object = energy_ball_scene.instantiate()
			1: object = guard_ball_scene.instantiate()
			2: object = rebound_ball_scene.instantiate()
			3: object = health_ball_scene.instantiate() if health_ball_scene else energy_ball_scene.instantiate()
		
	if object:
		object.global_position = random_pos
		$Objects.add_child(object)

func GameEvaluate():
	get_tree().change_scene_to_file("res://Scenes/UI/game_evaluate.tscn")

func _on_timer_timeout() -> void:
	can_create_object = true

func _on_base_left_left_base_died() -> void:
	left_base_die = true
	# 基地摧毁时不仅概率改变，还可以加快掉落速度
	$Objects/Timer.wait_time = 2.0 if right_base_die else 3.0
	$Base/Left.start()

func _on_base_right_right_base_died() -> void:
	right_base_die = true
	$Objects/Timer.wait_time = 2.0 if left_base_die else 3.0
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
