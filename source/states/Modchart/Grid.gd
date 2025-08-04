@tool
extends ColorRect

@onready var modchartEditor = $"/root/ModchartEditor"

var grid_size: Vector2 = Vector2(50,24):
	set(value):
		grid_size = value
		update_grid_size()

func _init() -> void: color = Color.TRANSPARENT

func _process(delta: float) -> void: update_grid_pos()

func update_grid_pos():
	if material: material.set_shader_parameter('x',modchartEditor.grid_x)

func update_grid_size():
	if material: material.set_shader_parameter('grid_size',grid_size)
		
func _notification(what: int) -> void:
	if !material:return
	match what:
		NOTIFICATION_DRAW: material.set_shader_parameter('parent_size',size)
		NOTIFICATION_READY:
			update_grid_pos()
			update_grid_size()
