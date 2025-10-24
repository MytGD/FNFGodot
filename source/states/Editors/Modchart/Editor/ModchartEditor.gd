extends Node

const GRID_SIZE = Vector2(40,24)
const Grid = preload("res://source/states/Editors/Modchart/Editor/Grid.gd")

const ModchartState = preload("res://source/states/Editors/Modchart/ModchartState.gd")

const EditorMaterial = preload("res://source/states/Editors/Modchart/Shaders/EditorShader.gd")

const StrumNote = preload("res://source/objects/Notes/StrumNote.gd")
const Sprite = preload("res://source/objects/Sprite/Sprite.gd")
const Character = preload("res://source/objects/Sprite/Character.gd")
const CameraCanvas = preload("res://source/objects/Display/Camera/Camera.gd")
const SpriteGroup = preload("res://source/general/groups/SpriteGroup.gd")
const PlayState = preload("res://source/states/PlayState.gd")
const Bar = preload("res://source/objects/UI/Bar.gd")
const GDText = preload("res://source/objects/Display/GDText.gd")

const KeyInterpolator = preload("res://source/states/Editors/Modchart/Keys/KeyInterpolator.gd")
const KeyInterpolatorNode = preload("res://source/states/Editors/Modchart/Editor/KeyInterpolatorNode.gd")

#region Ranges Const
const ButtonRange = preload("res://scenes/objects/ButtonRange.gd")
const ButtonRangeScene = preload("res://scenes/objects/ButtonRange.tscn")

const HSliderRange = preload("res://scenes/objects/HSliderRange.gd")
const HSliderRangeScene = preload("res://scenes/objects/HSliderRange.tscn")

const LineEditWithTitleScene = preload("res://scenes/objects/LineEditWithTitle.tscn")
const LineEditWithTitle = preload("res://scenes/objects/LineEditWithTitle.gd")
#endregion

var screen_size_mult = ScreenUtils.screenSize*2

var PropertiesAvaliable := {
	PlayState: {
		'defaultCamZoom': {'range': [-5,5]},
		'cameraSpeed': {'range': [0.2,10]},
		'scrollSpeed':  {'range': [0.2,10]},
		'zoomSpeed': {'range': [0.0,15.0]},
		'camZooming': null
	},
	CameraCanvas:{
		'x': {'range': [-screen_size_mult.x,screen_size_mult.x,1]},
		'y': {'range': [-screen_size_mult.x,screen_size_mult.x,1]},
		'shakeIntensity': {'range': [0,0.3,0.001]},
		'scroll': null,
		'zoom': null,
		'defaultZoom': {'range': [-7,7,0.1]},
		'angle': {'range': [-360,360,0.1]}
	},
	Sprite:{
		'x': null,
		'y': null,
		'velocity': {'step_x': 10,'step_y': 10},
		'acceleration': null,
		'scrollFactor': {'range_x': [0.0,10.0,0.1],'range_y': [0.0,10.0,0.1]}
	},
	SpriteGroup: {
		'x': null,
		'y': null
	},
	Bar: {
		'position': null,
		'scale': null,
		'rotation': null,
	},
		GDText:{
		'x': null,
		'y': null
	},
	StrumNote:{'direction': {'range': [-360,360]}},
	'Label':{
		'text': null,
		"visible_ratio": {'range': [0.0,1.0,0.01]}
	},
	'Node2D': {
		'scale': {'type': TYPE_FLOAT,'range': [-12,12]}
	}
}


var default_values: Dictionary[Object,Dictionary] = {}
var modchart_keys = ModchartState.keys
var modchart_upating = ModchartState.keys_index

var songPosition: float = 0.0: set = set_song_editor_position
var grids: Dictionary[String,Grid] = {}

#region PlayState Variables
@onready var playState = $SubViewport/PlayState
static var songToLoad = 'test'
#endregion

#region Nodes
@onready var dialog_bg = $BG
@onready var dialog: FileDialog = $FileDialog
@onready var confirm_dialog: ConfirmationDialog = $ConfirmationDialog

@onready var key_options = $KeyOptions
#region Timeline
@onready var position_line = $VSplit/HSplitP/HTimeline/Timeline/Time/PositionLine
@onready var timeline_panel = $VSplit/HSplitP/HTimeline/Timeline
@onready var timeline = $VSplit/HSplitP/HTimeline/Timeline/Time
#endregion

#endregion

#region Property Editor Variables
@onready var explorer_nodes = $VSplit/HSplit/PanelContainer/Explorator/Explorer

var properties_created: Array
@onready var properties_tab = $VSplit/HSplit/HSplit/Property/Properties/Scroll/Container
@onready var properties_select_obj_text = $VSplit/HSplit/HSplit/Property/Properties/InfoText
var property_label_settings = LabelSettings.new()

const UPDATE_PROPERTY_EVERY = 1.0/10.0
var property_update_el: float = 0.0
#endregion

#region Grid Properties
const grid_shader = preload("res://source/states/Editors/Modchart/Shaders/Grid.gdshader")
var grid_x: float = 0.0
var grid_real_x: float = 0.0

