@tool
extends Control
@export var flip_h: bool = false:
	set(flip):
		if flip_h == flip:
			return
		flip_h = flip
		scale.x = -1 if flip else 1
		
@export var flip_v: bool = false:
	set(flip):
		if flip_v == flip:
			return
		flip_v = flip
		scale.y = -1 if flip else 1
		
var _updating_pos: bool = false

@export var texture: Texture2D:
	set(tex):
		graphic.texture = tex
	get():
		return graphic.texture
		
@export var region_rect: Rect2:
	set(rect):
		graphic.region_rect = rect
	get():
		return graphic.region_rect

@export var graphic: NinePatchRect = get_node_or_null("Texture")

signal texture_changed
func _init():
	clip_contents = true
	if !graphic:
		graphic = NinePatchRect.new()
	use_parent_material = true
	graphic.use_parent_material = true
	graphic.name = 'Texture'
	
	graphic.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	graphic.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	#clip_contents = true
	graphic.texture_changed.connect(func():
		if texture:
			size = texture.get_size()
			graphic.size = size
			if texture is AtlasTexture:
				texture.region = Rect2(0,0,0,0)
			pivot_offset = size/2.0
		graphic.rotation = 0.0
		texture_changed.emit()
	)
	
	add_child(graphic)
	name = 'spriteSheet'

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		graphic.rotation = rotation
		rotation = 0
		graphic.size = size
