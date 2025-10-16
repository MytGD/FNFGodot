##A expensive [Node2D] class
##based in [url=https://api.haxeflixel.com/flixel/FlxSprite.html]FlxSprite[/url] 
##to be more accurate with 
##[url=https://gamebanana.com/mods/309789]Psych Engine[/url], 
##being easing to understand the code.
extends SpriteAnimated
class_name Sprite
const CameraCanvas = preload("res://source/objects/Display/Camera.gd")

#region Transform
@export var x: float: set = set_x, get = get_x
@export var y: float: set = set_y, get = get_y
var _position: Vector2: set = set_pos

@export var angle: float: set = set_angle, get = get_angle ##Similar to [member Control.rotation_degrees].
@export var alpha: float: set = set_alpha, get = get_alpha ##Change the alpha from the [member CanvasItem.modulate]

@export var width: float: set = set_width, get = get_width ##Texture width, only be changed when the sprite it's not being animated. 
@export var height: float: set = set_height, get = get_height ##Texture height, only be changed when the sprite it's not being animated.
@export var scrollFactor: Vector2 = Vector2.ONE ##A "parallax" effect

var _graphic_scale: Vector2 = Vector2.ZERO: set = set_graphic_scale
var _graphic_offset: Vector2 = Vector2.ZERO
var midpoint_scale: Vector2 = Vector2.ONE
#endregion

#region Offset
@export var offset: Vector2: set = set_offset
@export var offset_follow_scale: bool = false ##If [code]true[/code], the animation offset will be multiplied by the sprite scale when set.
@export var offset_follow_rotation: bool = true ##If [code]true[/code], the animation offset will follow the rotation.

##If [code]true[/code], the animation offset will follow the sprite flips.[br][br]
##For example, if the sprite has flipped horizontally, the [param offset.x] will be multiplied to [code]-1[/code]
##when setted again, and the same for vertically.
@export var offset_follow_flip: bool = false

#endregion

#region Velocity
@export_category("Velocity")
@export var acceleration: Vector2 = Vector2.ZERO ##This will accelerate the velocity from the value setted.
@export var velocity: Vector2 = Vector2.ZERO ##Will add velocity from the position, making the sprite move.
@export var maxVelocity: Vector2 = Vector2(999999,99999) ##The limit of the velocity, set [Vector2](-1,-1) to unlimited.
#endregion

#region Camera
var camera: Node: set = set_camera
var _scroll_offset: Vector2 = Vector2.ZERO
#endregion

#region Image
@export_category("Image")
var _animOffsets: Dictionary = {}
var imageSize: Vector2 = Vector2.ZERO ##The texture size of the [member image]

##The Path from the current image
var imageFile: StringName: 
	get(): return Paths.getPath(imagePath)

##The [b]absolute[/b] Path from the current image
var imagePath: StringName:
	get(): return image.texture.resource_name if image.texture else ''
#endregion

##[code]True[/code] to make the texture more smooth.
##[code]False[/code] to make texture pixelated.
@export var antialiasing: bool = true: set = set_antialiasing
#endregion


var groups: Array[SpriteGroup] = []


#Pivot Properties
var _last_scale: Vector2 = Vector2.ONE
var _last_rotation: float = rotation
var _real_pivot_offset: Vector2 = pivot_offset

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

 ##Move the sprite to the center of the screen
func screenCenter(type: StringName = 'xy') -> void:
	var midScreen: Vector2 = ScreenUtils.screenSize/2.0
	match type:
		'xy':
			_position = Vector2(
				midScreen.x - (pivot_offset.x * scale.x),
				midScreen.y - (pivot_offset.y * scale.y)
			)
		'x': x = midScreen.x - (pivot_offset.x * scale.x)
		'y': y = midScreen.y - (pivot_offset.y * scale.y)

##Get the [u]center[/u] position of the sprite in the scene.
func getMidpoint() -> Vector2:return _position + _scroll_offset + pivot_offset

func _process(delta: float) -> void:
	#Add velocity
	if acceleration != Vector2.ZERO: velocity += acceleration * delta
	if velocity != Vector2.ZERO: 
		_position += velocity.clamp(-maxVelocity,maxVelocity) * delta
	
	if scrollFactor != Vector2.ONE and camera:
		var pos = camera.get('_position')
		if !pos: pos = camera.get('position')
		if pos: _scroll_offset = -pos*(Vector2.ONE-scrollFactor)
	else: _scroll_offset = Vector2.ZERO

	_updatePos()