static var grid_size: Vector2 = GRID_SIZE
var grid_zoom: float = 1.0
#endregion

#region TimeLine Properties
var is_moving_line: bool = false
var last_position_line: Vector2 = Vector2.ZERO
var position_line_offset: float = 0.0
#endregion

#region Grid
@onready var grid_material = ShaderMaterial.new()
@onready var grid_scroll = $VSplit/HSplitP/HTimeline/GridContainer/Panel
@onready var grid_container: Panel = $VSplit/HSplitP/HTimeline/GridContainer
@onready var grid_property = $VSplit/HSplitP/Panel/Panel/Scroll/VBox
#endregion

#region Media Area
const MediaData = preload("uid://ckoa4kdjfntbw")
@onready var Media = $VSplit/HSplit/PanelContainer/Media
#endregion
#region Shader Area

#endregion

#region Keys Area
var is_shift_pressed: bool = false

var grid_selected: Grid
var keys_selected: Array[KeyInterpolatorNode] = []
var is_key_mouse_pressed: bool = false
var is_moving_keys: bool = false

var key_last_mouse_pos: float = 0.0
var key_type: Variant.Type = TYPE_NIL
var key_is_int: bool = false
var keys_copied: Array[KeyInterpolator] = []

var key_moving_first_pos: float = 0


#Textures
const KeyNormalTexture = preload("res://icons/KeyBezierHandle.svg")
const KeySelectedTexture = preload("res://icons/KeySelected.svg")

const RESET_TEXTURE = preload("res://icons/Reload.svg")
#endregion

#region Different values
var is_type_different: bool = false
var is_duration_different: bool = false
var is_transition_different: bool = false
var is_ease_different: bool = false
#endregion

#region Explorer
var explorer_object_selected: Object
var explorer_object_last_modulate: Color
var explorer_select_effect: bool = false
var explorer_modulate_delta: float = 0.0
var explorer_properties_can_be_update: bool = true
@onready var explorer_area_selected = $SubViewport/ObjectSelected
const SELECT_OBJECT_COLOR = Color(0.68,0.68,0.68)

func _on_explorer_button_selected(button) -> void:
	var obj = button.object
	explorer_properties_can_be_update = true
	if explorer_object_selected:
		if explorer_object_selected == obj: return
		if explorer_select_effect: 
			explorer_object_selected.modulate.r = explorer_object_last_modulate.r
			explorer_object_selected.modulate.g = explorer_object_last_modulate.g
			explorer_object_selected.modulate.b = explorer_object_last_modulate.b
		
	if !show_object_properties(obj):
		explorer_object_selected = null
		explorer_area_selected.visible = false 
		return
	
	explorer_area_selected.visible = true
	explorer_select_effect = obj is CanvasItem
	
	if explorer_select_effect: explorer_object_last_modulate = obj.modulate
	else: explorer_modulate_delta = 0.0
	explorer_object_selected = obj

func _on_explorer_media_button_pressed(button: Button):
	if button == explorer_object_selected: return
	explorer_properties_can_be_update = false
	explorer_object_selected = button
	if button.media is EditorMaterial: show_media_material_properties(button.media)

func _explorer_obj_selected_color(delta: float):
	_explorer_update_area_selected()
	if !explorer_select_effect or !explorer_object_selected: return
	explorer_modulate_delta += delta
	var col = explorer_object_last_modulate.lerp(
		SELECT_OBJECT_COLOR,
		abs(sin(explorer_modulate_delta*3.0))
	)
	explorer_object_selected.modulate = Color(col.r,col.g,col.b,explorer_object_selected.modulate.a)

func _explorer_update_area_selected():
	if !explorer_object_selected: return
	var pos = explorer_object_selected.get('global_position')
	if !pos: pos = Vector2.ZERO
	explorer_area_selected.position = pos
	
	#var canvas_transform = explorer_area_selected.get_transform()
	#print(canvas_transform)
	#explorer_area_selected.size = Vector2(canvas_transform.x.y,canvas_transform.y.x)
#endregion

func _ready() -> void:
	DiscordRPC.state = 'In Modchart Editor'
	DiscordRPC.refresh()
	
	
	property_label_settings.font_size = 13
	
	_update_song_info.call_deferred()
	grid_material.shader = grid_shader
	grid_material.set_shader_parameter('grid_size',GRID_SIZE)
	dialog.current_dir = Paths.exePath+'/'
	dialog.canceled.connect(dialog_bg.hide)
	dialog.file_selected.connect(func(_f): show_dialog(false))
	#Set the state of the PlayState
	playState.inModchartEditor = true
	playState.respawnNotes = true
	
	Conductor.bpm_changes.connect(bpm_changes)

#region Dialog
func show_dialog(show: bool = true, mode: FileDialog.FileMode = FileDialog.FILE_MODE_OPEN_FILE) -> void:
	if show: 
		dialog.clear_filters()
		dialog.file_mode = mode
	dialog_bg.visible = show
	dialog.visible = show

func connect_to_dialog(callable: Callable) -> void: 
	dialog.file_selected.connect(callable,ConnectFlags.CONNECT_ONE_SHOT)
