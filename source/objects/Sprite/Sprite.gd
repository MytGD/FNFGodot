##A expensive [Node2D] class
##based in [url=https://api.haxeflixel.com/flixel/FlxSprite.html]FlxSprite[/url] 
##to be more accurate with 
##[url=https://gamebanana.com/mods/309789]Psych Engine[/url], 
##being easing to understand the code.
extends SpriteAnimated
class_name Sprite
const CameraCanvas = preload("res://source/objects/Display/Camera/Camera.gd")

var groups: Array[SpriteGroup] = []

#region Transform Vars

#region Position Vars
@export var x: float: set = set_x, get = get_x
@export var y: float: set = set_y, get = get_y
var _position: Vector2: set = set_pos
@export var angle: float: set = set_angle, get = get_angle ##Similar to [member Control.rotation_degrees].

@export var scrollFactor: Vector2 = Vector2.ONE: set = set_scroll_factor ##A "parallax" effect
var _is_scroll_factor: bool = false

#Pivot Properties
var _last_scale: Vector2 = Vector2.ONE
var _last_rotation: float = rotation
var _real_pivot_offset: Vector2 = pivot_offset
#endregion

#region Offset Vars
var _animOffsets: Dictionary[String,Vector2] = {}
var _graphic_scale: Vector2 = Vector2.ZERO: set = set_graphic_scale
var _graphic_offset: Vector2 = Vector2.ZERO: set = set_graphic_offset
var midpoint_scale: Vector2 = Vector2.ONE

@export var offset: Vector2: set = set_offset ##The offset from the position.
@export var offset_follow_scale: bool = false ##If [code]true[/code], the animation offset will be multiplied by the sprite scale when set.
@export var offset_follow_rotation: bool = true ##If [code]true[/code], the animation offset will follow the rotation.
var _real_offset: Vector2 = Vector2.ZERO

##If [code]true[/code], the animation offset will follow the sprite flips.[br][br]
##[b]Example[/b]: if the sprite has flipped horizontally, the [param offset.x] will be inverted horizontally(x)
@export var offset_follow_flip: bool = false 
#endregion

#region Velocity Vars
@export_category("Velocity")
@export var acceleration: Vector2 = Vector2.ZERO: set = set_aceleration ##This will accelerate the velocity from the value setted.
@export var velocity: Vector2 = Vector2.ZERO: set = set_velocity ##Will add velocity from the position, making the sprite move.
var _accelerating: bool = false
@export var maxVelocity: Vector2 = Vector2(999999,99999) ##The limit of the velocity, set [Vector2](-1,-1) to unlimited.
#endregion

#endregion

#region Camera Vars
var camera: Node: set = set_camera
var _camera_is_canvas: bool = false
var _scroll_offset: Vector2 = Vector2.ZERO
#endregion

#region Image Vars
@export_category("Image")
@export var alpha: float: set = set_alpha, get = get_alpha ##Change the alpha from the [member CanvasItem.modulate]
@export var width: float: set = set_width, get = get_width ##Texture width, only be changed when the sprite it's not being animated. 
@export var height: float: set = set_height, get = get_height ##Texture height, only be changed when the sprite it's not being animated.

var imageSize: Vector2 = Vector2.ZERO ##The texture size of the [member image]

var imageFile: String: get = get_image_file ##The Path from the current image
var imagePath: String: get = get_image_path ##The [b]absolute[/b] Path from the current image

@export var antialiasing: bool = true: set = set_antialiasing ##[code]true[/code] to make the texture more smooth, [code]false[/code] to make texture pixelated.
#endregion

func _init(image_file: Variant = null, animated: bool = false):
	is_animated = animated
	super._init()
	set_notify_local_transform(true)
	
	if !image_file: return
	if image_file is Texture2D: image.texture = image_file
	elif image_file is String:
		image.texture = Paths.imageTexture(image_file)
		name = image_file.get_file()
	if image.texture: _update_texture()

func centerOrigin(): midpoint_scale = scale;

func kill() -> void: var parent = get_parent(); if parent: parent.remove_child(self) ##Remove the Sprite from the game, still can be accesed.

func removeFromGroups() -> void: for group in groups: group.remove(self)


#region Image Methods
func _update_texture():
	imageSize = image.texture.get_size() if image.texture else Vector2.ZERO
	super._update_texture()

 ##Cut the Image, just works if this sprite is [u]not animated[/u].
func setGraphicSize(sizeX: float = -1.0, sizeY: float = -1.0) -> void:
	if !image.texture: return
	if sizeX == -1.0: sizeX = image.region_rect.size.x
	if sizeY == -1.0: sizeY = image.region_rect.size.y
	var size = Vector2(sizeX,sizeY)
	image.region_rect.size = size
	pivot_offset = size/2.0
	image.pivot_offset = pivot_offset

func setGraphicScale(_scale: Vector2) -> void:
	scale = _scale
	_graphic_scale = Vector2.ONE-_scale
	_updatePos()
#endregion

#region Position Methods
func _process(delta: float) -> void:
	_add_velocity(delta)
	if !_is_scroll_factor: return
	_update_scroll_factor(); 
	_updatePos()

func _updatePos() -> void:  position = _position + _scroll_offset - _real_offset - _real_pivot_offset - _graphic_offset

func screenCenter(type: StringName = 'xy') -> void: ##Move the sprite to the center of the screen
	var midScreen: Vector2 = get_viewport().size/2.0
	match type:
		'xy': _position = midScreen - (pivot_offset*scale)
		'x': x = midScreen.x - (pivot_offset.x * scale.x)
		'y': y = midScreen.y - (pivot_offset.y * scale.y)


