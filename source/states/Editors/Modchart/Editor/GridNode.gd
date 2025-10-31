@tool
@icon("res://icons/GridGreen.svg")
class_name GridNode extends Control
const GridShader = preload("uid://dversuc1owccd")

static var grid_shader: ShaderMaterial = _get_grid_material()
@onready var rid = get_canvas_item()
func _ready() -> void:
	material = grid_shader
	resized.connect(func():material.set_shader_parameter('parent_size',size))

func _draw() -> void: draw_rect(Rect2(Vector2.ZERO,size),Color.WHITE)

static func _get_grid_material():
	var shader_material = ShaderMaterial.new()
	shader_material.shader = grid_shader
	return shader_material
