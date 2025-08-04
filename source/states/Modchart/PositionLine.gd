extends ColorRect

@onready var modchartEditor = $"/root/ModchartEditor"

var grid_offset: float = 10
func _ready():
	get_parent().child_entered_tree.connect(func(node):
		get_parent().move_child(self,-1)
	)
func _process(delta: float) -> void:
	var pos = (Conductor.step_float - (modchartEditor.song_step - Conductor.step_float))
	if pos > grid_offset:
		var offset = pos - grid_offset
		modchartEditor.grid_x = offset
		position.x = (pos - offset)*modchartEditor.grid_size_x
	elif pos < 0:
		var offset = -24
		modchartEditor.grid_x = offset
		position.x = (pos - offset)*modchartEditor.grid_size_x
	else:
		modchartEditor.grid_x = 0
		position.x = pos*modchartEditor.grid_size_x
