extends StaticBody2D

@export var player: CharacterBody2D
@export var max_health: int = 50  # 建议使用 max_health 作为导出变量

var health: int = 50
var heal: bool = true
var is_base_right: bool = true  # 标记为右侧基地

signal heal_ball(pos: Vector2)
signal right_base_died

func _ready() -> void:
	# 1. 统一初始化数值
	health = max_health
	
	# 2. 确保 UI 在初始化时就是满的
	if has_node("hp"):
		$hp.max_value = max_health
		$hp.value = health

func _process(_delta: float) -> void:
	# 治疗/补给逻辑
	if heal:
		spawn_heal_ball()
	
	# 死亡判定
	if health <= 0:
		die()

func spawn_heal_ball():
	heal_ball.emit($Marker2D.global_position)
	if player != null:
		player.energy = clampi(player.energy + 10, 0, 100)
		player.health = clampi(player.health + 1, 0, 100)
				
	heal = false
	$Timer.start()

func hurt(damage: int):
	# 播放受伤动画
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("hurt")
	
	# 扣血并同步更新血条 UI
	health -= damage
	if has_node("hp"):
		$hp.value = health

func die():
	# 基地摧毁逻辑
	right_base_died.emit()
	queue_free()

func _on_timer_timeout() -> void:
	heal = true
