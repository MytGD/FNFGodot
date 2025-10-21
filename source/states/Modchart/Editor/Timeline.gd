@tool
extends Node2D
const ModchartEditor = preload("res://source/states/Modchart/Editor/ModchartEditor.gd")
@export_range(-40,40,1.0) var timeline_offset: float = 20.0: set = set_timeline_offset
@export_range(0,100,1.0)  var timeline_space: float = 40.0: set = set_timeline_space
@export var step_init: int = 0: set = set_step_init
@export var steps: int = 0: set = set_steps
@export var line_height: float = 20.0: set = set_line_height
@export var font_size: int = 14: set = set_font_size

var _timeline_space_center: float = timeline_space/2.0
var height_center: float = line_height/2.0
func _ready() -> void: set_notify_transform(true)
func _draw() -> void:
	var _pos = position.x
	var steps_offset = _pos/timeline_offset
	
	var step: int = step_init - steps_offset
	var steps_to_be_draw = mini(steps-step,30)
	var limit_area: float = get_viewport_rect().size.x + _pos
	var pos_x: float = -timeline_space + timeline_offset - steps_offset
	print(pos_x)
	while step <= steps_to_be_draw:
		var line_pos_x = pos_x + _timeline_space_center + 1.5
		draw_rect(Rect2(
			Vector2(line_pos_x, height_center),
			Vector2(3, height_center)
		), Color.WHITE)
		pos_x += timeline_space
		if line_pos_x >= limit_area: break
		step += 1
	
	step = step_init
	pos_x = timeline_offset
	var text_size: int
	while step <= steps_to_be_draw:
		var str_step = str(step)
		var cur_step_length = str_step.length()
		text_size = font_size - cur_step_length if cur_step_length else font_size
		
		draw_string(
			ThemeDB.fallback_font,
			Vector2(pos_x, line_height),
			str_step,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			text_size
		)
		pos_x += timeline_space
		if pos_x >= limit_area: break
		step += 1

func set_font_size(size: int): font_size = size; queue_redraw()
func set_step_init(init: int): step_init = minf(init,steps); queue_redraw()
func set_steps(val: int): steps = val; queue_redraw()
func set_timeline_space(space: float): timeline_space = space;_timeline_space_center = space/2.0; queue_redraw()
func set_timeline_offset(off: float):timeline_offset = off; queue_redraw()
func set_line_height(height: float): line_height = height;height_center = height/2.0; queue_redraw()

func _notification(what: int) -> void: 
	if what == NOTIFICATION_TRANSFORM_CHANGED: queue_redraw()