func centerOrigin():
	midpoint_scale = scale
	_updatePos()
	
##Move the sprite for the Vector2([param pos_x,pos_y]) position.
##[param pos_x] can be a [float] or a [Vector2]: [codeblock]
##Sprite.set_pos(Vector2(1.0,1.0)) #Move Sprite to (1.0,1.0).
##Sprite.set_pos(1.0,1.0)#The same, but separated.
##[/codeblock]
##Cut the Image, just works if [u]not animated[/u] and [member image.texture] is a [AtlasTexture].
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
	
func join(front: bool = false):
	if groups: groups.back().add(self,true); return
	if camera: camera.add(self,front)

##Remove the Sprite from the game, still can be accesed.
func kill() -> void:
	if get_parent(): get_parent().remove_child(self)
	
	
func removeFromGroups() -> void:
	for group in groups: group.remove(self)


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
	if animation and animation.curAnim.name == animName: set_offset_from_anim(animName)
	#node.owner = self

func _connect_animation(): #Function from SpriteBase
	super._connect_animation()
	animation.animation_started.connect(set_offset_from_anim)
	animation.animation_renamed.connect(func(old,new):
		if _animOffsets.has(old): DictionaryHelper.rename_key(_animOffsets,old,new)
	)
	
func _update_texture():
	imageSize = image.texture.get_size() if image.texture else Vector2.ZERO
	super._update_texture()
	
	
func _updatePos() -> void:
	var pos = _position + _scroll_offset
	if offset_follow_rotation and rotation: pos -= offset.rotated(rotation)
	else: pos -= offset
	
	if pivot_offset == Vector2.ZERO: position = pos - _graphic_offset; return
	position = pos - (_real_pivot_offset - pivot_offset) - _graphic_offset

func set_pivot_offset(value: Vector2) -> void:
	_updatePos()
	super.set_pivot_offset(value)
	_recalculate_pivot_offset()
	_graphic_offset = _graphic_scale*image.pivot_offset

func _recalculate_pivot_offset() -> void:
	_real_pivot_offset = pivot_offset*scale
	if rotation: _real_pivot_offset = _real_pivot_offset.rotated(rotation)
		
func set_offset_from_anim(anim: String) -> void:
	if !_animOffsets.has(anim): return
	var off = _animOffsets[anim]
	if offset_follow_scale: off *= scale
	if offset_follow_flip: off *= image.scale
	offset = off

#region Setters
func set_x(_x: float): position.x += _x - position.x; _position.x = _x
func set_y(_y: float): _position.y += _y - position.y; _position.y = _y
func set_pos(_pos: Vector2): position += _pos - _position; _position = _pos
func set_angle(_angle: float): if rotation_degrees != _angle: rotation_degrees = _angle; _updatePos()
func set_alpha(_alpha: float): modulate.a = _alpha
func set_width(_width: float): image.region_rect.size.x = _width
func set_height(_height: float): image.region_rect.size.y = _height
func set_antialiasing(allow: bool): 
	antialiasing = allow
	texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE if allow else CanvasItem.TEXTURE_FILTER_NEAREST
func set_graphic_scale(_scale: Vector2): 
	_graphic_scale = _scale; 
	_graphic_offset = image.pivot_offset*_scale
func set_offset(_offset: Vector2): 
	if offset_follow_rotation and rotation: position -= (_offset - offset).rotated(rotation)
	else: position -= _offset - offset
	offset = _offset
func set_camera(_cam: Node):
	if camera == _cam: return
	var is_in_scene: bool =is_inside_tree()
	if camera and camera is CameraCanvas: camera.remove.call(self)
	camera = _cam
	if !is_in_scene: return
	if _cam is CameraCanvas: _cam.add(self)
	else: reparent(_cam)
#endregion

#region Getters
func get_x() -> float: return _position.x
func get_y() -> float: return _position.y
func get_angle() -> float: return rotation_degrees
func get_alpha() -> float: return modulate.a
func get_width() -> float:  return image.region_rect.size.x if is_animated else imageSize.x
func get_height() -> float: return image.region_rect.size.y if is_animated else imageSize.y
#endregion
func _notification(what: int) -> void:
	super._notification(what)
	match what:
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			if _last_rotation != rotation or _last_scale != scale:
				_last_rotation = rotation
				_last_scale = scale
				_recalculate_pivot_offset()
				_updatePos()
