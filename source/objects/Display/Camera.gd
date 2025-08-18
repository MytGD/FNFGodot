class_name CameraCanvas extends Control

@export var x: float:
	set(value):
		position.x = value
	get():
		return position.x
		
@export var y: float:
	set(value):
		position.y = value
	get():
		return position.y

@export var zoom: float = 1.0: 
	set(value):
		zoom = value
		camera.scale = Vector2(value,value)
		_updatePos()
	
@export var alpha: float: 
	set(value):
		camera.modulate.a = value
	get():
		return camera.modulate.a

@export var defaultZoom: float = 1.0

var color: Color:
	set(value):
		camera.modulate.r = value.r
		camera.modulate.g = value.g
		camera.modulate.b = value.b
	get():
		return camera.modulate
		
var angle: float:
	set(value):
		if value == angle:return
		camera.rotation_degrees = value
	get():
		return camera.rotation_degrees
		
var camera: Node2D = Node2D.new()

var filtersArray: Array = []

var scroll: Vector2 = Vector2.ZERO
var scrollOffset: Vector2 = Vector2.ZERO

var width: int: 
	set(value):
		size.x = value
		_update_camera_size()
	get():
		return size.x
var height: int: 
	set(value):
		size.y = value
		_update_camera_size()
	get():
		return size.y
#var camModulate: CanvasModulate = CanvasModulate.new()

@export_category("Shake")
var shakeIntensity: float = 0.0
var shakeTime: float = 0.0
var shakeSmooth: bool = false
var _shake_pos: Vector2 = Vector2.ZERO

var _position: Vector2 = Vector2.ZERO

var flashSprite: ColorRect = ColorRect.new()
var bg: ColorRect = ColorRect.new()



var _first_index: int = 0

var _viewport: SubViewport
var _viewports_created: Array[SubViewport]
var _last_viewport_added: SubViewport

var _shader_image: Sprite2D

func _init() -> void:
	clip_contents = true
	bg.size = Vector2(ScreenUtils.screenWidth,ScreenUtils.screenHeight)
	bg.modulate = Color(0.0,0.0,0.0,0.0)

	bg.name = 'bg'
	
	width = ScreenUtils.screenWidth
	height = ScreenUtils.screenHeight
	
	add_child(camera)
	
	flashSprite.name = 'flashSprite'

	flashSprite.modulate.a = 0.0
	flashSprite.scale = Vector2(2,2)
	
	add_child(flashSprite)
	
	camera.child_exiting_tree.connect(func(node):
		if node.get_index() < _first_index: _first_index -= 1
	)
	_update_camera_size()

func _update_camera_size():
	size = Vector2(width,height)
	if _viewport: _viewport.size = size
	pivot_offset = size/2.0

func _update_viewport_size():
	for i in _viewports_created: i.size = Vector2.ONE * ScreenUtils.screenWidth/get_viewport().size.x
		
func _ready():
	flashSprite.size = size
	flashSprite.pivot_offset = size/2.0

#region Shaders Methods

func setFilters(shaders: Array = []) -> void: ##Set Shaders in the Camera
	removeFilters()
	filtersArray.append_array(_convertFiltersToMaterial(shaders))
	if !filtersArray: return
	
	_add_camera_to_viewport()
	_shader_image.material = filtersArray[0]
	
	if filtersArray.size() == 1: _shader_image.texture = _viewport.get_texture(); return
	
	var index: int = 1
	while index < filtersArray.size():
		_addViewportShader(filtersArray[index])
		index += 1


func addFilters(shaders: Variant) -> void: ##Add shaders to the existing ones.
	if shaders is String: shaders = [shaders]
	if !filtersArray: setFilters(shaders); return
	
	shaders = _convertFiltersToMaterial(shaders)
	_add_camera_to_viewport()
	for i in shaders: _addViewportShader(i)
	filtersArray.append_array(shaders)

func _convertFiltersToMaterial(shaders: Array) -> Array[Material]:
	var array: Array[Material] = []
	for i in shaders:
		var shader: Material = (Paths.loadShader(i) if i is String else i)
		if !shader or shader in array: continue
		array.append(shader)
	return array

func _addViewportShader(filter: ShaderMaterial) -> Sprite2D:
	if !_last_viewport_added: return
	
	_add_camera_to_viewport()
	
	var viewport = _get_new_viewport()
	add_child(viewport)
	
	if filter.shader.resource_name: viewport.name = filter.shader.resource_name
	
	var tex = Sprite2D.new()
	tex.centered = false
	tex.texture = _last_viewport_added.get_texture()
	tex.material = filter
	
	viewport.add_child(tex)
	_viewports_created.append(viewport)
	
	_shader_image.texture = viewport.get_texture()
	
	_last_viewport_added = viewport
	return tex
	

