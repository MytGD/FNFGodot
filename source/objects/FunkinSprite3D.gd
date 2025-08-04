@tool
extends Node3D
class_name FunkinSprite3D
##A expensive [Node2D] class
##based in [url=https://api.haxeflixel.com/flixel/FlxSprite.html]FlxSprite[/url] 
##to be more accurate with 
##[url=https://gamebanana.com/mods/309789]Psych Engine[/url], 
##being easing to understand the code.

const Anim = preload("res://source/general/animation/Anim.gd")

var animation: Anim:
	set(anim):
		animation = anim
		if !anim:
			return
		anim._parent = self
		anim.image = image
		anim.curAnim.node_to_animate = image
		anim.animation_started.connect(func(i):
			if _animOffsets.has(i):
				offset = _animOffsets[i] * scale if scaling_offset else _animOffsets[i]
		)
	
var is_animated: bool:
	set(value):
		if is_animated == value:
			return
		
		is_animated = value
		if value:
			animation = Anim.new()
			animation._parent = self
			animation.image = image
			return
		
		if animation:
			animation.stop()
			animation = null

@export var x: float:
	set(value):
		#position.x += value - x
		_position.x = value
	get():
		return _position.x
##Position Y
@export var y: float: 
	set(value):
		#position.y += value - y
		_position.y = value
	get():
		return _position.y

##Position Y
@export var z: float: 
	set(value):
		#position.y += value - y
		_position.z = value
	get():
		return _position.z

@export var _position: Vector3 = Vector3.ZERO:
	set(value):
		position += value - _position
		_position = value

@export var offset: Vector3 = Vector3.ZERO: 
	set(value):
		position -= value - offset
		offset = value

var scaling_offset: bool = false

##Similar to [member Control.rotation_degrees].
@export var angle: float: 
	set(value):
		rotate_z(deg_to_rad(value))
	get():
		return rad_to_deg(rotation.z)


##A "parallax" effect
@export var scrollFactor: Vector2 = Vector2.ONE


@export_category("Velocity")
##This will accelerate the velocity from the value setted.
@export var acceleration: Vector2 = Vector2.ZERO

##Will add velocity from the position, making the sprite move.
@export var velocity: Vector2 = Vector2.ZERO
		
##The limit of the velocity, set [Vector2](-1,-1) to unlimited.
@export var maxVelocity: Vector2 = Vector2(999,999)

@export_category("Image")
var image: Sprite3D = get_sprite(): 
	set(node):
		if !node or image == node:
			return
		if image:
			var image_tex = image.get('texture')
			image.queue_free()
			node.set('texture',image_tex)
		
		image = node
		_set_image(node)

##The Path from the current image
var imageFile: StringName:
	get():
		return Paths.getPath(imagePath)

##The [b]REAL[/b] Path from the current image
var imagePath: StringName:
	get():
		return image.texture.resource_name if image.texture else ''

var imageSize: Vector2 = Vector2.ZERO

##Set the blend of the Sprite, can be: [code]add,subtract,mix[/code]
@export_enum("none","add","mix","subtract","premult_alpha","overlay") 
var blend: String = 'none': 
	set(blendMode):
		ShaderHelper.set_object_blend(self,blendMode)
		blend = blendMode
		
##Change the alpha from the [member CanvasItem.modulate]
@export var alpha: float = 1.0: 
	set(value):
		image.modulate.a = value
	get(): 
		return image.modulate.a if image else 0.0


##Texture width, only be changed when the sprite it's not being animated. 
@export var width: float:
	set(value):
		image.region_rect.size.x = value
	get():
		return image.region_rect.size.x if image else 0.0

##Texture height, only be changed when the sprite it's not being animated.
@export var height: float:
	set(value):
		image.region_rect.size.y = value
	get():
		return image.region_rect.size.y if image else 0.0

@export var pivot_offset: Vector2 = Vector2.ZERO:
	set(value):
		pivot_offset = value
		image.set('pivot_offset',value)
		_graphic_offset = _graphic_scale*value

