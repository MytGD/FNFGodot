@icon("res://icons/process_bar_2d.svg")
extends Node2D
var bg: Sprite = Sprite.new()

var x: float:
	set(value):
		position.x = value
	get():
		return position.x
var y: float:
	set(value):
		position.y = value
	get():
		return position.y

var angle: float:
	set(value):
		rotation_degrees = value
	get():
		return rotation_degrees

var leftBar: CanvasItem = _get_fill_bar(null,true)
var rightBar: CanvasItem = _get_fill_bar(null,true)

var progress: float = 0.5: 
	set(value):
		if progress == value:
			return
		value = clamp(value,0,1.0)
		progress = value
		_update_bar()

var progress_position: Vector2 = Vector2.ZERO

var flip: bool = false: 
	set(flipped):
		flip = flipped
		_update_bar()

var fill_bars_size: Vector2 = Vector2.ZERO
var defaultSize: Vector2 = Vector2.ZERO

var alpha: float:
	set(value):
		alpha = value
		modulate.a = value
	get():
		return modulate.a

var _right_bar_is_color: bool = true:
	set(is_color):
		if is_color == _right_bar_is_color:
			return
		_right_bar_is_color = is_color
		rightBar = _get_fill_bar(rightBar,is_color)
		add_child(rightBar)
		move_child(rightBar,0)
		rightBar.name = 'rightBar'
		

var _left_bar_is_color: bool = true:
	set(is_color):
		if is_color == _left_bar_is_color:
			return
		_left_bar_is_color = is_color
		leftBar = _get_fill_bar(leftBar,is_color)
		add_child(leftBar)
		move_child(leftBar,bg.get_index())
		leftBar.name = 'leftBar'
		

func _init(bgImage: String = ''):
	name = 'bar'
	
	bg.image.texture_changed.connect(func():
		defaultSize = Vector2(bg.width,bg.height)
	)
	
	bg.image.texture = Paths.imageTexture(bgImage)
	bg.name = 'bg'
	add_child(rightBar)
	rightBar.modulate = Color(0.4,0.4,0.4,1)
	add_child(leftBar)
	add_child(bg)

func _ready():
	leftBar.name = 'leftBar'
	rightBar.name = 'rightBar'
	
	_update_bar_fill_size()

static func _get_fill_bar(old_bar: CanvasItem = null, is_solid_color: bool = true) -> CanvasItem:
	var new_bar
	if is_solid_color:
		new_bar = ColorRect.new()
		if old_bar:
			new_bar.size = old_bar.region_rect.size.x
		new_bar.position = Vector2(3,3)
	else:
		new_bar = get_animated_bar()
		if old_bar:
			new_bar.region_rect.size.x = old_bar.size.x
	
	if old_bar:
		old_bar.queue_free()
	return new_bar

func flip_colors():
	var leftColor = leftBar.modulate
	leftBar.modulate = rightBar.modulate
	rightBar.modulate = leftColor

static func get_animated_bar() -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.centered = false
	sprite.region_enabled = true
	return sprite
	
##Set Bar Images, if dont want to change, leave blank.
func set_bar_image(base: Variant = null,left: Variant = null,right: Variant = null) -> void:
	if base:
		bg.image.texture = Paths.imageTexture(base) if base is String else base
	
	if left:
		_left_bar_is_color = false
		leftBar.texture = Paths.imageTexture(left)  if left is String else left
		leftBar.region_rect.size = leftBar.texture.get_size()
		
	if right:
		_right_bar_is_color = false
		rightBar.texture = Paths.imageTexture(right) if right is String else right
		rightBar.region_rect.size = rightBar.texture.get_size()
	_update_bar()
	
func move_bg_to_front() -> void:
	move_child(bg,get_child_count())

func move_bg_to_behind() -> void:
	move_child(bg,0)

##Set the bar colors. [param left] and [param right] can be a [Array] or a [Color].[br]
##If is a [Array], the values inside it will be divided by [code]255[/code].
##To put a color in just one side, set [code]null[/code] for the another:[codeblock]
##var bar = Bar.new()
##bar.set_colors([255,255,255],null) #Set color of the left bar to white.
##bar.set_colors(null,Color.RED) #Set color of the right bar to red.
##[/codeblock]
func set_colors(left: Variant = null, right: Variant = null) -> void:
	if left:
		leftBar.modulate = left if left is Color else Color(left[0]/255.0,left[1]/255.0,left[2]/255.0)
	if right:
		rightBar.modulate = right if right is Color else Color(right[0]/255.0,right[1]/255.0,right[2]/255.0)

func _update_bar() -> void:
	if _left_bar_is_color:
		leftBar.size = Vector2(fill_bars_size.x*progress,fill_bars_size.y)
	else:
		leftBar.region_rect.size = Vector2(fill_bars_size.x*progress,fill_bars_size.y)
	
	if _right_bar_is_color:
		rightBar.size = fill_bars_size
	else:
		rightBar.region_rect.size = fill_bars_size
		
	progress_position = get_process_position()

func _update_bar_fill_size():
	fill_bars_size = bg.imageSize - Vector2(3,3)
	_update_bar()

func get_process_position(process: float = progress):
	var _process = Vector2(bg.imageSize.x*process,0.0)*scale
	if rotation:
		return _process.rotated(rotation)
	return _process
	
func screenCenter(pos: String = 'xy') -> void:
	if pos.begins_with('x'):
		x = ScreenUtils.screenWidth/2.0 - bg.width/2.0
	if pos.ends_with('y'):
		y = ScreenUtils.screenHeight/2.0 - bg.height/2.0
