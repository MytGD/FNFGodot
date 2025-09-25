##A Base [Node2D] to make animations using [Anim] object.
##Set this to [code]true[/code] if you want that sprite animated.
extends Node2D
class_name SpriteAnimated
const Anim = preload("res://source/general/animation/Anim.gd")
const Graphic = preload("res://source/objects/Sprite/Graphic.gd")

@export var is_animated: bool = true: 
	set(value):
		if value == is_animated: return
		is_animated = value
		if value: _create_animation()

 ##The animation class. See how to use in [Anim].
@export var animation: Anim

@export var pivot_offset: Vector2: set = set_pivot_offset

##The Node that will be animated. [br]
##Can be a [Sprite2D] with [member Sprite2D.region_enabled] enabled
## or a [NinePatchRect]
@export var image: CanvasItem = Graphic.new():
	set(value):
		image = value
		_update_animation_image()

var autoUpdateImage: bool = true:
	set(value):
		if autoUpdateImage == value: return
		if image:
			if value: image.texture_changed.connect(_update_texture)
			else: image.texture_changed.disconnect(_update_texture)
		autoUpdateImage = value
@export var flipX: bool: set = flip_h ##Flip the sprite horizontally.
@export var flipY: bool: set = flip_v ##Flip the sprite vertically.

signal pivot_changed

func _init():
	_create_animation()
	add_child(image)
	_update_image()

func _create_animation():
	if animation or !is_animated: return
	animation = Anim.new()
	_connect_animation()
	
func _update_image(image_node: CanvasItem = image):
	if autoUpdateImage: image_node.texture_changed.connect(_update_texture)
	_update_image_flip()

func _update_animation_image():
	if !animation: return
	animation.image = image
	animation.curAnim.node_to_animate = image

func _notification(what: int) -> void:
	if !animation: return
	match what:
		NOTIFICATION_DISABLED, NOTIFICATION_EXIT_TREE:
			animation.curAnim.can_process = false
			animation.curAnim.playing = false
		NOTIFICATION_ENABLED, NOTIFICATION_ENTER_TREE:
			animation.curAnim.can_process = true
			animation.curAnim.start_process()

func _connect_animation():
	animation.image_animation_enabled.connect(func(enabled): autoUpdateImage = !enabled)
	animation.image_parent = self
	_update_animation_image()
	image.region_rect = Rect2(0,0,0,0)
	
func _update_texture():
	if is_animated: animation.clearLibrary()
	elif image.texture: 
		var size = image.texture.get_size()
		image.region_rect = Rect2(Vector2.ZERO,size)
		pivot_offset = size/2.0
		image.pivot_offset = pivot_offset
	else:
		pivot_offset = Vector2.ZERO
		image.pivot_offset = pivot_offset
	
func set_pivot_offset(value: Vector2) -> void: #Replaced in several scripts.
	pivot_offset = value
	pivot_changed.emit()

func flip_h(flip: bool = flipX) -> void:
	if flip == flipX: return
	flipX = flip
	_update_image_flip()
	
func flip_v(flip: bool = flipY) -> void:
	if flipY == flip: return
	flipY = flip
	_update_image_flip()
	
func _update_image_flip() -> void:
	image.scale = Vector2(-1 if flipX else 1, -1 if flipY else 1)
	if image is Graphic: image._update_offset()
