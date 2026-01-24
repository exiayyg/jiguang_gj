extends AudioStreamPlayer

@export var intro_stream: AudioStream = preload("res://Assets/Audio/前奏.mp3")
@export var loop_stream: AudioStream = preload("res://Assets/Audio/循环.mp3")

var is_looping: bool = false
var loop_start_time: float = 2.44 # 你提到的切入点

func _ready():
	stream = intro_stream
	play()

func _process(_delta):
	# 当播放接近 2.44 秒时，立即切换到循环部分
	# 使用 >= 是为了防止因为帧率波动错过精确的 2.44000
	if not is_looping and get_playback_position() >= loop_start_time:
		switch_to_loop()

func switch_to_loop():
	stream = loop_stream
	play() # 切换流并重新播放
	is_looping = true
