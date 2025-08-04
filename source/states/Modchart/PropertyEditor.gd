extends PanelContainer

const Grid = preload("res://source/states/Modchart/Grid.gd")
const DropdownBox = preload("res://source/states/Modchart/DropdownBox.gd")
const GridShader = preload("res://assets/shaders/Grid.gdshader")

@onready var scroll := $VBoxContainer/Scroll
@onready var bg := $VBoxContainer/Scroll/Panel
@onready var property_scroll := $"../P_Container/S_Container/Scroll"
@onready var position_line := $VBoxContainer/Scroll/Panel/PositionLine

static var GridMaterial = ShaderMaterial.new()
var grids_created: Array = []

static func _static_init() -> void:
	GridMaterial.shader = GridShader
	GridMaterial.set_shader_parameter('grid_bg_enabled',true)

func _ready():
	var v_scroll_property: VScrollBar = property_scroll.get_v_scroll_bar()
	var v_scroll: VScrollBar = scroll.get_v_scroll_bar()
	v_scroll.scrolling.connect(func(): property_scroll.scroll_vertical = v_scroll.value)
	v_scroll_property.scrolling.connect(func(): scroll.scroll_vertical = v_scroll_property.value)
	
func createGrid(text_shader: DropdownBox) -> Grid:
	if !text_shader: return
	
	var grid = Grid.new()
	var size_y = text_shader.separator.get_minimum_size().y
	grid.name = text_shader.name
	grid.size = Vector2(bg.size.x,size_y)
	grid.material = GridMaterial.duplicate()
	grid.grid_size = Vector2(50,size_y/text_shader.texts.size())
	grid.visible = false
	
	bg.add_child(grid)
	
	var grid_data = [grid,text_shader]
	text_shader.minimum_size_changed.connect(func():
		updateGridPosition(grid_data)
	)
	text_shader.toggled.connect(func(toggled):
		if toggled:
			showGrid(grid_data)
			return
		hideGrid(grid_data)
	)
	grids_created.append(grid_data)
	return grid

func removeGrid(grid):
	for i in grids_created:
		if i[0] == grid:
			grids_created.erase(i)
			break
	
func showGrid(grid_data: Array):
	if !grid_data:
		return
	grid_data[0].visible = true
	updateGridPosition(grid_data)
	
func updateGridPosition(grid_data):
	if grid_data[0].visible:
		grid_data[0].position.y = grid_data[1].position.y + grid_data[1].separator.position.y + 8
		
func hideGrid(grid_data: Array):
	if !grid_data: return
	grid_data[0].visible = false

func _notification(what: int) -> void:
	if position_line and what == NOTIFICATION_RESIZED:
		position_line.size.y = size.y
