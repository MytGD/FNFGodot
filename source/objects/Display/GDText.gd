extends Label
var x: float:
	set(value):
		_position.x = value
	get():
		return _position.x
var y: float:
	set(value):
		_position.y = value
	get():
		return _position.y

var _position: Vector2 = Vector2.ZERO:
	set(value):
		_position = value
		_updatePos()

var _alignment_offset: Vector2 = Vector2.ZERO
var offset: Vector2 = Vector2.ZERO
var width: float: 
	set(value):
		size.x = value
		_update_alignment_offset()
	get():
		return size.x

var height: float: 
	set(value):
		size.y = value
		_update_alignment_offset()
	get():
		return size.y
var camera: Node: set = set_camera
var color: Color = Color.WHITE: set = set_text_color
var parent
var scrollFactor: Vector2 = Vector2(1,1)

var _scroll_offset: Vector2 = Vector2.ZERO

var alpha: float = 1.0: 
	set(value):
		modulate.a = value
	get():
		return modulate.a

var font: String: 
	set(value):
		set_font(value)
		font = value

func _init(textT:String = '',posX: float = 0, posY: float = 0,textWidth: float = ScreenUtils.screenWidth):
	set_font('vcr.ttf')
	label_settings = LabelSettings.new()
	label_settings.outline_size = 7
	label_settings.outline_color = Color.BLACK
	autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	size = Vector2(textWidth,ScreenUtils.screenHeight)
	text = str(textT)
	
	x = posX
	y = posY
	name = 'text'

func set_camera(newCamera: Node):
	if newCamera == camera:
		return
	camera = newCamera
	if newCamera is CameraCanvas:
		newCamera.add(self)
	else:
		if parent:
			reparent(newCamera)
			return
		newCamera.add_child(self)
	
func set_text_color(newColor: Variant):
	if newColor is String:
		color = FunkinGD.getColorFromHex(newColor)
	elif newColor is Color:
		color = newColor
	label_settings.font_color = color
	
func set_pos(pos_x: Variant,pos_y: float) -> void:
	if pos_x is Vector2:
		x = pos_x.x
		y = pos_x.y
		return
	x = pos_x
	y = pos_y
	
func _updatePos():
	position = _position - offset - scrollFactor + _alignment_offset
	
func _process(_delta):
	if scrollFactor != Vector2.ONE and camera:
		var pos = camera._position if camera.get('_position') else camera.get('position')
		if pos:
			_scroll_offset = -pos*(Vector2.ONE-scrollFactor)
	else:
		_scroll_offset = Vector2.ZERO
	_updatePos()

func set_font(font):
	var fontDetect = Paths.font(font)
	var fontSource: FontFile = FontFile.new()
	if fontDetect.is_empty():
		fontDetect =  "res://assets/fonts/vcr.ttf"
	fontSource.load_dynamic_font(fontDetect)
	if fontSource == null:
		fontSource = FontFile.new()
	if fontSource != null:
		add_theme_font_override('font',fontSource)

func _update_alignment_offset():
	match horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			_alignment_offset.x = -width/2.0
		HORIZONTAL_ALIGNMENT_RIGHT:
			_alignment_offset.x = width
		_:
			_alignment_offset.x = 0
	match vertical_alignment:
		VERTICAL_ALIGNMENT_CENTER:
			_alignment_offset.y = height/2.0
		VERTICAL_ALIGNMENT_BOTTOM:
			_alignment_offset.y = height
		_:
			_alignment_offset.y = 0
	
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			parent = get_parent()
		NOTIFICATION_UNPARENTED:
			parent = null
		NOTIFICATION_DRAW:
			_update_alignment_offset()

func screenCenter(type: StringName = 'xy'):
	pass
