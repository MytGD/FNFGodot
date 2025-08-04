extends Node2D

@onready var modchartEditor = $/root/ModchartEditor

const KeyInterpolator = preload("res://source/states/Modchart/KeyInterpolator.gd")
const Points: PackedVector2Array = [
	Vector2(0, 0.5), #Left
	Vector2(0.5, 0), #Top
	Vector2(1, 0.5), #Right
	Vector2(0.5, 1) #Down
]

var polygon_points: PackedVector2Array = PackedVector2Array()

#Grid to Follow
var grid: Control
var grid_x_size: float:
	get():
		return grid.grid_size.x if grid else 50

var size: Vector2 = Vector2(10,10):
	set(value):
		size = value
		reloadPoints()
		
var key_length: float = 0.0
var key_data: KeyInterpolator

func _ready() -> void: reloadPoints()
	
func _process(delta: float) -> void: position.x = getKeyPosition()

func getKeyPosition(): return (key_data.step - modchartEditor.grid_x) * grid_x_size

func reloadPoints():
	var center = size/2.0
	for i in Points: polygon_points.append(i*size - center)
	queue_redraw()
	
func _draw() -> void:
	var points: PackedVector2Array = []
	draw_polygon(polygon_points,PackedColorArray([Color.WHITE]))
	
	if !key_data.duration: key_length = 0.0; return
	
	var div = size/3.0
	points.clear()
	
	key_length = key_data.duration*1000/Conductor.stepCrochet * grid_x_size
	
	var center = size/2.0
	for i in Points: points.append(i*size - center + Vector2(key_length,0))
	
	if grid: draw_rect(Rect2(0, -div.y/2.0, key_length, div.y), Color.WHITE)
	draw_polygon(points,PackedColorArray([Color.WHITE]))
