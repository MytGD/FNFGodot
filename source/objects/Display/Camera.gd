class_name CameraCanvas extends Node2D
const SolidSprite = preload("res://source/objects/Sprite/SolidSprite.gd")

#region Transform
@export var x: float: set = set_x, get = get_x
@export var y: float: set = set_y, get = get_y
@export var zoom: float = 1.0: set = set_zoom
@export var alpha: float: set = set_alpha,get = get_alpha
var _position: Vector2 = Vector2.ZERO
var color: Color: set = set_color,get = get_color
var angle: float: set = set_angle, get = get_angle
var width: int: set = set_width
var height: int: set = set_height
var pivot_offset: Vector2 = Vector2.ZERO
#endregion

#region Camera
var bg: SolidSprite = SolidSprite.new()
var _first_index: int = 0
var scroll_camera: Node2D = Node2D.new()
var scroll: Vector2 = Vector2.ZERO
var scrollOffset: Vector2 = Vector2.ZERO
var flashSprite: SolidSprite = SolidSprite.new()
@export var defaultZoom: float = 1.0 #Used in PlayState
#region Shake
@export_category("Shake")
var shakeIntensity: float = 0.0
var shakeTime: float = 0.0
var _shake_pos: Vector2 = Vector2.ZERO
#endregion

#endregion

#region Shaders
var filtersArray: Array = []
var viewport: SubViewport
var _viewports_created: Array[SubViewport]
var _last_viewport_added: SubViewport
var _shader_image: Sprite2D
#endregion

#region Shotcuts
var remove: Callable = scroll_camera.remove_child
#endregion

func _init() -> void:
	#clip_contents = true
	#mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	
	bg.modulate = Color.TRANSPARENT
	bg.name = 'bg'
	width = ScreenUtils.screenWidth
	height = ScreenUtils.screenHeight
	
	add_child(scroll_camera)
	
	flashSprite.name = 'flashSprite'
	flashSprite.modulate.a = 0.0
	scroll_camera.child_exiting_tree.connect(func(node):
		if node.get_index() < _first_index: _first_index -= 1
	)
	
	_update_camera_size()
	add_child(flashSprite)

#region Size Methods
func _update_camera_size():
	var size = Vector2(width,height)
	#size = Vector2(width,height)
	flashSprite.scale = size
	bg.scale = size
	if viewport: viewport.size = size
	pivot_offset = size/2.0
	queue_redraw()
	
func _update_viewport_size():
	for i in _viewports_created: i.size = Vector2.ONE * ScreenUtils.screenWidth/get_viewport().size.xj
#endregion

#region Shaders Methods
func setFilters(shaders: Array = []) -> void: ##Set Shaders in the Camera
	removeFilters()
	filtersArray.append_array(_convertFiltersToMaterial(shaders))
	if !filtersArray: return
	
	create_viewport()
	_shader_image.material = filtersArray.front()
	
	if filtersArray.size() == 1: _shader_image.texture = viewport.get_texture(); return
	
	var index: int = filtersArray.size()-2
	while index >= 0:
		_addViewportShader(filtersArray[index])
		index -= 1


func addFilters(shaders: Variant) -> void: ##Add shaders to the existing ones.
	if !shaders is Array: shaders = [shaders]
	shaders = _convertFiltersToMaterial(shaders)
	
	create_viewport()
	if _shader_image.material: _addViewportShader(_shader_image.material)
	
	
	_shader_image.material = shaders.pop_back()
	for i in shaders: _addViewportShader(i)
	if shaders: filtersArray.append_array(shaders)
	filtersArray.append(_shader_image.material)

func _convertFiltersToMaterial(shaders: Array) -> Array[Material]:
	var array: Array[Material] = []
	for i in shaders:
		var shader: Material = (Paths.loadShader(i) if i is String else i)
		if !shader or shader in array: continue
		array.append(shader)
	return array

func _addViewportShader(filter: ShaderMaterial) -> Sprite2D:
	if !_last_viewport_added: return
	create_viewport()
	
	var viewport = _get_new_viewport()
	add_child(viewport)
	
	if filter.shader.resource_name: viewport.name = filter.shader.resource_name
	
	var tex = Sprite2D.new()
	tex.name = 'Sprite2D'
	tex.centered = false
	tex.texture = _last_viewport_added.get_texture()
	tex.material = filter
	
	viewport.add_child(tex)
	_viewports_created.append(viewport)
	
	_shader_image.texture = viewport.get_texture()
	
	_last_viewport_added = viewport
	return tex
	

func removeFilter(shader: ShaderMaterial) -> void: ##Remove shaders.
	var filter_id = filtersArray.find(shader)
	if filter_id == -1: return
	
	if filtersArray.size() == 1: removeFilters(); return
	
	filtersArray.remove_at(filter_id)
	var prev_image: Sprite2D
	var shader_viewport = _viewports_created[filter_id]
	var view_image = shader_viewport.get_node('Sprite2D')
	
	if filter_id == filtersArray.size():  prev_image = _shader_image
	else:  prev_image = _viewports_created[filter_id+1].get_node('Sprite2D')
	prev_image.texture = view_image.texture
	_viewports_created.remove_at(filter_id)
	shader_viewport.queue_free()
	

func removeFilters(): ##Remove every shader created in this camera.
	if !filtersArray: return
	filtersArray.clear()
	if _shader_image:
		_shader_image.queue_free()
		_shader_image = null
	
	if can_remove_viewport(): remove_viewport()
	if _viewports_created:
		for i in _viewports_created: i.queue_free()
		_viewports_created.clear()
	
	