#endregion

#region Properties
func _clear_properties():
	for i in properties_tab.get_children(): i.queue_free()
	properties_created.clear()

func show_object_properties(object: Object) -> bool:
	if object is ShaderMaterial: return false
	
	_clear_properties()
	var properties: Dictionary = _get_object_properties(object)
	
	if !properties: properties_select_obj_text.visible = true; return false
	properties_select_obj_text.visible = false
	
	for i in properties:
		var data = properties[i]
		var separator = _create_property_separator(i,data[1])
		
		var _props = data[0]
		for p in _props: 
			var property = _create_property_buttons(object,p,_props[p])
			if property: separator.properties_to_hide.append_array(property)
	return true

func _get_object_properties(object: Object):
	var script: Script = object.get_script()
	var props: Dictionary
	if script:
		while script:
			var val = PropertiesAvaliable.get(script)
			if val: 
				var _class_n = script.resource_path.get_basename().get_file()
				props[_class_n] = [val,explorer_nodes._get_node_icon(script)]
			script = script.get_base_script()
	
	var name_class = object.get_class()
	var class_props = PropertiesAvaliable.get(name_class)
	if class_props: props[name_class] = [class_props,explorer_nodes._get_class_icon(name_class)]
	return props
func show_media_material_properties(material: EditorMaterial):
	_clear_properties()
	
	var uniforms = material.uniforms
	for i in uniforms: _create_property_buttons(material,i,uniforms[i])
		
	#Load Objects Text
	var objects_edit: LineEditWithTitle = LineEditWithTitleScene.instantiate()
	objects_edit.text = 'Objects:'
	objects_edit.tooltip_text = 'Objects that will contain the shader.'
	objects_edit.edit_text = _get_shader_objects_str(material)
	objects_edit.edit_text_changed.connect(func(_t): material.objects = _t.split(','))
	properties_tab.add_child(objects_edit)

func _get_shader_objects_str(material: EditorMaterial) -> String:
	if !material.objects: return ''
	var text: String = material.objects[0]
	var index: int = 1
	while index < material.objects.size(): text += ','+material.objects[index]; index += 1
	return text

func _create_property_separator(text: String, icon: Texture):
	var separator = PropertySeparator.new()
	separator.class_text = text
	separator.button.icon = icon
	properties_tab.add_child(separator)
	return separator

func _create_property_buttons(object: Object, property: String, data = null) -> Array[Node]:
	var type = typeof(get_object_value(object,property))
	var nodes: Array[Node] = []
	
	match type:
		TYPE_FLOAT,TYPE_INT: 
			nodes.append(_create_property_range(object,property,type == TYPE_INT,data))
		TYPE_VECTOR2,TYPE_VECTOR3,TYPE_VECTOR4,TYPE_VECTOR2I,TYPE_VECTOR3I,TYPE_VECTOR4I:
			nodes.append_array(_create_vectors_properties(object,property,type,data))
		TYPE_BOOL: nodes.append(_create_property_box_button(object,property))
		_: return nodes
	
	for i in nodes: 
		properties_tab.add_child(i)
		_create_interpolator_key_to_button(i)
	return nodes

func _create_property_range(obj: Object, property: Variant, int_value: bool = false, data = null):
	var button
	if data and data.has('range'): button = _create_property_hslider(data.range,int_value)
	else: button = _create_property_button_range(int_value)
	button.set_value_no_signal(get_object_value(obj,property))
	button.name = property
	button.text = property+': '
	button.label_settings = property_label_settings
	button.value_changed.connect(func(_v): set_object_value(obj,property,_v))
	properties_created.append([button,obj,property])
	
	var default_value = _get_obj_property_default(obj,property)
	if default_value != null: _create_reset_property_button(button,default_value)
	return button

func _create_property_button_range(int_value: bool = false) -> ButtonRange:
	var button = ButtonRangeScene.instantiate()
	button.update_min_size_x = true
	button.update_min_size_y = true
	button.int_value = int_value
	button.label_settings = property_label_settings
	if !int_value: button.step = 0.1
	return button

func _create_property_range_vector(obj: Object, property: Variant, index: int, int_value: bool = false, data = null):
	var value = obj[property]
	var index_name = VectorUtils.vectors_index[index]
	var range_name = 'range_'+index_name
	var step_name = 'step_'+index_name
	var button
	
	var custom_step: bool = false
	if data: 
		if data.has(range_name): button = _create_property_hslider(data[range_name],int_value)
		elif data.has(step_name): custom_step = true
	
	if !button: button = _create_property_button_range(int_value)
	button.set_value_no_signal(value[index])
	button.name = property+':'+index_name
	button.text = property+' '+index_name+': '
	button.label_settings = property_label_settings
	if custom_step: button.step = data[step_name]
	return button
	
