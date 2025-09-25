@tool
class_name SolidSprite extends Node2D
func _draw(): 
	draw_rect(Rect2(Vector2.ZERO,Vector2(1,1)),Color.WHITE)
