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
	
func _update_offset() -> void:
	if pivot_offset == Vector2.ZERO: position = _frame_offset; return
	position = _frame_offset - (pivot_offset*scale - pivot_offset)

func set_graphic_color(color: Color):
	if texture: texture = null
	if !is_solid:
		is_solid = true
		centered = true
	pivot_offset = Vector2.ZERO
	queue_redraw()

func _draw():
	if is_solid: draw_rect(Rect2(0,0,1,1),graphic_color)