func _create_vectors_properties(obj: Object, property: Variant, type: Variant.Type, data = null) -> Array[Node]:
	var index: int = 0
	var size = VectorUtils.get_vector_size(type)
	var int_value = type == TYPE_VECTOR2I or type == TYPE_VECTOR3I or type == TYPE_VECTOR4I
	
	var nodes: Array[Node] = []
	var default_value = _get_obj_property_default(obj,property)
	while index < size:
		var button = _create_property_range_vector(obj,property,index,int_value,data)
		nodes.append(button)
		properties_created.append([button,obj,property,index])
		button.value_changed.connect(func(_v): set_object_vector_value(obj,property,index,_v))
		if default_value: _create_reset_property_button(button,default_value[index])
		index += 1
	return nodes

func _create_property_hslider(range_data: Array, rounded: bool = false) -> HSliderRange:
	var button = HSliderRangeScene.instantiate()
	button.min_value = range_data[0]
	button.int_value = rounded
	button.max_value = range_data[1]
	if range_data.size() >= 3: button.step = range_data[2]
	return button

func _create_property_box_button(obj: Object, property: String) -> CheckBox:
	var button = CheckBox.new()
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.name = property
	button.text = ': '+property
	button.add_theme_font_size_override('font_size',property_label_settings.font_size)
	button.focus_mode = Control.FOCUS_NONE
	button.toggled.connect(func(_v): obj[property] = _v)
	return button

func _update_properties() -> void:
	for i in properties_created:
		var obj = i[0]
		var val = get_object_value(i[1],i[2]) if i.size() < 4 else get_object_index_value(i[1],i[2],i[3])
		if obj is CheckBox:
			obj.set_pressed_no_signal(val)
		else: 
			if obj.line_edit.has_focus() or obj is HSliderRange and obj.slider.has_focus(): return
			obj.set_value_no_signal(val)

func _create_interpolator_key_to_button(button: Control) -> void:
	var key = KeyValue.new()
	var bind = _update_interpolator_key_pos.bind(key)
	button.resized.connect(bind)
	button.add_child(key)
	bind.call_deferred()

func _update_interpolator_key_pos(key: Control):
	var parent: Control = key.get_parent()
	if parent is HSliderRange:
		key.position = Vector2(parent.slider.position.x + parent.slider.size.x + 40,parent.size.y/2.0 - 8)
		return
	var min_size = parent.get_combined_minimum_size()
	key.position = Vector2(min_size.x + 40,parent.size.y/2.0 - 8)

func _create_reset_property_button(button_to_connect: Control, default: Variant):
	var button = Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.icon = RESET_TEXTURE
	button.custom_minimum_size = Vector2(23,23)
	button.expand_icon = true
	
	button.pressed.connect(func(): button_to_connect.value = default)
	var func_bind = _check_reset_visible.bind(default,button)
	var pos_func = _update_reset_button_pos.bind(button)
	button_to_connect.value_changed.connect(func_bind)
	button_to_connect.resized.connect(pos_func)
	button_to_connect.add_child(button)
	pos_func.call_deferred()
	func_bind.call_deferred(button_to_connect.value)
	return button

func _check_reset_visible(value: Variant, default: Variant,b: Button): b.visible = value != default

func _update_reset_button_pos(reset_button: Button) -> void:
	var parent: Control = reset_button.get_parent()
	if parent is HSliderRange:
		reset_button.position = Vector2(parent.slider.position.x + parent.slider.size.x,parent.size.y/2.0 - 8)
		return
	var min_size = parent.get_combined_minimum_size()
	reset_button.position = Vector2(min_size.x,parent.size.y/2.0 - 8)

func _check_properties_update(delta: float):
	if !properties_created: return
	property_update_el += delta
	if property_update_el >= UPDATE_PROPERTY_EVERY:
		property_update_el = 0.0
		_update_properties()

func _get_obj_property_default(obj: Object, property: String):
	var default = default_values.get_or_add(obj,{}).get(property)
	if default == null: 
		if obj is EditorMaterial: default = obj.uniforms[property].default
		else: default = obj.property_get_revert(property)
		default_values[obj][property] = default
	return default

func set_object_value(obj: Object, property: String,value: Variant) -> void:
	if obj is ShaderMaterial: obj.set_shader_parameter(property,value); return
	obj.set(property,value)

func set_object_vector_value(obj: Object, property: String, index: int, value: Variant):
	if obj is ShaderMaterial:
		var vector = obj.get_shader_parameter(property)
		match index:
			0: vector.x = value
			1: vector.y = value
			2: vector.z = value
			3: vector.w = value
		obj.set_shader_parameter(property,value)
		return
	match index:
		0: obj[property].x = value
		1: obj[property].y = value
		2: obj[property].z = value
		3: obj[property].w = value

func get_object_index_value(obj: Object, property: String, index: int) -> Variant:
	if obj is ShaderMaterial: return obj.get_shader_parameter(property)[index];
	return obj.get(property)[index]

func get_object_value(obj: Object, property: String) -> Variant:
	if obj is ShaderMaterial: return obj.get_shader_parameter(property);
	return obj.get(property)
#endregion

#region Song
func bpm_changes() -> void:
	#bpm.text = str(Conductor.bpm)
	#bpm.placeholder_text = bpm.text
	pass

