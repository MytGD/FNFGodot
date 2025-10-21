@tool
class_name SolidSprite extends Node2D
@export var filled: bool = true: set =set_filled
@export var width: float = 16: set = set_width
@export var size: Vector2 = Vector2.ONE: set = set_size

func set_size(_new_size: Vector2): size = _new_size; queue_redraw()
func set_filled(_filled: bool): filled = _filled; queue_redraw()
func set_width(_width: float):  width = _width; if !filled: queue_redraw()

func _draw(): 
	if filled: draw_rect(Rect2(Vector2.ZERO,size),Color.WHITE,true,width)
	else: draw_rect(Rect2(Vector2.ZERO,size),Color.WHITE)
