@tool
extends Chess
const NoteChart = preload("uid://dxl7cofy02rr5")
var notes: Node2D = Node2D.new()

var _beat_lines: Array
func _ready() -> void: add_child(notes); _create_beat_lines()

func _draw() -> void: super._draw(); _create_beat_lines()

func _create_beat_lines():
	for i in _beat_lines: i.queue_free()
	_beat_lines.clear()
	
	var beats = int(length/4)
	while beats:
		var line = SolidSprite.new()
		line.size = Vector2(width,3)
		line.modulate = Color.RED
		line.position.y = rect_size.y*beats*4
		add_child(line)
		_beat_lines.append(line)
		beats -= 1
	
