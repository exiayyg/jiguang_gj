extends CanvasLayer
class_name GameHUD

# --- 全局静态单例 ---
static var instance: GameHUD

# --- 信号 ---
## 动画效果执行
signal health_depleted_animation_finished
## 生命值发生改变
signal health_changed(current_hp: int, max_hp: int)

# --- 节点绑定 ---
@onready var avatar_rect: TextureRect = $PlayerContainer/PlayerPanel/Flex/PlayerAvatar/PlayerAvatarRect
@onready var name_label: Label = $PlayerContainer/PlayerPanel/Flex/PlayerInfoBox/PlayerNameLabel
@onready var level_label: Label = $PlayerContainer/PlayerPanel/Flex/PlayerInfoBox/PlayerLevelLabel
@onready var health_bar: ProgressBar = $PlayerContainer/PlayerPanel/Flex/PlayerInfoBox/LifebloodContainer/LifeBar
@onready var health_nums_label: Label = $PlayerContainer/PlayerPanel/Flex/PlayerInfoBox/LifebloodContainer/LifeBar/LifeNumsLabel
@onready var kill_enemy_count: Label = $KillEnemyCount
# --- 内部状态 ---
var _max_hp: int = 3
var _current_hp: int = 3
var _player_level: int = 1

# --- 生命周期 ---
func _enter_tree() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	setup_kill_count_display()
	# 【调试开关】如果是独立运行此场景，自动开始测试
	# OS.has_feature("editor") 确保只在编辑器环境下运行测试，打包发布后自动失效
	if get_parent() == get_tree().root and OS.has_feature("editor"):
		print("--- 检测到单独运行 HUD 场景，开始自动化测试 ---")
		run_debug_test()

# --- 公共 API ---

## 初始化玩家信息
## 用法: GameHUD.instance.setup_player("Hero", 1, 5)
func setup_player(player_name: String, level: int, max_hp: int, avatar: Texture2D = null) -> void:
	
	_player_level = level
	
	name_label.text = "Player:%s" % player_name
	level_label.text = "Level.%d" % level
	if avatar:
		avatar_rect.texture = avatar
	update_health(max_hp, max_hp, false)


## 更新血量
## 用法: GameHUD.instance.update_health(current_hp)
## animate: 是否播放过渡动画 (默认 true)
func update_health(new_hp: int, new_max_hp: int = -1, animate: bool = true) -> void:
	if new_max_hp > 0:
		_max_hp = new_max_hp
	
	_current_hp = clampi(new_hp, 0, _max_hp)
	
	health_changed.emit(_current_hp, _max_hp)
	
	health_bar.max_value = _max_hp
	health_nums_label.text = "%d/%d" % [_current_hp, _max_hp]
	
	if animate:
		_animate_bar(_current_hp)
	else:
		health_bar.value = _current_hp
		
## 更新等级
## 用法: GameHUD.instance.add_level(adding_level)
## adding_level: 增加/减少了若干等级(不是增加到!)
func add_level(adding_level: int):
	_player_level += adding_level
	level_label.text = "Level.%d" % _player_level

# --- 私有逻辑 ---
## 动画效果实现
func _animate_bar(target_value: int) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(health_bar, "value", target_value, 0.5)
	
	if target_value < health_bar.value:
		health_bar.modulate = Color(2.5, 0.5, 0.5)
		var color_tween = create_tween()
		color_tween.tween_property(health_bar, "modulate", Color.WHITE, 0.3)
	
	tween.finished.connect(func():
		if target_value == 0:
			print("Debug: 发出 health_depleted_animation_finished 信号")
			health_depleted_animation_finished.emit()
	)

# ==========================================
#  自动化集成测试 (Integration Test)
# ==========================================
func run_debug_test() -> void:

	
	print("1. 初始化玩家数据...")
	setup_player("TestUser", 10, 100)
	await get_tree().create_timer(1.0).timeout # 暂停1秒方便肉眼观察
	
	print("2. 测试扣血 (100 -> 70)...")
	update_health(70)
	await get_tree().create_timer(1.0).timeout
	
	print("3. 测试加血 (70 -> 90)...")
	update_health(90)
	await get_tree().create_timer(1.0).timeout
	
	print("4. 测试过量治疗 (90 -> 999 -> 应该被Clamp在100)...")
	update_health(999)
	await get_tree().create_timer(1.0).timeout
	
	print("5. 测试升级 (Lv.10 -> Lv.11)...")
	add_level(1)
	await get_tree().create_timer(1.0).timeout
	
	print("6. 测试死亡 (100 -> 0)...")
	update_health(0)
	# 这里不需要 await，因为 _animate_bar 里有打印 log



# 初始化方法
func setup_kill_count_display():
	# 初始显示
	update_kill_count_display()

# 更新消灭敌人数量显示
func update_kill_count_display():
	if kill_enemy_count:
		kill_enemy_count.text = "已消灭: %d" % Global.current_kill_count
