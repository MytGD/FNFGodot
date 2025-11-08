class_name FunkinSprite extends Node2D
const Anim = preload("res://source/general/animation/Anim.gd")
const Graphic = preload("res://source/objects/Sprite/Graphic.gd")

@export var x: float: set = set_x,get = get_x
@export var y: float: set = set_y,get = get_y

var _position: Vector2: set = set_position



@export var pivot_offset: Vector2: set = set_pivot_offset
var _real_pivot_offset: Vector2

#region Offset
@export_category("Offset")
@export var offset: Vector2 = Vector2.ZERO: set = set_offset
##If [code]true[/code], the animation offset will follow the sprite flips.[br][br]
##[b]Example[/b]: if the sprite has flipped horizontally, the [param offset.x] will be inverted horizontally(x)
@export var offset_follow_flip: bool = false 
@export var offset_follow_scale: bool = false ##If [code]true[/code], the animation offset will be multiplied by the sprite scale when set.
@export var offset_follow_rotation: bool = true ##If [code]true[/code], the animation offset will follow the rotation.
var _real_offset: Vector2 = Vector2.ZERO

var _animOffsets: Dictionary[String,Vector2] = {}
var _graphic_scale: Vector2 = Vector2.ZERO: set = set_graphic_scale
var _graphic_offset: Vector2 = Vector2.ZERO: set = set_graphic_offset
var midpoint_scale: Vector2 = Vector2.ONE
#endregion

#region Scroll Factor
@export var scrollFactor: Vector2 = Vector2.ONE: set = set_scroll_factor
var _real_scroll_factor: Vector2
var _scroll_offset: Vector2
var _needs_factor_update: bool
#endregion

var parent: Node

var _last_scale: Vector2
var _last_rotation: float = 0.0

#region Velocity Vars
@export_category("Velocity")
@export var acceleration: Vector2 = Vector2.ZERO: set = set_aceleration ##This will accelerate the velocity from the value setted.
@export var velocity: Vector2 = Vector2.ZERO: set = set_velocity ##Will add velocity from the position, making the sprite move.
var _accelerating: bool = false
@export var maxVelocity: Vector2 = Vector2(999999,99999) ##The limit of the velocity, set [Vector2](-1,-1) to unlimited.
#endregion


#region Images/Animation Properties
##The Node that will be animated. [br]
##Can be a [Sprite2D] with [member Sprite2D.region_enabled] enabled
## or a [NinePatchRect]
@export var image: CanvasItem = Graphic.new(): set = set_image_node

##If [code]true[/code], 
##the region_rect of the [param image] will be resized automatically 
##for his texture size every time it's changes.
var _auto_resize_image: bool = true

@export_category("Image")
@export var antialiasing: bool: set = set_antialiasing

@export var width: float: set = set_width, get = get_width ##Texture width, only be changed when the sprite it's not being animated. 
@export var height: float: set = set_height, get = get_height ##Texture height, only be changed when the sprite it's not being animated.

var imageSize: Vector2 ##The texture size of the [member image]

var imageFile: String: get = get_image_file ##The Path from the current image
var imagePath: String: get = get_image_path ##The [b]absolute[/b] Path from the current image

@export var flipX: bool: set = flip_h ##Flip the sprite horizontally.
@export var flipY: bool: set = flip_v ##Flip the sprite vertically.

@export var animation: Anim ##The animation class. See how to use in [Anim].

#endregion

#region Native Methods
func _init(is_animated: bool = false,texture: Variant = null):
	if is_animated: _create_animation()
	image.name = 'Sprite'
	set_notify_local_transform(true)
	_on_image_changed()
	set_texture(texture)
	add_child(image)

func _ready() -> void: set_notify_local_transform(true); 

func _enter_tree() -> void: _update_position()

func _process(delta: float) -> void:
	if _needs_factor_update: _update_scroll_factor()
	if _accelerating: _add_velocity(delta)
	if animation: animation.curAnim.process_frame(delta)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED: parent = get_parent(); _check_scroll_factor()
		NOTIFICATION_UNPARENTED: parent = null; _needs_factor_update = false
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			if _last_rotation == rotation and _last_scale == scale: return;
			_last_rotation = rotation
			_last_scale = scale
			_update_pivot()
			_update_real_offset()
#endregion