#region Pivot Methods
func _recalculate_pivot_offset() -> void:
	_real_pivot_offset = pivot_offset*scale
	if rotation: _real_pivot_offset = _real_pivot_offset.rotated(rotation)
	_real_pivot_offset = _real_pivot_offset - pivot_offset
	_updatePos()
#endregion

#region Velocity Methods
func _is_accelerating() -> bool: return acceleration != Vector2.ZERO or velocity != Vector2.ZERO
func _add_velocity(delta: float) -> void:
	if !_accelerating: return
	velocity += acceleration * delta
	_position += velocity.clamp(-maxVelocity,maxVelocity) * delta
	#endregion

#region Offset Methods
func set_offset_from_anim(anim: String) -> void:
	if !_animOffsets.has(anim): return
	var off = _animOffsets[anim]
	if animation and animation.curAnim.name == anim: offset = off
	
func _update_real_offset() -> void:
	_real_offset = offset
	if offset_follow_scale: _real_offset *= scale
	if offset_follow_flip: _real_offset *= image.scale
	if offset_follow_rotation: _real_offset = _real_offset.rotated(rotation)

func _update_scroll_factor():
	if scrollFactor != Vector2.ONE and camera:
		if _camera_is_canvas: _scroll_offset = -camera._scroll_position*(Vector2.ONE-scrollFactor)
		else: _scroll_offset = -camera.position*(Vector2.ONE-scrollFactor)
	else: _scroll_offset = Vector2.ZERO

##When the [param animName] plays, the offset placed in [param offsetX,offsetY] will be set.[br][br]
##[b]OBS:[/b] [param offsetX] can be a [float] or a [Vector2]:[codeblock]
##var sprite = Sprite.new()
##sprite.animation.addAnimation('static','param')
##sprite.animation.addAnimation('confirm','param2')
##sprite.addAnimOffset('confirm',sprite.pivot_offset) #Set using Vector2.
##sprite.addAnimOffset('static',0,0) #Set using float.
##[/codeblock]
func addAnimOffset(animName: StringName, offsetX: Variant = 0.0, offsetY: float = 0.0) -> void:
	var _offset: Vector2
	match typeof(offsetX):
		TYPE_VECTOR2,TYPE_VECTOR2I: _offset = offsetX
		TYPE_ARRAY,TYPE_PACKED_FLOAT32_ARRAY,TYPE_PACKED_FLOAT64_ARRAY,\
		TYPE_PACKED_INT32_ARRAY,TYPE_PACKED_INT64_ARRAY: _offset = Vector2(offsetX[0],offsetX[1])
		_: _offset = Vector2(offsetX,offsetY)
	
	_animOffsets[animName] = _offset
	if animation and animation.curAnim.name == animName: offset = _offset
#endregion

#region Setters
func set_x(_x: float): position.x += _x - position.x; _position.x = _x
func set_y(_y: float): _position.y += _y - position.y; _position.y = _y
func set_pos(_pos: Vector2): _position = _pos; _updatePos()
func set_velocity(vel: Vector2): velocity = vel; _accelerating = _is_accelerating() 
func set_aceleration(acc: Vector2): acceleration = acc; _accelerating = _is_accelerating()
func set_angle(_angle: float): if rotation_degrees != _angle: rotation_degrees = _angle; _updatePos()
func set_alpha(_alpha: float): modulate.a = _alpha
func set_width(_width: float): image.region_rect.size.x = _width
func set_height(_height: float): image.region_rect.size.y = _height
func set_offset(_offset: Vector2): offset = _offset; _update_real_offset();_updatePos()
func set_graphic_offset(off: Vector2): _graphic_offset = off; _updatePos()
func set_pivot_offset(value: Vector2) -> void:
	super.set_pivot_offset(value)
	_graphic_offset = _graphic_scale*image.pivot_offset
	_recalculate_pivot_offset()

func set_antialiasing(allow: bool): 
	antialiasing = allow
	texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE if allow else CanvasItem.TEXTURE_FILTER_NEAREST
func set_scroll_factor(fac: Vector2): 
	scrollFactor = fac
	_is_scroll_factor = (fac != Vector2.ONE)
	_update_scroll_factor()
	_updatePos()

func set_graphic_scale(_scale: Vector2): 
	_graphic_scale = _scale; 
	_graphic_offset = image.pivot_offset*_scale
func set_camera(_cam: Node):
	if camera == _cam: return
	if _camera_is_canvas: camera.remove.call(self)
	
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
func get_angle() -> float: return rotation_degrees
func get_alpha() -> float: return modulate.a
func get_width() -> float:  return image.region_rect.size.x if is_animated else imageSize.x
func get_height() -> float: return image.region_rect.size.y if is_animated else imageSize.y
func get_image_file() -> String: return Paths.getPath(imagePath)
func get_image_path() -> String: return image.texture.resource_name if image.texture else ''
func getMidpoint() -> Vector2:return _position + _scroll_offset + pivot_offset ##Get the [u]center[/u] position of the sprite in the scene.
#endregion

func _notification(what: int) -> void:
	super._notification(what)
	match what:
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			if _last_rotation == rotation and _last_scale == scale: return
			_last_rotation = rotation
			_last_scale = scale 
			_recalculate_pivot_offset()
			_update_real_offset()

func _connect_animation():
	super._connect_animation()
	animation.animation_started.connect(set_offset_from_anim)
	animation.animation_renamed.connect(func(old,new):
		if _animOffsets.has(old): DictionaryUtils.rename_key(_animOffsets,old,new)
	)

func _property_get_revert(property: StringName) -> Variant:
	match property:
		'scale': return Vector2.ONE
	return null
