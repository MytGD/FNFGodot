@icon("res://icons/Camera2D.svg")
class_name CameraCanvas extends Node2D
const FlashSprite = preload("res://source/objects/Display/Camera/FlashSprite.gd")

#region Transform
@export var x: float: set = set_x, get = get_x
@export var y: float: set = set_y, get = get_y
@export var zoom: float = 1.0: set = set_zoom
@export var alpha: float: set = set_alpha,get = get_alpha


var color: Color: set = set_color,get = get_color
var angle: float: set = set_angle, get = get_angle
var angle_degrees: float = 0.0: set = set_angle_degress
var width: int: set = set_width
var height: int: set = set_height
var pivot_offset: Vector2 = Vector2.ZERO
#endregion

#region Camera
var bg: SolidSprite = SolidSprite.new()
var _first_index: int = 0

var scroll_camera: Node2D = Node2D.new()
var scroll: Vector2 = Vector2.ZERO: set = set_scroll
var scrollOffset: Vector2 = Vector2.ZERO: set = set_scroll_offset
var _scroll_position: Vector2 = Vector2.ZERO: set = _set_scroll_position
var _scroll_pivot_offset: Vector2 = Vector2.ZERO: set = _set_scroll_pivot_offset
var _real_scroll_position: Vector2 = Vector2.ZERO

var flashSprite: FlashSprite = FlashSprite.new()
@export var defaultZoom: float = 1.0 #Used in PlayState
#region Shake
@export_category("Shake")
var shakeIntensity: float = 0.0
var shakeTime: float = 0.0
var _shake_pos: Vector2 = Vector2.ZERO: set = _set_shake_pos
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
	
	scroll_camera.name = 'Scroll'
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
	create_shader_image()
	
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
	_shader_image.material = shaders[0]
	var index: int = 1
	while index < shaders.size(): _addViewportShader(shaders[index]); index += 1
	if shaders: filtersArray.append_array(shaders)
	filtersArray.append(_shader_image.material)

func _addViewportShader(filter: ShaderMaterial) -> Sprite2D:
	if !_last_viewport_added: return
	create_viewport()
	
	var shader_view = _get_new_viewport()
	add_child(shader_view)
	
	if filter.shader.resource_name: shader_view.name = filter.shader.resource_name
	
	var tex = Sprite2D.new()
	tex.name = 'Sprite2D'
	tex.centered = false
	tex.texture = _last_viewport_added.get_texture()
	tex.material = filter
	
	shader_view.add_child(tex)
	_viewports_created.append(shader_view)
	
	_shader_image.texture = shader_view.get_texture()
	_last_viewport_added = shader_view
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
	scroll_camera.transform = Transform2D(Vector2.RIGHT,Vector2.DOWN,Vector2.ZERO)
	scroll_camera.reparent(viewport,false)
	_update_angle()
	_update_zoom()
	_update_pivot()
	_update_scroll_transform()
	
	#flashSprite.reparent(viewport,false)
	_last_viewport_added = viewport
	
	create_shader_image()
	
func create_shader_image():
	if _shader_image: return
	
	_shader_image = Sprite2D.new()
	_shader_image.name = 'ViewportTexture'
	_shader_image.centered = false
	_shader_image.texture = viewport.get_texture()
	
	add_child(_shader_image)
	move_child(_shader_image,0)

func remove_viewport() -> void:
	if !viewport: return
	scroll_camera.reparent(self,false)
	move_child(scroll_camera,0)
	viewport.queue_free()
	viewport = null

func can_remove_viewport() -> bool:
	return !filtersArray and not (viewport and viewport.world_3d)
#endregion

#region Effects Methods
#region Shake
##Shake the Camera
func shake(intensity: float, time: float) -> void: shakeIntensity = intensity; shakeTime = time

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
func add(node: Node,front: bool = true) -> void: ##Add a node to the camera, if [code]front = false[/code], the node will be added behind of the first node added.
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

#region Camera Transform
func _update_pivot() -> void:
	var _scroll_pivot = pivot_offset - _scroll_position
	var _scroll_pivot_cal = _scroll_pivot
	if angle_degrees: _scroll_pivot = _scroll_pivot.rotated(angle_degrees)
	_scroll_pivot_offset = (_scroll_pivot*zoom - _scroll_pivot_cal)

func _update_angle()  -> void:
	if viewport: 
		viewport.canvas_transform.x.y = -angle_degrees
		viewport.canvas_transform.y.x = angle_degrees
	else: scroll_camera.rotation = angle_degrees
	_update_pivot()

func _update_zoom() -> void:
	if viewport: 
		viewport.canvas_transform.x.x = zoom
		viewport.canvas_transform.y.y = zoom
	else: scroll_camera.scale = Vector2(zoom,zoom)
	_update_pivot()

func _update_scroll_pos(): _scroll_position = -scroll + scrollOffset
func _update_scroll_transform():
	_real_scroll_position = _scroll_position - _scroll_pivot_offset + _shake_pos
	if viewport: viewport.canvas_transform.origin = _real_scroll_position
	else: scroll_camera.position = _real_scroll_position
#endregion

func _draw() -> void: draw_rect(Rect2(Vector2.ZERO,Vector2(width,height)),Color.WHITE)

#region Setters
func set_x(_x: float) -> void: position.x = _x
func set_y(_y: float) -> void: position.y = _y
func set_width(value: int) -> void: width = value; _update_camera_size()
func set_height(value: int) -> void: height = value; _update_camera_size()
func set_alpha(value: float) -> void: scroll_camera.modulate.a = value
func set_zoom(value: float) -> void: zoom = value; _update_zoom()
func set_angle(value: float) -> void: set_angle_degress(deg_to_rad(value))
func set_pivot_offset(value: Vector2) -> void: pivot_offset = value; _update_pivot()
func set_scroll(val: Vector2) -> void: scroll = val; _update_scroll_pos()
func set_scroll_offset(val: Vector2): scrollOffset = val; _update_scroll_transform()
func _set_scroll_position(val: Vector2) -> void: _scroll_position = val; _update_scroll_transform()
func _set_scroll_pivot_offset(val: Vector2) -> void: _scroll_pivot_offset = val; _update_scroll_transform()
func _set_shake_pos(val: Vector2): _shake_pos = val; _update_scroll_transform()
func set_angle_degress(value: float):
	if value == angle_degrees: return
	angle_degrees = value
	_update_angle()
func set_color(_color: Variant): 
	scroll_camera.modulate.r = _color.r; 
	scroll_camera.modulate.g = _color.g; 
	scroll_camera.modulate.b = _color.b
#endregion

#region Getters
func get_x() -> float: return position.x
func get_y() -> float: return position.y
func get_alpha() -> float: return scroll_camera.modulate.a
func get_angle() -> float: return deg_to_rad(angle_degrees)
func get_color() -> Color: return scroll_camera.modulate
#endregion

static func _convertFiltersToMaterial(shaders: Array) -> Array[Material]:
	var array: Array[Material] = []
	for i in shaders:
		var shader: Material = (Paths.loadShader(i) if i is String else i)
		if !shader or shader in array: continue
		array.append(shader)
	return array


static func _get_new_viewport() -> SubViewport:
	var view = SubViewport.new()
	view.transparent_bg = true
	view.disable_3d = true
	view.gui_snap_controls_to_pixels = false
	view.size = ScreenUtils.screenSize
	#view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	return view

func _get_property_revert(property: String):
	match property:
		'zoom': return defaultZoom
		'defaultZoom': return 1.0
		'scrollOffset': return Vector2.ZERO
		'angle': return 0.0
	return null
