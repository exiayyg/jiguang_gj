extends Control

# 使用数组管理所有锚点，方便扩展
@onready var markers = [$Marker/Marker2D, $Marker/Marker2D2, $Marker/Marker2D3]
var panel_count: int = 0
var chat: int = 0

var battle: PackedScene = preload("res://Scenes/UI/battle.tscn")

func _ready() -> void:
	$Label.visible = false
	$Label2.visible = false
	
	# 初始状态：相机对准第一格并设置初始缩放
	if markers.size() > 0:
		$Camera2D.global_position = markers[0].global_position
		$Camera2D.zoom = Vector2(3.0, 3.0)

func _input(event):
	# 1. 检查是否按下任意键或鼠标
	# 2. event.is_pressed() 确保只在按下瞬间触发
	# 3. not event.is_echo() 防止长按导致的连续翻页
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo():
		# 如果当前在特定的格子（例如 panel_count == 1），先处理对话逻辑
		if panel_count == 1:
			if chat == 0:
				$Label.visible = true
				chat += 1
			elif chat == 1:
				$Label2.visible = true
				chat += 1
			elif chat == 2:
				advance_manga()
		else:
			advance_manga()

func advance_manga():
	# 如果已经到最后一格，切换到战斗场景
	if panel_count >= markers.size() - 1:
		get_tree().change_scene_to_file("res://Scenes/UI/battle.tscn")
		return
	
	# 准备切换到下一格
	panel_count += 1
	var target_marker = markers[panel_count]
	
	# 创建平滑动画
	var tween = get_tree().create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 移动相机位置
	tween.tween_property($Camera2D, "global_position", target_marker.global_position, 0.8)
	
	# 修改缩放 (Zoom)
	match panel_count:
		1:
			tween.tween_property($Camera2D, "zoom", Vector2(3.0, 3.0), 0.8)
		2:
			tween.tween_property($Camera2D, "zoom", Vector2(3.0, 3.0), 0.8)
		_:
			tween.tween_property($Camera2D, "zoom", Vector2(1.0, 1.0), 0.8)