#region Animation Methods
##When the [param animName] plays, the offset placed in [param offsetX,offsetY] will be set.[br][br]
##[b]OBS:[/b] [param offsetX] can be a [float] or a [Vector2]:[codeblock]
##animation.addAnimation('static','param')
##addAnimOffset('static',50,50) #Set using float.
##addAnimOffset('static',[50,50]) #Set using Array.
##addAnimOffset('static',Vector2(50,50)) #Set using Vector2. ##[/codeblock]
func addAnimOffset(animName: String, offsetX: Variant = 0.0, offsetY: float = 0.0) -> void:
	var _offset: Vector2 = Vector2(offsetX,offsetY) \
	if offsetX is float or offsetX is int else VectorUtils.as_vector2(offsetX)
	
	_animOffsets[animName] = _offset
	if animation and animation.current_animation == animName: offset = _offset

func _create_animation() -> void: 
	if animation: return
	_auto_resize_image = false
	animation = Anim.new()
	_connect_animation()

func _kill_animation() -> void:
	animation.stop()
	_auto_resize_image = true
	image.region_rect.size = imageSize
	animation.animation_started.disconnect(set_offset_from_anim)
	animation.animation_renamed.disconnect(set_offset_from_anim)
	animation = null

func _update_animation_image() -> void:
	if !animation: return
	animation.image = image
	animation.curAnim.node_to_animate = image

func _connect_animation() -> void:
	animation.animation_started.connect(set_offset_from_anim)
	animation.animation_renamed.connect(_on_animation_renamed)
	animation.image_animation_enabled.connect(func(enabled): _auto_resize_image = !enabled)
	animation.image_parent = self
	_update_animation_image()
	image.region_rect = Rect2(0,0,0,0)

func _on_animation_renamed(old,new): if _animOffsets.has(old): DictionaryUtils.rename_key(_animOffsets,old,new)

func set_offset_from_anim(anim: String) -> void:
	if !_animOffsets.has(anim): return
	var off = _animOffsets[anim]
	if animation and animation.current_animation == anim: offset = off
#endregion

#region Velocity Methods
func _check_velocity() -> void: _accelerating = acceleration != Vector2.ZERO or velocity != Vector2.ZERO

func _add_velocity(delta: float) -> void:
	velocity += acceleration * delta
	_position += velocity.clamp(-maxVelocity,maxVelocity) * delta
#endregion

#region Setters

func set_position_xy(_x: float, _y:float): _position = Vector2(_x,_y);
func set_position(_pos: Vector2): _position = _pos; _update_position()

func set_x(_x: float): _position.x = _x 
func set_y(_y: float): _position.y = _y

func set_velocity(vel: Vector2): velocity = vel; _check_velocity() 
func set_aceleration(acc: Vector2): acceleration = acc; _check_velocity()
func set_offset(_off: Vector2): 
	offset = _off; 
	var _last_off = _real_offset
	_update_real_offset(); 
	position -= _real_offset - _last_off

func set_scroll_factor(factor: Vector2):scrollFactor = factor; _real_scroll_factor = Vector2.ONE - factor; _check_scroll_factor()
func set_pivot_offset(value: Vector2) -> void: pivot_offset = value; _update_pivot()

func set_camera(_cam: Node):
	if camera == _cam: return
	if camera and _camera_is_canvas: camera.remove.call(self)
	
	if !_cam: camera = null; _camera_is_canvas = false; return
	
	_camera_is_canvas = _cam is CameraCanvas
	if !_camera_is_canvas and _cam.get('position') == null: camera = null; return
	
	camera = _cam
	
	if !is_inside_tree(): return
	if _camera_is_canvas: _cam.add(self)
	else: reparent(_cam)
#endregion

#region Getters
func get_x() -> float: return _position.x
func get_y() -> float: return _position.y
func get_position() -> Vector2: return _position
func get_offset() -> Vector2: return offset
func _get_real_position() -> Vector2: return _position - _real_offset - _real_pivot_offset + _scroll_offset - _graphic_offset
func getMidpoint() -> Vector2:return _position + _scroll_offset + pivot_offset ##Get the [u]center[/u] position of the sprite in the scene.
#endregion

#region Image Setters
func set_antialiasing(anti: bool):
	antialiasing = anti
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if anti else CanvasItem.TEXTURE_FILTER_NEAREST