func selected_json(file: String = ''):
	if !file: return
	
	if grids:
		confirm_dialog.visible = true
		confirm_dialog.confirmed.connect(func():
			_load_song_from_json(file); dialog_bg.visible = false,ConnectFlags.CONNECT_ONE_SHOT
		)
		return
	show_dialog(false)
	confirm_dialog.visible = false
	_load_song_from_json(file)

func load_json() -> void:
	show_dialog()
	dialog.add_filter('*.json')
	connect_to_dialog(selected_json)

func _load_song_from_json(dir_absolute: String):
	Conductor.clearSong(true)
	playState.SONG.clear()
	set_song_editor_position(0.0)
	
	Paths.curMod = Paths.getModFolder(dir_absolute)
	removeAllGrids()
	playState.clear()
	playState._reset_values()
	FunkinGD._clear_scripts(true)
	
	playState.loadSong(dir_absolute)
	playState.loadSongObjects()
	
	if playState.process_mode != ProcessMode.PROCESS_MODE_DISABLED: playState.startSong()
	
	_update_song_info()

func _update_song_info():
	if playState.Song.songName: 
		if Paths.curMod: DiscordRPC.details = 'Editing Modchart of: '+playState.Song.songName+' of the '+Paths.curMod+" mod"
		else: DiscordRPC.details = 'Editing Modchart of: '+playState.Song.songName
	else: DiscordRPC.details = 'Editing Modchart'
	DiscordRPC.refresh()
	
	timeline.steps = Conductor.get_step_count()
#endregion

#region Shader Area
func _on_select_shader_media_pressed() -> void: 
	show_dialog(); 
	connect_to_dialog(addMediaShader)
	dialog.add_filter('*.frag')
	dialog.add_filter('*.gdshader')

func addMediaShader(path: String):
	var shader = EditorMaterial.new()
	shader.loadShader(path)
	if !shader.shader: return
	Media.add_shader(shader)

func addShader(shader_media: MediaData):
	if !shader_media.media: return
	if !shader_media.media.objects:
		Global.show_label_error("Insert the objects in Property Menu before add the shader.")
		return
	var shader = shader_media.shader
	for i in shader.objecs:
		var obj = FunkinGD._find_object(i)
		if !obj: Global.show_label_error("Can't add shader to "+i+", object don't found."); continue
		if obj is CameraCanvas: obj.addFilters(shader); continue
		
		if obj is CanvasItem:
			if obj.material: Global.show_label_error("Can't add shader to "+i+", object already as a material."); continue
			obj.material = shader
	addFileToEditor(shader_media.name,shader)
#endregion

#region Modchart Area
func _process(delta: float) -> void:
	if playState.process_mode != playState.PROCESS_MODE_DISABLED: 
		set_song_editor_position(Conductor.songPosition)
		_check_properties_update(delta)
	_explorer_obj_selected_color(delta)

func save_modchart(path_absolute: String): Paths.saveFile(ModchartState.get_keys_data(),path_absolute)
#endregion

#region Song Position
func set_song_editor_position(new_pos: float) -> void:
	if new_pos == songPosition: return
	
	if Conductor.step_float < 0: 
		grid_x = -26
	else: 
		grid_x = maxf(0,Conductor.step_float - 15)
	
	grid_real_x = grid_x*grid_size.x
	position_line.position.x = grid_size.x*Conductor.step_float
	grid_scroll.position.x = -grid_real_x
	timeline.position.x = -grid_real_x
	
	var is_processing_back: bool = new_pos < songPosition
	songPosition = new_pos
	
	if is_processing_back: playState.updateRespawnNotes()
	ModchartState.process_keys(is_processing_back)
	
	for i in grids:
		var grid = grids[i]
		updateGridX(grid)
		updateGridKeys(grid,is_processing_back)
	updateKeysPositions()
func set_song_position(pos: float):
	if pos == songPosition: return
	Conductor.setSongPosition(pos)
	playState.updateNotes()
	set_song_editor_position(pos)

func set_song_position_from_line() -> void:
	set_song_position(Conductor.get_step_time(position_line.position.x/GRID_SIZE.x))
#endregion

#region Grid Methods
func createGrid(object: Variant) -> Grid:
	var grid: Grid = Grid.new()
	if object is Object: grid.object = object
	grid.material = grid_material.duplicate()
	grid.size = Vector2(ScreenUtils.screenWidth,10)
	
	grid_scroll.add_child(grid)
	grid.gui_input.connect(grid_input.bind(grid))
	return grid

func updateGridKeys(grid: Grid, from_back: bool = false) -> void:
	if from_back: grid.process_keys_behind()
	else: grid.process_keys_front()

func updateGridX(grid: Grid) -> void:
	grid.material.set_shader_parameter('x',grid_x)
	grid.position.x = grid_real_x

func updateGridY(grid: Grid) -> void: grid.position.y = grid.dropdownBox.position.y + 24.0

func set_grid_zoom(new_zoom: float):
	grid_size = Vector2(GRID_SIZE.x*new_zoom,GRID_SIZE.y)
	for i in grids:
		var grid = grids[i]
		grid.material.set_shader_parameter('grid_size',grid_size)
		for key in grid._keys_created: key.updatePos()
	timeline.queue_redraw()

