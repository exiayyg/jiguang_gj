extends Control

func _ready() -> void:
	$AudioStreamPlayer.play()
	
func _input(event):
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo():
		# 开始后台加载
		var path = "res://Scenes/Levels/test_level.tscn"
		ResourceLoader.load_threaded_request(path)
		# 进入一个循环检查或者切换到过渡动画
		set_process(true) 

func _process(_delta):
	var path = "res://Scenes/Levels/test_level.tscn"
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(path, progress)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(path)
		get_tree().change_scene_to_packed(new_scene)