func set_image_node(node: CanvasItem): image = node; _on_image_changed()
func flip_h(flip: bool = flipX) -> void: flipX = flip; _update_image_flip()
func flip_v(flip: bool = flipY) -> void: flipY = flip; _update_image_flip()
func set_alpha(_alpha: float): modulate.a = _alpha
func set_width(_width: float): image.region_rect.size.x = _width
func set_height(_height: float): image.region_rect.size.y = _height
func set_graphic_offset(off: Vector2): _graphic_offset = off; _update_position()
func set_graphic_scale(_scale: Vector2): _graphic_scale = _scale; _update_graphic_offset()
func set_texture(tex: Variant):
	if !tex: image.texture = null; return;
	image.texture = tex if tex is Texture2D else Paths.texture(tex)
#endregion

#region Image Getters
func get_alpha() -> float: return modulate.a
func get_width() -> float:  return image.region_rect.size.x if animation else imageSize.x
func get_height() -> float: return image.region_rect.size.y if animation else imageSize.y
func get_image_file() -> String: return Paths.getPath(imagePath)
func get_image_path() -> String: return image.texture.resource_name if image.texture else ''
#endregion


#region Updaters

#region Scroll Factor
func _check_scroll_factor() -> void: _needs_factor_update = scrollFactor != Vector2.ONE
func _update_scroll_factor() -> void:
	var pos: Vector2 = camera.scroll if camera else parent.get('position')
	if !pos: _scroll_offset = Vector2.ZERO; return
	_scroll_offset = pos * _real_scroll_factor
	_update_position()
#endregion

func _update_position() -> void: position = _get_real_position()

func _update_graphic_offset() -> void: _graphic_offset = image.pivot_offset*_graphic_scale

func _update_pivot():
	_real_pivot_offset = pivot_offset*scale
	if rotation: _real_pivot_offset = _real_pivot_offset.rotated(rotation)
	_real_pivot_offset = _real_pivot_offset - pivot_offset

func _update_real_offset() -> void:
	_real_offset = offset
	if offset_follow_scale: _real_offset *= scale
	if offset_follow_flip: _real_offset *= image.scale
	if offset_follow_rotation: _real_offset = _real_offset.rotated(rotation)

func _on_texture_changed() -> void:
	if !image.texture: 
		imageSize = Vector2.ZERO;
		pivot_offset = imageSize; 
		image.pivot_offset = imageSize;
		return
	imageSize = image.texture.get_size()
	if _auto_resize_image: 
		image.region_rect = Rect2(Vector2.ZERO,imageSize); 
		pivot_offset = imageSize/2.0
		image.pivot_offset = pivot_offset

func _on_image_changed() -> void:
	image.texture_changed.connect(_on_texture_changed)
	_update_image_flip()
	_update_animation_image()
	
func _update_image_flip() -> void:
	image.scale = Vector2(-1 if flipX else 1, -1 if flipY else 1)
	if image is Graphic: image._update_offset()
#endregion

var groups: Array[SpriteGroup] = []

#region Camera Vars
var camera: Node: set = set_camera
var _camera_is_canvas: bool = false
#endregion

func centerOrigin(): midpoint_scale = scale;

##Remove the Sprite from the scene. The same as using [code]get_parent().remove_child(self)[/code]
func kill() -> void: var parent = get_parent(); if parent: parent.remove_child(self)  

func removeFromGroups() -> void: for group in groups: group.remove(self)

#region Image Methods
func setGraphicSize(sizeX: float = -1.0, sizeY: float = -1.0) -> void: ##Cut the Image, just works if this sprite is [u]not animated[/u].
	if !image.texture: return
	if sizeX == -1.0: sizeX = image.region_rect.size.x
	if sizeY == -1.0: sizeY = image.region_rect.size.y
	var size = Vector2(sizeX ,sizeY)
	image.region_rect.size = size
	pivot_offset = size/2.0
	image.pivot_offset = pivot_offset

func setGraphicScale(_scale: Vector2) -> void: scale = _scale; _graphic_scale = Vector2.ONE-_scale
#endregion

func screenCenter(type: StringName = 'xy') -> void: ##Move the sprite to the center of the screen
	var viewport = get_viewport(); if !viewport: return
	var midScreen: Vector2 = viewport.size/2.0
	match type:
		'xy': position = midScreen - (pivot_offset*scale)
		'x': x = midScreen.x - (pivot_offset.x * scale.x)
		'y': y = midScreen.y - (pivot_offset.y * scale.y)


func _property_get_revert(property: StringName) -> Variant:
	match property:
		'scale','scrollFactor': return Vector2.ONE
		'velocity','acceleration','offset': return Vector2.ZERO
	return null
