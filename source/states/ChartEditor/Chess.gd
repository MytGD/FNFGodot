extends Node2D

var line_size = Vector2(16,16)
var line_length = 4
var steps: int = 16

var chess_rects: Array[ColorRect]
var chess_colors = [Color.GRAY,Color.DIM_GRAY]
func loadChess(steps_length: int = steps, lines: int = line_length):
	steps = steps_length
	line_length = lines
	draw_chess()

func draw_chess():
	var max_steps = steps*line_length
	while max_steps - chess_rects.size() < 0:
		chess_rects.pop_back().queue_free()
		
	while max_steps - chess_rects.size() > 0:
		var color = ColorRect.new()
		color.process_mode = Node.PROCESS_MODE_DISABLED
		color.mouse_filter = Control.MOUSE_FILTER_IGNORE
		color.size = line_size
		color.name = 'Color'+str(chess_rects.size())
		chess_rects.append(color)
		add_child(color)
		move_child(color,0)
	
	var index = 0
	for y in range(steps):
		for x in range(line_length):
			var color_rect = chess_rects[index]
			color_rect.position = Vector2(x,y)*line_size
			color_rect.color = chess_colors[(x+y)%2]
			color_rect.size = line_size
			index += 1