func create_viewport() -> void:
	if viewport: return
	
	viewport = _get_new_viewport()
	add_child(viewport)
	flashSprite.reparent(viewport,false)
	scroll_camera.reparent(viewport,false)
	
	_last_viewport_added = viewport
	if _shader_image: return
	
	_shader_image = Sprite2D.new()
	_shader_image.centered = false
	_shader_image.texture = viewport.get_texture()
	
	add_child(_shader_image)
	move_child(_shader_image,0)

func remove_viewport() -> void:
	if !viewport: return
	flashSprite.reparent(self,false)
	scroll_camera.reparent(self,false)
	move_child(scroll_camera,0)
	viewport.queue_free()
	viewport = null

func can_remove_viewport() -> bool:
	return !filtersArray and not (viewport and viewport.world_3d)
#endregion

#region Effects Methods
#region Shake
func shake(intensity: float, time: float) -> void: ##Shake the Camera
	shakeIntensity = intensity; shakeTime = time

func _updateShake(delta: float):
	if shakeTime:
		shakeTime -= delta
		if shakeTime <= 0.0: shakeIntensity = 0; shakeTime = 0; _shake_pos = Vector2.ZERO
	
	if !shakeIntensity: return
	var intensity = Vector2(
		randf_range(-shakeIntensity,shakeIntensity),
		randf_range(-shakeIntensity,shakeIntensity)
	)*1000.0
	_shake_pos = intensity
#endregion

func fade(color: Variant = Color.BLACK,time: float = 1.0, _force: bool = true, _fadeIn: bool = true) -> void: ##Fade the camera.
	var tag = 'fade'+name
	if !_force and FunkinGD.isTweenRunning('fade'+tag): return
	flashSprite.modulate = FunkinGD._get_color(color)
	var target = 0.0 if _fadeIn else 1.0
	if !time: FunkinGD.cancelTween(tag); flashSprite.modulate.a = target
	else: FunkinGD.startTweenNoCheck(tag,flashSprite,{'modulate:a': target},time,'linear')


func flash(color: Color = Color.WHITE, time: float = 1.0, force: bool = false) -> void: ##Flash bang
	if time <= 0.0: return
	var tag = 'flash'+name
	if !force and FunkinGD.isTweenRunning(tag): return
	flashSprite.modulate = color
	FunkinGD.doTweenAlpha(tag,flashSprite,0.0,time,'linear').bind_node = self
#endregion

#region Insert/Remove Nodes Methods
##Add a node to the camera, if [code]front = false[/code], the node will be added behind of the first node added.
func add(node: Node,front: bool = true) -> void:
	if !node: return
	_insert_object_to_camera(node)
	if not front: move_to_order(node,_first_index)
	
func move_to_order(node: Node, order: int):
	if !node: return
	var old_index = node.get_index()
	order = mini(order,scroll_camera.get_child_count())
	scroll_camera.move_child(node,order)
	if old_index >= _first_index and order <= _first_index: _first_index += 1 #If the node was ahead of _first_index and moved before or to _first_index, add to _first_index
	elif old_index < _first_index and order > _first_index: _first_index -= 1 #If the node was before or at _first_index and moved past it, subadd to _first_index

func insert(index: int = 0,node: Object = null) -> void: ##Insert the node at [param index].
	if !node: return
	_insert_object_to_camera(node)
	move_to_order(node,index)

func _insert_object_to_camera(node: Node):
	var parent = node.get_parent()
	if parent: parent.remove_child(node)
	scroll_camera.add_child(node)
	node.set("camera",self)
#endregion

func _process(delta: float) -> void:
	_updateShake(delta)
	_updatePos()

func _updatePos():
	_position = -scroll + scrollOffset
	var real_pivot_offset = pivot_offset - _position
	var pivot = real_pivot_offset
	
	if scroll_camera.rotation: pivot = pivot.rotated(scroll_camera.rotation)
	
	pivot *= zoom
	scroll_camera.position = _position - (pivot - real_pivot_offset) + _shake_pos

func _draw() -> void:
	#RenderingServer.canvas_item_set_clip(get_canvas_item(),true)
	draw_rect(Rect2(Vector2.ZERO,Vector2(width,height)),Color.WHITE)

#region Setters
func set_x(_x: float): position.x = _x
func set_y(_y: float): position.y = _y
func set_width(value: int): width = value; _update_camera_size()
func set_height(value: int): height = value; _update_camera_size()
func set_angle(value: float): if value != angle: scroll_camera.rotation_degrees = value
func set_alpha(value: float): scroll_camera.modulate.a = value
func set_zoom(value: float): zoom = value; scroll_camera.scale = Vector2(value,value); _updatePos()
func set_color(_color: Variant): 
	scroll_camera.modulate.r = _color.r; 
	scroll_camera.modulate.g = _color.g; 
	scroll_camera.modulate.b = _color.b
#endregion

#region Getters
func get_x() -> float: return position.x
func get_y() -> float: return position.y
func get_alpha() -> float: return scroll_camera.modulate.a
func get_angle() -> float:return scroll_camera.rotation_degrees
func get_color() -> Color: return scroll_camera.modulate
#endregion

static func _get_new_viewport() -> SubViewport:
	var view = SubViewport.new()
	view.transparent_bg = true
	view.disable_3d = true
	view.own_world_3d = true
	view.audio_listener_enable_2d = false
	view.audio_listener_enable_3d = false
	view.size = ScreenUtils.screenSize
	#view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	return view
