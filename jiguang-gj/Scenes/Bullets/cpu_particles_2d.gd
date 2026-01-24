extends Node2D

@onready var particles: CPUParticles2D = $"." 

# 外部传入的方向变量
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 确保粒子节点存在
	if particles:
		# 1. 处理发射方向
		if direction != Vector2.ZERO:
			particles.direction = Vector2(direction.x, direction.y)
		
		
		particles.gravity = Vector2.ZERO
		
	
		particles.emitting = true
	
	# 自动销毁逻辑
	var max_life = particles.lifetime * (1.0 + particles.lifetime_randomness)
	await get_tree().create_timer(max_life).timeout
	queue_free()