func removeFilter(shader: ShaderMaterial) -> void: ##Remove shaders.
	if !shader in filtersArray: return
	filtersArray.erase(shader)
	setFilters(filtersArray)

func removeFilters(): ##Remove every shader created in this camera.
	filtersArray.clear()
	if _shader_image:
		_shader_image.queue_free()
		_shader_image = null
	
	if _viewport:
		camera.reparent(self)
		move_child(camera,0)
		_viewport.queue_free()
		_viewport = null
	
	if _viewports_created:
		for i in _viewports_created: i.queue_free()
		_viewports_created.clear()
	
	
func _add_camera_to_viewport():
	if _viewport: return
	
	_viewport = _get_new_viewport()
	add_child(_viewport)
	camera.reparent(_viewport)
	
	_last_viewport_added = _viewport
	if _shader_image: return
	
	_shader_image = Sprite2D.new()
	_shader_image.centered = false
	_shader_image.texture = _viewport.get_texture()
	
	add_child(_shader_image)
	move_child(_shader_image,0)
#endregion
	
##Shake the Camera
func shake(intensity: float, time: float) -> void:
	shakeIntensity = intensity
	shakeTime = time


##Fade the camera.
func fade(color: Variant = Color.BLACK,time: float = 1, _force: bool = true, _fadeIn: bool = true) -> void:
	var tag = 'fade'+name+('fadeIn' if _fadeIn else 'fadeOut')
	if !_force and FunkinGD.isTweenRunning('fade'+tag): return
	
	var target = 0.0 if _fadeIn else 1.0
	if color is String: color = FunkinGD.getColorFromHex(color)
	
	flashSprite.color = color
	
	if time: FunkinGD.startTween(tag,flashSprite,{'modulate:a': target},time,'linear'); return
	else: FunkinGD.cancelTween(tag); flashSprite.modulate.a = target

##Flash bang
func flash(color: Color = Color.WHITE, time: float = 1.0, force: bool = false) -> void:
	var tag = 'flash'+name
	if !time or !force and FunkinGD.isTweenRunning(tag): return
	flashSprite.color = color
	flashSprite.modulate.a = 1
	FunkinGD.doTweenAlpha(tag,flashSprite,0.0,time,'linear').bind_node(self)

func _process(delta) -> void:
	if shakeIntensity:
		var intensity = Vector2(
			randf_range(-shakeIntensity,shakeIntensity),
			randf_range(-shakeIntensity,shakeIntensity)
		)*1000.0
		if not shakeSmooth: _shake_pos = intensity
		else: _shake_pos = _shake_pos.lerp(_shake_pos + intensity,0.5)
	
	if shakeTime:
		shakeTime -= delta
		if shakeTime <= 0.0:
			shakeIntensity = 0
			shakeTime = 0
			_shake_pos = Vector2.ZERO
	_updatePos()
	
func _updatePos():
	_position = -scroll + scrollOffset
	var real_pivot_offset = pivot_offset - _position
	var pivot = real_pivot_offset
	if camera.rotation: pivot = pivot.rotated(camera.rotation)
	pivot *= zoom
	camera.position = _position - (pivot - real_pivot_offset) + _shake_pos
	
##Add a node to the camera, if [code]front = false[/code], the node will be added behind of the first node added.
func add(node: Node,front: bool = true) -> void:
	if !node: return
	_insert_object_to_camera(node)
	if not front: move_to_order(node,_first_index)

func _insert_object_to_camera(node: Node):
	var parent = node.get_parent()
	if parent: parent.remove_child(node)
	camera.add_child(node)
	node.set("camera",self)
	
func move_to_order(node: Node, order: int):
	if !node: return
	
	var old_index = node.get_index()
	
	order = mini(order,camera.get_child_count())
	camera.move_child(node,order)
	
	##If the node was ahead of _first_index and moved before or to _first_index, add to _first_index
	if old_index >= _first_index and order <= _first_index: _first_index += 1
	
	##If the node was before or at _first_index and moved past it, subadd to _first_index
	elif old_index < _first_index and order > _first_index: _first_index -= 1
	
##Insert the node at [code]pos[/code].
func insert(pos: int = 0,node: Object = null) -> void:
	if !node: return
	_insert_object_to_camera(node)
	move_to_order(node,pos)

##Remove the node from the camera.
func remove(node: Object) -> void: camera.remove_child(node)
	
static func _get_new_viewport() -> SubViewport:
	var view = SubViewport.new()
	view.transparent_bg = true
	view.disable_3d = true
	view.size = ScreenUtils.screenSize
	#view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	return view
