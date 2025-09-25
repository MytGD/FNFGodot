extends Control
const KeyInterpolator = preload("res://source/states/Modchart/KeyInterpolator.gd")
const ModchartEditor = preload("res://source/states/Modchart/ModchartEditor.gd")
const Points: PackedVector2Array = [
	Vector2(0, 0.5), #Left
	Vector2(0.5, 0), #Top
	Vector2(1, 0.5), #Right
	Vector2(0.5, 1) #Down
]

const KEY_SIZE = Vector2(10,10)
const KEY_LENGTH_SIZE = 5
static var polygon_points: PackedVector2Array = PackedVector2Array()

var data: KeyInterpolator

var step_crochet: float = 0.0: set = _set_step_crochet #Sets in ModchartEditor
var step: float = 0.0 #Sets and used in Grid
var parent
var length: float = 0.0


func _init(interpolator: KeyInterpolator = KeyInterpolator.new()): 
	#rotation_degrees = 45
	data = interpolator
	data.key_node = self
	size = KEY_SIZE
	if !polygon_points:
		var center = KEY_SIZE/2.0
		for i in Points: polygon_points.append(i*KEY_SIZE - center)
	
func _draw() -> void:
	if data.duration: 
		length = data.duration/step_crochet*ModchartEditor.GRID_SIZE.x
		draw_rect(Rect2(
			-size/3.5,
			Vector2(length,KEY_LENGTH_SIZE)
		),Color.WHITE)
	else:
		length = 0.0
	draw_polygon(polygon_points,PackedColorArray([Color.WHITE]))

func _set_step_crochet(crochet: float):
	step_crochet = crochet
	queue_redraw()
