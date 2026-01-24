extends Node2D

@onready var particles: CPUParticles2D = $"."

func _ready() -> void:
	particles.emitting = true
	
	# 考虑到生命周期有随机性，计算可能的最大停留时间
	# 最大寿命 = 基准寿命 * (1 + 随机性系数)
	var max_life = particles.lifetime * (1.0 + particles.lifetime_randomness)
	
	# 使用计时器等待最长寿命结束后清理内存
	await get_tree().create_timer(max_life).timeout
	queue_free()