func updateAllGrids(update_size: bool = false) -> void: 
	for i in grids:
		var grid = grids[i]
		updateGridY(grid)
		if update_size: grid.updateSize()

func removeAllGrids() -> void:
	ModchartState.clear()
	for i in grids:
		var grid = grids[i]
		grid.dropdownBox.queue_free()
		grid.queue_free()
	grids.clear()
	keys_selected.clear()

func removeGrid(grid: Grid) -> void:
	if !grid: return
	
	for i in grid.keys.values(): for k in i: keys_selected.erase(k.key_node)
	
	var obj = getGridObject(grid)
	
	if obj is EditorMaterial:
		for i in obj.objects:
			var node = FunkinGD._find_object(i)
			if !node: continue
			if node is CameraCanvas: node.removeFilter(obj)
			else: node.material = null
	elif obj:
		#Return value to default
		var grid_keys = grid.properties
		for i in grid_keys: obj.set(i,grid_keys[i].default)
	
	ModchartState.removeObject(grid.object_name)
	grids.erase(grid.object_name)
	grid.dropdownBox.queue_free()
	grid.queue_free()

func addFileToEditor(object_name: String, object: Object) -> void:
	#Check if the name already exists.
	var grid_data = grids.get(object_name)
	if grid_data: Global.show_label_error('Object "'+object_name+'" alredy exists!'); return
	
	var is_material = object is EditorMaterial
	
	var grid = createGrid(object_name)
	grid.object = object
	grid.object_name = object_name
	
	var modchart_data = {'keys': grid.keys}
	var icon_texture: Texture
	
	if is_material:
		if !object.uniforms: Global.show_label_error("Error on Loading Shader: Shader don't have uniforms."); return
		
		modchart_data.shader_name = object.shader_name
		modchart_data.objects = object.objects
		
		icon_texture = load("res://icons/Shader.svg")
		
	else: icon_texture = load("res://icons/Object.svg")
	
	var icon = Sprite2D.new()
	icon.texture = icon_texture
	icon.position = Vector2(20,8)
	
	ModchartState.keys[object_name] = modchart_data
	ModchartState.keys_index[object_name] = {}
	
	var dropdownBox = DropdownBox.new()
	dropdownBox.add_child(icon)
	dropdownBox.name = object_name
	dropdownBox.button_pressed = true
	dropdownBox.toggled.connect(show_grid.bind(grid))
	dropdownBox.text_name = '  '+object_name
	dropdownBox.text_label.gui_input.connect(dropdown_box_input.bind(grid))
	
	grid.dropdownBox = dropdownBox
	
	grid_property.add_child(dropdownBox)
	grids[object_name] = grid
	
	updateGridX(grid)
	grid.updateSize()
	call_deferred('call_deferred','updateAllGrids')

func show_grid(show: bool, grid: Grid):
	grid.visible = show
	call_deferred('call_deferred','updateAllGrids')
	
func addPropertyToGrid(grid: Grid, prop: String):
	var obj = getGridObject(grid)
	if !obj: return
	var value = getObjectProperty(obj,prop)
	if value == null:
		Global.show_label_error('Cannot add "'+prop+'" property: missing or undefined type.',1.0,600)
		return
		
	if not typeof(value) in MathUtils.math_types:
		Global.show_label_error('Cannot add "'+prop+'" property: property is not a numeric type.',1.0,600)
		return
	
	grid.createProperty(prop)
	grid.dropdownBox.texts.append(prop)
	grid.dropdownBox.update_texts()
	ModchartState.addPropertyIndex(grid.object_name,prop)
	grid.updateSize()

func removeGridProperty(grid: Grid, prop: String):
	var obj = getGridObject(grid)
	var prop_keys = grid.keys[prop]
	if prop_keys:
		ModchartState.setObjectValue(obj,prop,prop_keys[0].prev_val)
		for i in prop_keys: keys_selected.erase(i); i.key_node.queue_free()
	
	grid.keys.erase(prop)
	grid.keys_index.erase(prop)
	grid.properties.erase(prop)
	grid.dropdownBox.texts.erase(prop)
	grid.dropdownBox.update_texts()
	ModchartState.keys_index[grid.object_name].erase(prop)
	grid.updateSize()
#endregion

#region Key Setters
func updateKeysPositions(): for i in grids: for key in grids[i]._keys_created: key.updatePos()

func toggle_key(key: KeyInterpolatorNode, add: bool = is_shift_pressed):
	if key in keys_selected: unselect_key(key)
	else: select_key(key,add)

func select_key(key: KeyInterpolatorNode,add: bool = is_shift_pressed):
	if !add: unselect_keys()
	key.modulate = Color.CYAN
	keys_selected.append(key)

func select_keys(keys: Array[KeyInterpolatorNode], add: bool = is_shift_pressed):
	if !add:
		unselect_keys()
		keys_selected.assign(keys)
	else: for i in keys: keys_selected.append(i)
	
	for i in keys: i.modulate = Color.CYAN

