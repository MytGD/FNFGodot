@tool
##A base [Sprite2D] to be compatible with [Anim].
extends Sprite2D

var _frame_offset: Vector2: set = set_frame_offset
var _frame_angle: float: set = set_frame_angle

var pivot_offset: Vector2: set = set_pivot_offset
var is_solid: bool = false

func _init() -> void: region_enabled = true; centered = false; use_parent_material = true; texture_changed.connect(_texture_changed)
func _update_offset() -> void: position = _frame_offset - (pivot_offset*scale - pivot_offset)

func set_graphic_size(size: Vector2) -> void: if is_solid: scale = size; return
func set_pivot_offset(pivot: Vector2) -> void: pivot_offset = pivot; _update_offset()
func set_frame_angle(angle: float) -> void: rotation = angle*scale.x;
func set_frame_offset(off: Vector2) -> void: _frame_offset = off*scale; _update_offset();
func _texture_changed() -> void: _frame_offset = Vector2.ZERO; rotation = 0;
func _draw() -> void: if is_solid: draw_rect(Rect2(0,0,1,1),Color.WHITE)

func _make_solid() -> void:
	if is_solid: return
	pivot_offset = Vector2.ZERO
	texture = null
	is_solid = true
	centered = true
	scale = Vector2.ONE
	queue_redraw()
