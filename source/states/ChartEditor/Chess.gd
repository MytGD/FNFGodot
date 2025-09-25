@tool
extends Node2D
var line_size = Vector2(16,16)
var line_length = 4
var steps: int = 16

var chess_colors: PackedColorArray = [Color.GRAY,Color.DIM_GRAY]
func loadChess(steps_length: int = steps, lines: int = line_length):
	steps = steps_length
	line_length = lines

func _draw() -> void:
	var index = 0
	for y in range(steps):
		for x in range(line_length):
			draw_rect(Rect2(Vector2(x,y)*line_size,line_size),chess_colors[(x+y)%2])
			index += 1