func unselect_key(key: KeyInterpolatorNode):
	key.modulate = Color.WHITE
	keys_selected.erase(key)

func unselect_keys():
	for i in keys_selected: i.modulate = Color.WHITE
	keys_selected.clear()

func removeKey(key: KeyInterpolatorNode):
	key.data.time = INF
	ModchartState.update_key(key.data)
	key.parent.removeKey(key)
	
func removeKeysSelected():
	for i in keys_selected: removeKey(i)
	keys_selected.clear()

func add_keys_step(step: float):
	for i in keys_selected: 
		i.step += step
		i.data.time = Conductor.get_step_time(i.step)
		i.updatePos()
	ModchartState.process_keys(step > 0.0)

func add_keys_duration(value: float):
	var has_duration: bool = false
	for i in keys_selected: 
		i.data.duration += value
		if !has_duration: has_duration = !!i.data.duration
	
func set_keys_value(value: float): for i in keys_selected: 
		var key_array = get_keys_grid_from_key(i)
		var key_index = key_array.find(i.data)
		var prev_key: KeyInterpolator
		if key_index < key_array.size()-1:
			prev_key = key_array[key_index+1]
			prev_key.prev_val = value
			if prev_key.init_val == i.data.init_val: prev_key.init_val = value
		
		i.data.value = value
		if key_can_process(i.data): ModchartState.update_key(i.data)

func set_keys_value_index(index: String,value: float):
	match index:
		'x': for i in keys_selected: i.data.value.x = value
		'y': for i in keys_selected: i.data.value.y = value
		'z': for i in keys_selected: i.data.value.z = value
		'w': for i in keys_selected: i.data.value.w = value
	
	for i in keys_selected: if key_can_process(i.data): i.data._process()
	
func set_keys_init_value(value: float):
	for i in keys_selected: 
		i.data.init_val = value
		if i.data.tween_started: i.data._process()

func set_keys_init_value_index(index: String,value: float):
	match index:
		'x': for i in keys_selected: i.data.init_val.x = value
		'y': for i in keys_selected: i.data.init_val.y = value
		'z': for i in keys_selected: i.data.init_val.z = value
		'w': for i in keys_selected: i.data.init_val.w = value

func key_can_process(key: KeyInterpolator):
	var prev = get_prev_key(key)
	return Conductor.songPosition >= key.time and (!prev or prev.time >= Conductor.songPosition)
	
func get_prev_key(key: KeyInterpolator) -> KeyInterpolator:
	var grid_array = get_keys_grid_from_key(key.key_node)
	var index = grid_array.find(key)
	return grid_array[index+1] if index < grid_array.size()-1 else null

func get_keys_grid_from_key(key: KeyInterpolatorNode) -> Array: return key.parent.keys[key.data.property]

func detect_key_index(key: KeyInterpolatorNode) -> int: return get_keys_grid_from_key(key).find(key.data)

func disable_moving_keys(): is_moving_keys = false

func copy_keys_selected() -> void:
	keys_copied.clear()
	for i in keys_selected: keys_copied.append(i.data)

func paste_keys(round_step: bool = !is_shift_pressed):
	if !keys_copied: return
	var time_add: float = Conductor.step_float - keys_copied[0].key_node.step
	if round_step: time_add = roundf(time_add)
	var keys_created: Array[KeyInterpolatorNode]
	var last_key: KeyInterpolator
	
	var max_time: float = songPosition
	for i in keys_copied:
		var grid = i.key_node.parent
		var time = i.key_node.step + time_add
		var index = grid.addKey(
			time,
			i.property,
			i.value,
			i.duration,
			i.transition,
			i.ease
		)
		max_time = maxf(max_time,time+i.duration)
		last_key = grid.keys[i.property][index]
		last_key.init_val = i.init_val
		keys_created.append(last_key.key_node)
	
	select_keys(keys_created,false)
	set_song_editor_position(max_time)
#endregion

#region Inputs
func getMouseXStep(mouse_pos: float, rounded: bool = !is_shift_pressed):
	mouse_pos /= grid_size.x
	return roundf(mouse_pos) if !rounded else mouse_pos

func dropdown_box_input(event: InputEvent, grid: Grid):
	if event is InputEventMouseButton:
		if !event.pressed: return
		match event.button_index:
			2:
				grid_selected = grid

func grid_input(event: InputEvent, grid: Grid):
	if not event is InputEventMouseButton: return
	match event.button_index:
		1:
			if event.pressed or is_moving_keys: return
			if !Conductor.songs:
				Global.show_label_error('Insert a Song First!')
				return
			
			if !Conductor.bpm:
				Global.show_label_error("Insert a Bpm First!")
				return
			
			var mouse_pos = event.position
			
			var grid_properties = grid.keys.keys()
			var property = grid_properties[mini(grid.keys.size()-1,int(mouse_pos.y/24.0))]
			
			var default_value: Variant = grid.properties[property].default
			
			var step = getMouseXStep(mouse_pos.x+grid.position.x)
			
			var time: float = Conductor.get_step_time(step)
			
			for i in grid._keys_created:
				var k = i.data
				
				if k.property == property and (k.time - 1.2 + maxf(k.duration,1.2) >= time):
					toggle_key(i,is_shift_pressed)
					return
			
			var index = grid.addKey(
				step,
				property,
				default_value,
				0,
				Tween.TRANS_LINEAR,
				Tween.EASE_OUT
			)
			
			var key = grid.keys[property][index].key_node
			key.updatePos()
			key.gui_input.connect(key_input.bind(key))
			select_key(key,false)

