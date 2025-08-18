@tool
extends Sprite2D 
##A base [Sprite2D] to be compatible with [Anim].

var _frame_offset: Vector2:
	set(value):
		_frame_offset = value*scale
		_update_offset()

var _frame_angle: float: 
	set(value): rotation = value*scale.x

## Adjusts the visual pivot point of the graphic, especially when flipped or scaled.
## Works like `pivot_offset` in `NinePatchRect`.
var pivot_offset: Vector2:
	set(value):
		pivot_offset = value
		_update_offset()

var graphic_color: Color = Color.WHITE: set = set_graphic_color
var is_solid: bool = false
func _init() -> void:
	region_enabled = true
	centered = false
	use_parent_material = true
	texture_changed.connect(_update_texture)

func _update_offset() -> void:
	position = _frame_offset - (pivot_offset*scale - pivot_offset)
	
func set_graphic_color(color: Color) -> void:
	if texture: texture = null
	if !is_solid:
		is_solid = true
		centered = true
	graphic_color = color
	pivot_offset = Vector2.ZERO
	queue_redraw()

func _update_texture() -> void:
	_frame_offset = Vector2.ZERO
	_frame_angle = 0
	pass

func _draw() -> void:
	if is_solid: draw_rect(Rect2(0,0,1,1),graphic_color)
