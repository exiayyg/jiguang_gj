extends StaticBody2D

@export var player: CharacterBody2D
@export var max_health: int = 100 # 使用 max_health 记录上限

var health: int = 0
var heal: bool = true
var is_base_left: bool = true

signal heal_ball(pos: Vector2)
signal left_base_died

func _ready() -> void:
	# 初始化：将当前血量设为最大血量
	health = max_health
	
	# 确保 UI 节点存在再进行初始化
	if has_node("hp"):
		$hp.max_value = max_health
		$hp.value = health # 必须显式设置当前的 value，确保满血显示

func _process(_delta: float) -> void:
	# 治疗逻辑
	if heal:
		process_healing()
		
	# 死亡逻辑
	if health <= 0:
		base_death()

# 封装治疗逻辑，让 _process 看起来更整洁
func process_healing():
	heal_ball.emit($Marker2D.global_position)
	if player != null:
		# 优化能量恢复逻辑：使用 clamp 限制在 0-100 之间
		player.energy = clampi(player.energy + 10, 0, 100)
		#player.health = clampi(player.health + 1, 0, 100)
	heal = false
	$Timer.start()

func hurt(damage: int):
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("hurt")
	
	health -= damage
	
	# 实时同步 UI 血条
	if has_node("hp"):
		$hp.value = health

func base_death():
	# 在这里可以添加基地爆炸的动画或音效
	left_base_died.emit()
	queue_free()

func _on_timer_timeout() -> void:
	heal = true
