@tool
extends Control
var line_size: Vector2 = Vector2(16,16)
var line_length: int = 4: set = set_line_length
var steps: int = 16: set = set_steps

var chess_colors: PackedColorArray = [Color.GRAY,Color.DIM_GRAY]
func loadChess(steps_length: int = steps, lines: int = line_length):
	steps = steps_length
	line_length = lines

func _draw() -> void:
	for y in range(steps): for x in range(line_length): 
		draw_rect(Rect2(Vector2(x,y)*line_size,line_size),chess_colors[(x+y)%2])
	size = Vector2(line_length,steps)*line_size

func set_steps(_s: int) -> void:
	if steps == _s: return
	steps = _s
	queue_redraw()
func set_line_length(length: int) -> void:
	if length == line_length: return
	line_length = length
	queue_redraw()
