##A expensive [Node2D] class
##based in [url=https://api.haxeflixel.com/flixel/FlxSprite.html]FlxSprite[/url] 
##to be more accurate with 
##[url=https://gamebanana.com/mods/309789]Psych Engine[/url], 
##being easing to understand the code.
extends SpriteAnimated
class_name Sprite
const CameraCanvas = preload("res://source/objects/Display/Camera.gd")

@export var x: float:
	set(value):
		position.x += value - _position.x
		_position.x = value
	get(): return _position.x
	
##Position Y
@export var y: float: 
	set(value):
		position.y += value - _position.y
		_position.y = value
	get(): return _position.y

@export var offset: Vector2 = Vector2.ZERO: 
	set(value):
		if offset_follow_rotation and rotation: position -= (value - offset).rotated(rotation)
		else: position -= value - offset
		offset = value

@export var _position: Vector2 = Vector2.ZERO:
	set(value):
		position += value - _position
		_position = value


##Similar to [member Control.rotation_degrees].
@export var angle: float: 
	set(value):
		if rotation_degrees == value: return
		rotation_degrees = value
		_updatePos()
	get(): return rotation_degrees


##A "parallax" effect
@export var scrollFactor: Vector2 = Vector2.ONE


@export_category("Velocity")
##This will accelerate the velocity from the value setted.
@export var acceleration: Vector2 = Vector2.ZERO

##Will add velocity from the position, making the sprite move.
@export var velocity: Vector2 = Vector2.ZERO
		
##The limit of the velocity, set [Vector2](-1,-1) to unlimited.
@export var maxVelocity: Vector2 = Vector2(999999,99999)

@export_category("Image")

var _animOffsets: Dictionary = {}

##If [code]true[/code], the animation offset will be multiplied by the sprite scale when set.
var offset_follow_scale: bool = false

##If [code]true[/code], the animation offset will follow the sprite flips.[br][br]
##For example, if the sprite has flipped horizontally, the [param offset.x] will be multiplied to [code]-1[/code]
##when setted again, and the same for vertically.
var offset_follow_flip: bool = false
var offset_follow_rotation: bool = true

var imageSize: Vector2 = Vector2.ZERO ##The texture size of the [member image]

##The Path from the current image
var imageFile: StringName: 
	get(): return Paths.getPath(imagePath)

##The [b]REAL[/b] Path from the current image
var imagePath: StringName:
	get(): return image.texture.resource_name if image.texture else ''

##Set the blend of the Sprite, can be: [param add,subtract,mix]
@export_enum("none","add","mix","subtract","premult_alpha","overlay") 
var blend: String = 'none': 
	set(blendMode):
		ShaderHelper.set_object_blend(self,blendMode)
		blend = blendMode
		
##Change the alpha from the [member CanvasItem.modulate]
@export var alpha: float: 
	set(value): modulate.a = value
	get(): return modulate.a


##Texture width, only be changed when the sprite it's not being animated. 
@export var width: float:
	set(value):
		image.region_rect.size.x = value
	get():
		return image.region_rect.size.x if is_animated else imageSize.x

##Texture height, only be changed when the sprite it's not being animated.
@export var height: float:
	set(value):
		image.region_rect.size.y = value
	get():
		return  image.region_rect.size.y if is_animated else imageSize.y

##[code]True[/code] to make the texture more smooth.
##[code]False[/code] to make texture pixelated.
@export var antialiasing: bool = true: 
	set(enable):
		antialiasing = enable
		texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE if enable else CanvasItem.TEXTURE_FILTER_NEAREST


var _scroll_offset: Vector2 = Vector2.ZERO

var _graphic_scale: Vector2 = Vector2.ZERO:
	set(value):
		_graphic_scale = value
		_graphic_offset = image.pivot_offset*value

var _graphic_offset: Vector2 = Vector2.ZERO

var camera: Node: 
	set(newCamera):
		if camera == newCamera: return

		var is_in_scene: bool =is_inside_tree()
		if camera and camera is CameraCanvas: camera.remove(self)
		camera = newCamera
		if !is_in_scene: return
		
		if newCamera is CameraCanvas: newCamera.add(self)
		else: reparent(newCamera)
		
var midpoint_scale: Vector2 = Vector2.ONE
var groups: Array[SpriteGroup] = []


#Pivot Properties
var _last_scale: Vector2 = Vector2.ONE
var _last_rotation: float = rotation
var _real_pivot_offset: Vector2 = pivot_offset

func _init(image_file: Variant = null, animated: bool = false):
	super._init()
	is_animated = animated
	
	set_notify_local_transform(true)
	set_notify_transform(true)
	if image_file:
		if image_file is Texture2D: image.texture = image_file
		elif image_file is String:
			image.texture = Paths.imageTexture(image_file)
			name = image_file.get_file()
		
		if image.texture: _update_texture()

 ##Move the sprite to the center of the screen
func screenCenter(type: StringName = 'xy') -> void:
	var midScreen: Vector2 = ScreenUtils.screenSize/2.0
	match type:
		'xy': set_pos(midScreen.x - (pivot_offset.x * scale.x),midScreen.y - (pivot_offset.y * scale.y))
		'x': x = midScreen.x - (pivot_offset.x * scale.x)
		'y': y = midScreen.y - (pivot_offset.y * scale.y)

##Get the [u]center[/u] position of the sprite in the scene.
func getMidpoint() -> Vector2:return _position + _scroll_offset + pivot_offset

func _process(delta: float) -> void:
	#Add velocity
	if acceleration != Vector2.ZERO: velocity += acceleration * delta
	if velocity != Vector2.ZERO: _position += clamp(velocity,-maxVelocity,maxVelocity) * delta
	
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
func set_pos(pos_x: Variant, pos_y: float = 0.0) -> void:
	if pos_x is Vector2: _position = pos_x; return
	_position = Vector2(pos_x,pos_y)


##Create a Rect
func makeGraphic(graphicWidth: float = 30.0, graphicHeight: float = 30.0, graphicColor: Color = Color.BLACK):
	if animation:animation.clearLibrary()
	image.texture = null
	var color = ColorRect.new()
	color.color = graphicColor
	color.size = Vector2(graphicWidth,graphicHeight)
	add_child(color)
	color.name = 'graphic'

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
		TYPE_ARRAY: _offset = Vector2(offsetX[0],offsetX[1])
		_: _offset = Vector2(offsetX,offsetY)
	
	_animOffsets[animName] = _offset
	if animation and animation.curAnim.name == animName: 
		set_offset_from_anim(animName)
	#node.owner = self

func _create_animation(): #Function from SpriteBase
	if animation: return
	super._create_animation()
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

func check_scroll_factor():
	pass
func _notification(what: int) -> void:
	super._notification(what)
	match what:
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			if _last_rotation != rotation or _last_scale != scale:
				_last_rotation = rotation
				_last_scale = scale
				_recalculate_pivot_offset()
				_updatePos()