##[code]True[/code] to make the texture more smooth.
##[code]False[/code] to make texture pixelated.
@export var antialiasing: bool = true: 
	set(enable):
		antialiasing = enable
		image.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE if enable else CanvasItem.TEXTURE_FILTER_NEAREST
		
##Flip the sprite horizontally.
@export var flipX: bool = false: 
	set(flip):
		flipX = flip
		image.flip_h = flip
		#image.scale.x = -1 if flip else 1
##Flip the sprite vertically.
@export var flipY: bool = false: 
	set(flip):
		flipY = flip
		image.flip_v = flip
		#image.scale.y = -1 if flip else 1

var _added_light_points: bool = false

var _graphic_scale: Vector2 = Vector2.ZERO:
	set(value):
		_graphic_scale = value
		_graphic_offset = pivot_offset*value

var _graphic_offset: Vector2 = Vector2.ZERO

var camera: Node: 
	set(newCamera):
		if camera == newCamera:
			return
		
		var add_to_scene: bool = parent != null
		if camera and camera is CameraCanvas:
			camera.remove(self)
		
		camera = newCamera
		if !add_to_scene:
			return
		if newCamera is CameraCanvas:
			newCamera.add(self)
		else:
			newCamera.add_child(self)

var _midpoint_scale: Vector2 = Vector2.ONE
var _flip_offset: Vector2 = Vector2.ZERO

var groups: Array[SpriteGroup] = []


var parent: Node
var _lastParent: Node = null


var _animOffsets: Dictionary = {}


func _init(image_file: Variant = null):
	_set_image(image)
	
	if image_file is Texture2D:
		image.texture = image_file
	elif image_file is String:
		image.texture = Paths.imageTexture(image_file)
	
	if image.texture:
		_update_texture()
func _update_texture():
	if animation:
		animation.clearLibrary()
	
	if !image.texture:
		pivot_offset = Vector2.ZERO
		imageSize = pivot_offset
		return
	
	imageSize = image.texture.get_size()
	image.region_rect.size = imageSize
	pivot_offset = imageSize/2.0

##Move the sprite to the center of the screen
func screenCenter(type: StringName = 'xy') -> void:
	var midScreen: Vector2 = ScreenUtils.screenSize/2.0
	match type:
		'xy':
			set_pos(midScreen.x - (pivot_offset.x * scale.x),midScreen.y - (pivot_offset.y * scale.y))
		'x':
			x = midScreen.x - (pivot_offset.x * scale.x)
		'y':
			y = midScreen.y - (pivot_offset.y * scale.y)
	
##Get the [u]center[/u] position of the sprite.
func getMidpoint() -> Vector3:
	var mid = pivot_offset*_midpoint_scale
	return _position + Vector3(mid.x,mid.y,0.0)

func _process(delta: float) -> void:
	#Add velocity
	if acceleration != Vector2.ZERO:
		velocity += acceleration * delta
	
	if velocity != Vector2.ZERO:
		_position += clamp(velocity,-maxVelocity,maxVelocity) * delta
		return
	_updatePos()

func centerOrigin():
	_midpoint_scale = Vector2(scale.x,scale.y)

##[codeblock]
##Sprite.set_pos(Vector2(1.0,1.0)) #Move Sprite to (1.0,1.0).
##Sprite.set_pos(1.0,1.0)#The same, but separated.
##[/codeblock]
func set_pos(pos_x: Variant, pos_y: float = 0.0,pos_z: float = 0.0) -> void:
	if pos_x is Vector3:
		_position = pos_x
		return
	_position = Vector3(pos_x,pos_y,pos_z)


func _updatePos() -> void:
	var pos: Vector3 = _position
	var pivot: Vector2 = pivot_offset
	
	if rotation.z:
		pivot = pivot.rotated(rotation.z)
		pos -= offset.rotated(Vector3(0,0,1),rotation.z)
	else:
		pos -= offset
	pivot *= Vector2(scale.x,scale.y)
	
	pivot -= pivot_offset - _graphic_offset
	
	pos.x -= pivot.x
	pos.y -= pivot.y
	position = pos

##Create a Rect
func makeGraphic(graphicWidth: float = 30.0, graphicHeight: float = 30.0, graphicColor: Color = Color.BLACK):
	if animation:
		animation.clearLibrary()
	image.texture = null