func grid_options_menu_pressed(index: int):
	match index:
		1: removeGrid(grid_selected)

func key_input(event: InputEvent,key: KeyInterpolatorNode):
	if event is InputEventMouseButton:
		match event.button_index:
			1:
				if event.pressed: 
					is_key_mouse_pressed = true
					key_moving_first_pos = getMouseXStep(get_viewport().get_mouse_position().x)
					return
				
				if !is_moving_keys: 
					toggle_key(key)
					is_key_mouse_pressed = false
			2: 
				key_options.show()
				key_options.position = get_viewport().get_mouse_position()

func key_options_menu_pressed(index: int):
	match index: 
		0: removeKeysSelected()

func timeline_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			var index = event.button_index
			match index:
				4,5: 
					var pos = position_line.position.x
					var size = grid_size.x
					if index == 5: size = -size
					if is_shift_pressed: pos += size*2
					else: pos += size
					var step = floorf(pos/grid_size.x)
					step = maxf(-24,step)
					position_line.position.x = step*grid_size.x
					set_song_position_from_line()
					
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if !event.pressed: return
		match event.keycode:
			KEY_SPACE,KEY_ENTER: pausePlaystate(playState.process_mode != PROCESS_MODE_DISABLED)
			KEY_C: if Input.is_key_pressed(KEY_CTRL): copy_keys_selected()
			KEY_V: if Input.is_key_pressed(KEY_CTRL): paste_keys()
			KEY_LEFT: add_keys_step(-2.0 if is_shift_pressed else -1.0)
			KEY_RIGHT: add_keys_step(2.0 if is_shift_pressed else 1.0)
			KEY_DELETE: removeKeysSelected()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and !event.pressed:
			is_key_mouse_pressed = false
			is_moving_line = false
			disable_moving_keys.call_deferred()
	elif event is InputEventKey: 
		if event.keycode == KEY_SHIFT: is_shift_pressed = event.pressed
	elif event is InputEventMouseMotion:
		if !is_key_mouse_pressed: return
		var mouse_pos = getMouseXStep(event.position.x)
		var pos_sub = (mouse_pos - key_moving_first_pos)
		
		if pos_sub >= 1.0 or pos_sub <= -1.0: is_moving_keys = true
		if is_moving_keys and pos_sub:
			add_keys_step(pos_sub)
			key_moving_first_pos = mouse_pos
#endregion

#region Data
func getGridObject(grid: Variant) -> Object:
	var obj = grid.object
	if !obj: obj = FunkinGD._find_object(grid.object_name)
	return obj

func getGridObjectProperties(grid: Variant) -> Variant:
	var obj = getGridObject(grid)
	if !obj: return
	if obj is EditorMaterial: return obj.uniforms
	return PropertiesAvaliable.get(obj.get_script(),[])
	
func getObjectProperty(object: Variant, prop: String):
	return object.get_shader_parameter(prop) if object is ShaderMaterial else object.get(prop)
#endregion

#region PlayState
func pausePlaystate(pause: bool) -> void:
	playState.canHitNotes = !pause
	if pause: playState.pauseSong()
	else: playState.resumeSong()

func _set_playstate_value(value: Variant, property: String): playState.set(property,value)
#endregion

#region Signals
func _on_modchart_options_index_selected(index: int):
	match index:
		0:
			show_dialog(true,FileDialog.FILE_MODE_SAVE_FILE)
			connect_to_dialog(save_modchart)
		1: show_dialog(true,FileDialog.FILE_MODE_SAVE_FILE)
			#connect_to_dialog(load_modchart)

func _on_song_options_index_selected(index: int):
	match index:
		0: load_json()
#endregion

class PropertySeparator extends VBoxContainer:
	var button: Button = Button.new()
	var properties_to_hide: Array = []
	var class_text: String = ''
	func _init() -> void:
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set("theme_override_constants/icon_max_width",23)
	
	func _ready() -> void:
		button.toggle_mode = true
		button.button_pressed = true
		add_child(button)
		button.focus_mode = Control.FOCUS_NONE
		button.toggled.connect(func(_t): for i in properties_to_hide: i.visible = _t; update_text())
		update_text()
	
	func update_text(): button.text = class_text+(' v' if button.button_pressed else ' >')
	
class KeyValue extends TextureButton:
	func _init() -> void:
		texture_normal = KeyNormalTexture
		texture_pressed = KeySelectedTexture
		toggle_mode = true
	func _draw() -> void:
		draw_string(ThemeDB.fallback_font,Vector2(-15,16),'<   >')
