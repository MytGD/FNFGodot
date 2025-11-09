extends VideoStreamPlayer

func _init(): resized.connect(_on_resized)

func load_stream(path: Variant) -> void:
	var _stream = Paths.video(path) if path is String else path
	if !_stream is VideoStreamTheora: stream = null
	stream = _stream
	if is_inside_tree(): play()

func _enter_tree() -> void:
	if stream: play()

func _on_resized() -> void:
	var video_div = ScreenUtils.screenSize/size
	var video_scale = minf(video_div.x,video_div.y)
	scale = Vector2(video_scale,video_scale)
	