##Cut the Image, just works if [u]not animated[/u] and [member image.texture] is a [AtlasTexture].
func setGraphicSize(sizeX: float = -1.0, sizeY: float = -1.0) -> void:
	if !image.texture:
		return
	if sizeX == -1.0:
		sizeX = image.region_rect.size.x
	if sizeY == -1.0:
		sizeY = image.region_rect.size.y
	var size = Vector2(sizeX,sizeY)
	image.region_rect.size = size
	pivot_offset = size/2.0

func setGraphicScale(_scale: Vector2) -> void:
	scale.x = _scale.x
	scale.y = _scale.y
	_graphic_scale = Vector2.ONE-_scale
	
	
func join(front: bool = false):
	if groups:
		groups.back().add(self,true)
		return
	
	if camera:
		camera.add(self,front)
	
	if _lastParent:
		_lastParent.add_child(self)
		return
	
	
##Remove the Sprite from the game, still can be accesed.
func kill() -> void:
	if parent:
		parent.remove_child(self)
	
	
func removeFromGroups() -> void:
	for group in groups:
		group.remove(self)

##Returns an [PackedVector2Array], containing non-transparent pixels position, used to make the light points.[br][br]
##[u][code]pixelDiv[/code] divides the calculations, reducing the amount of forces, but making the pixels less accurate
func getPixelArea(area: Rect2 = image.get_region_rect(),pixelDiv: Vector2i = Vector2i(3,3)) -> PackedVector2Array:
	if !image.texture:
		return []
	
	var image: Image = (image.texture.atlas if image.texture is AtlasTexture else image.texture).get_image()
	var array: PackedVector2Array = []
	
	var x_range = range(area.position.x,area.position.x + area.size.x,pixelDiv.x)
	var y_range = range(area.position.y,area.position.y + area.size.y,pixelDiv.y)
	
	if x_range.back() != area.size.x:
		x_range.append(area.size.x)
	if y_range.back() != area.size.y:
		y_range.append(area.size.y)
	
	var cur_x = 0
	for pos_x in x_range:
		var alphas: Array = []
		var x: float = pos_x - area.position.x
		
		var cur_y = 0
		for pos_y in y_range:
			var can_set = image.get_pixel(pos_x,pos_y).a < 0.5
			continue
			var y = pos_y - area.position.y
			var last_alpha = alphas[cur_y-1] if alphas else false
			array.append(Vector2(x,y))
			cur_y += 1
		cur_x += 1
		
	return array

##When the [code]animName[/code] plays, the offset placed in [code]offsetX,offsetY[/code] will be set.
func addAnimOffset(animName: StringName, offsetX: float = 0.0, offsetY: float = 0.0, offsetZ: float = 0.0) -> void:
	_animOffsets[animName] = Vector3(offsetX,offsetY,offsetZ)
	if animation and animation.curAnim.name == animName:
		offset = Vector3(offsetX,offsetY,offsetZ)

static func get_sprite() -> Sprite3D:
	var sprite = Sprite3D.new()
	sprite.region_enabled = true
	sprite.centered = false
	sprite.use_parent_material = true
	return sprite
	
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			set_node_process(self,false)
		NOTIFICATION_PARENTED:
			_lastParent = parent
			parent = get_parent()
		NOTIFICATION_UNPARENTED:
			parent = null
		NOTIFICATION_DISABLED:
			if animation:
				animation.curAnim.process_frames = false
		NOTIFICATION_ENABLED:
			if animation:
				animation.curAnim.process_frames = true

static func set_node_process(obj: Node, process: bool = false):
	#obj.set_process(process)
	obj.set_physics_process(process)
	obj.set_physics_process_internal(process)
	obj.set_process_input(process)
	obj.set_process_internal(process)
	obj.set_process_shortcut_input(process)
	obj.set_process_unhandled_input(process)
	obj.set_process_unhandled_key_input(process)

func _set_image(node: Node3D):
	if !node:
		return
	if animation:
		animation.image = node
	add_child(node)
	node.texture_changed.connect(_update_texture)
	node.owner = get_tree().edited_scene_root
	
	
