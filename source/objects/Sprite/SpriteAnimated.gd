##A Base [Node2D] to make animations using [Anim] object.
##Set this to [code]true[/code] if you want that sprite animated.
@icon('../icons/AnimatedSprite.svg')
extends Node2D
class_name SpriteAnimated
const Anim = preload("res://source/general/animation/Anim.gd")
const Graphic = preload("res://source/objects/Sprite/Graphic.gd")

@export var is_animated: bool = true: 
	set(value):
		if value == is_animated: return
		is_animated = value
		if value: _create_animation()

@export var animation: Anim ##The animation class. See how to use in [Anim].
@export var pivot_offset: Vector2: set = set_pivot_offset

##The Node that will be animated. [br]
##Can be a [Sprite2D] with [member Sprite2D.region_enabled] enabled
## or a [NinePatchRect]
@export var image: CanvasItem = Graphic.new(): set = set_image_node

var autoUpdateImage: bool = true:
	set(value):
		if autoUpdateImage == value: return
		autoUpdateImage = value
		if !image: return
		if value: image.texture_changed.connect(_update_texture)
		else: image.texture_changed.disconnect(_update_texture)
		
@export var flipX: bool: set = flip_h ##Flip the sprite horizontally.
@export var flipY: bool: set = flip_v ##Flip the sprite vertically.
func _init():
	_create_animation()
	image.name = 'Sprite'
	add_child(image)
	_update_image()


func _update_image(image_node: CanvasItem = image):
	if autoUpdateImage: image_node.texture_changed.connect(_update_texture)
	_update_image_flip()

func _update_texture() -> void:
	if is_animated: animation.clearLibrary(); return
	if !image.texture: 
		pivot_offset = Vector2.ZERO
		image.pivot_offset = pivot_offset
		return
	
	var size = image.texture.get_size()
	image.region_rect = Rect2(Vector2.ZERO,size)
	pivot_offset = size/2.0
	image.pivot_offset = pivot_offset

func _update_image_flip() -> void:
	image.scale = Vector2(-1 if flipX else 1, -1 if flipY else 1)
	if image is Graphic: image._update_offset()

#region Animation Methods
func _create_animation() -> void: 
	if animation or !is_animated: return
	animation = Anim.new()
	_connect_animation()

func _update_animation_image() -> void:
	if !animation: return
	animation.image = image
	animation.curAnim.node_to_animate = image

func _connect_animation() -> void:
	animation.image_animation_enabled.connect(func(enabled): autoUpdateImage = !enabled)
	animation.image_parent = self
	_update_animation_image()
	image.region_rect = Rect2(0,0,0,0)

func set_anim_process(process: bool) -> void:
	animation.curAnim.can_process = process
	if process: animation.curAnim.start_process(); return
	animation.curAnim.playing = false
#endregion

#region Setters
func set_image_node(node: CanvasItem): 
	image = node; 
	_update_animation_image()
	if image: image.name = 'Sprite'

func set_pivot_offset(value: Vector2) -> void: pivot_offset = value

func flip_h(flip: bool = flipX) -> void:
	if flip == flipX: return
	flipX = flip
	_update_image_flip()
	
func flip_v(flip: bool = flipY) -> void:
	if flipY == flip: return
	flipY = flip
	_update_image_flip()
#endregion

func _notification(what: int) -> void:
	if !animation: return
	match what:
		NOTIFICATION_DISABLED, NOTIFICATION_EXIT_TREE: set_anim_process(false)
		NOTIFICATION_ENABLED, NOTIFICATION_ENTER_TREE: set_anim_process(true)
