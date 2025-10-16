@tool
extends Node2D
const ModchartEditor = preload("res://source/states/Modchart/Editor/ModchartEditor.gd")
@export var timeline_offset: float = 20.0:
	set(value):
		timeline_offset = value
		queue_redraw()

@export var timeline_space: float = 40.0:
	set(value):
		timeline_space = value
		queue_redraw()
@export var steps: int = 0:
	set(value):
		steps = value
		queue_redraw()

@export var line_height: float = 20.0:
	set(value):
		line_height = value
		queue_redraw()
		
func _draw() -> void:
	var step: int = -1
	var draw_line: bool = true
	var line_center = timeline_space/2.0
	var line_center_y = line_height/2.0
	var rect_height = line_height/2.0
	var pos_x: float = -timeline_space + timeline_offset
	
	var text_offset: float = 0.0
	
	var text_size = mini(16,(ModchartEditor.grid_size.x+6)/int(str(steps).length())) #24(GRID_SIZE) - 4
	var text_space = text_size/3.25
	while step < steps or draw_line:
		if draw_line:
			draw_rect(Rect2(
				Vector2(pos_x + line_center + 1.5,line_center_y),
				Vector2(3,rect_height)
			),Color.WHITE)
		else:
			step += 1
			text_offset = int(str(step).length()-1)
			pos_x += timeline_space
			draw_string(
				ThemeDB.fallback_font,
				Vector2(pos_x - text_offset*text_space,line_height),
				str(step),
				HORIZONTAL_ALIGNMENT_CENTER,
				-1,text_size
			)
		draw_line = !draw_line
