extends Node

const GRID_SIZE = Vector2(40,24)

const EditorMaterial = preload("res://source/states/Modchart/Shaders/EditorShader.gd")

const StrumNote = preload("res://source/objects/Notes/StrumNote.gd")
const Sprite = preload("res://source/objects/Sprite/Sprite.gd")
const Character = preload("res://source/objects/Sprite/Character.gd")
const CameraCanvas = preload("res://source/objects/Display/Camera.gd")
const SpriteGroup = preload("res://source/general/groups/SpriteGroup.gd")
const PlayState = preload("res://source/states/PlayState.gd")

const KeyInterpolator = preload("res://source/states/Modchart/Keys/KeyInterpolator.gd")
const KeyInterpolatorNode = preload("res://source/states/Modchart/Editor/KeyInterpolatorNode.gd")

const ButtonRange = preload("res://scenes/objects/ButtonRange.gd")
const ButtonRangeScene = preload("res://scenes/objects/ButtonRange.tscn")
const ModchartState = preload("res://source/states/Modchart/ModchartState.gd")
const Grid = preload("res://source/states/Modchart/Editor/Grid.gd")

var PropertiesAvaliable: Dictionary = {
	PlayState: {
		'defaultCamZoom': {'range': [-5,5]},
		'cameraSpeed': {'range': [0.2,10]},
		'scrollSpeed':  {'range': [0.2,10]}
	},
	CameraCanvas:{
		'scrollOffset': null,
		'angle': {'range': [-360,360]}
	},
	Sprite:{
		'scale': {'type': TYPE_FLOAT,'range': [-12,12]},
		'x': null,
		'y': null,
	},
	StrumNote:{'direction': {'range': [-360,360]}}
}
#var PropertiesAvaliable: Dictionary[Script,Dictionary] = {}

var modchart_keys = ModchartState.keys
var modchart_upating = ModchartState.keys_index


var songPosition: float = 0.0: set = set_song_editor_position
var grids: Dictionary[String,Grid] = {}

#Song Data
#region Tween Variables
@onready var duration: ButtonRange = $"VSplit/HSplit/HSplit/Property/Key/Duration"

@onready var transition_menu: MenuButton = $"VSplit/HSplit/HSplit/Property/Key/Transition/Options"
var cur_transition: Tween.TransitionType
@onready var transition_popup = transition_menu.get_popup()

@onready var ease_menu: MenuButton = $"VSplit/HSplit/HSplit/Property/Key/Ease/Options"
var cur_ease: Tween.EaseType
@onready var ease_popup: PopupMenu = ease_menu.get_popup()
#endregion

#region Nodes
@onready var dialog_bg = $BG
@onready var dialog: FileDialog = $FileDialog
@onready var confirm_dialog: ConfirmationDialog = $ConfirmationDialog
@onready var playState = $SubViewport/PlayState

@onready var key_options = $KeyOptions
@onready var object_options = $VSplit/HSplitP/Panel/HBox/Object/Name


@onready var property_options = $PropertyOptions
@onready var properties_names = $PropertyOptions/Properties
@onready var property_remove = $PropertyOptions/PropertyRemove

#region Timeline
@onready var position_line = $VSplit/HSplitP/HTimeline/Timeline/Time/PositionLine
@onready var timeline_panel = $VSplit/HSplitP/HTimeline/Timeline
@onready var timeline = $VSplit/HSplitP/HTimeline/Timeline/Time
#endregion

#region Property Editor Variables
@onready var explorer_nodes = $VSplit/HSplit/PanelContainer/Explorator/ColorRect/Explorer
var properties_created: Array[Dictionary]
@onready var properties_tab = $VSplit/HSplit/HSplit/Property/Properties/Scroll/Container
@onready var properties_select_obj_text = $VSplit/HSplit/HSplit/Property/Properties/InfoText

#endregion

#region Grid Properties
const grid_shader = preload("res://source/states/Modchart/Shaders/Grid.gdshader")
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

#region Shader Area
@onready var shader_tab: Panel = $ShaderTab
@onready var shader_menu: MenuButton = $ShaderTab/Shaders
@onready var shader_tag: LineEdit = $ShaderTab/Tag
@onready var shader_menu_popup: PopupMenu = shader_menu.get_popup()
@onready var shader_objects: LineEdit = $ShaderTab/Objects
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
#endregion

#region Different values
var is_type_different: bool = false
var is_duration_different: bool = false
var is_transition_different: bool = false
var is_ease_different: bool = false
#endregion

#region Explorer
var explorer_object_selected: Node
var explorer_object_last_modulate: Color
var explorer_select_effect: bool = false
var explorer_modulate_delta: float = 0.0
func _on_explorer_button_selected(button) -> void:
	if explorer_object_selected: explorer_object_selected.modulate = explorer_object_last_modulate
	var obj = button.object
	explorer_select_effect = obj is CanvasItem
	
	if explorer_select_effect: explorer_object_last_modulate = obj.modulate
	else: explorer_modulate_delta = 0.0
	explorer_object_selected = obj
	show_object_properties(obj)
#endregion

func _ready() -> void:
	DiscordRPC.state = 'In Modchart Editor'
	DiscordRPC.refresh()
	
	grid_material.shader = grid_shader
	grid_material.set_shader_parameter('grid_size',GRID_SIZE)
	dialog.current_dir = Paths.exePath+'/'
	dialog.canceled.connect(dialog_bg.hide)
	
	#region Shaders
	updateShadersPopup()
	
	shader_menu_popup.index_pressed.connect(func(i):
		var shader = shader_menu_popup.get_item_text(i)
		shader_menu.text = shader
		shader_tag.placeholder_text = shader.get_file().get_basename()
	)
	
	dialog.file_selected.connect(func(_f): show_dialog(false))
	#endregion
	
	#region Transition
	for i in TweenService.transitions: transition_popup.add_item(StringHelper.first_letter_upper(i))
	
	transition_menu.text = transition_popup.get_item_text(0)
	
	transition_popup.index_pressed.connect(func(i):
		var trans = transition_popup.get_item_text(i)
		transition_menu.text = trans
		cur_transition = TweenService.detect_trans(trans)
		set_keys_transition(cur_transition)
	)
	#endregion
	
	#region Ease
	ease_popup.index_pressed.connect(func(i):
		var ease = ease_popup.get_item_text(i)
		ease_menu.text = ease
		cur_ease = TweenService.detect_ease(ease)
		set_keys_ease(cur_ease)
	)
	#endregion
	
	#region Position Line
	#endregion
	
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

func disconnect_to_dialog(callable: Callable) -> void: 
	dialog.file_selected.disconnect(callable)
#endregion

#region Properties

func show_object_properties(object: Object):
	if object is ShaderMaterial: return
	
	for i in properties_tab.get_children(): i.queue_free()
	var script: Script = object.get_script()
	
	var properties: Dictionary = {}
	if script:
		while script:
			var props = PropertiesAvaliable.get(script)
			if props: 
				var _class_n = script.resource_path.get_basename().get_file()
				properties[_class_n] = [props,explorer_nodes._get_class_icon(_class_n)]
			script = script.get_base_script()

	var base_class_props = PropertiesAvaliable.get(ClassDB.instantiate(object.get_class()))
	#if base_class_props: properties.append_array(base_class_props)
	
	if !properties: properties_select_obj_text.visible = true; return
	properties_select_obj_text.visible = false
	
	for i in properties:
		var data = properties[i]
		var separator = _create_property_separator(i,data[1])
		
		var _props = data[0]
		for p in _props: 
			var property = _create_property_buttons(object,p,_props[p])
			if property: separator.properties_to_hide.append_array(property)

func _create_property_separator(text: String, icon: Texture):
	var separator = PropertySeparator.new()
	separator.class_text = text
	separator.button.icon = icon
	properties_tab.add_child(separator)
	return separator
		
func _create_property_buttons(object: Node, property: String, data = null) -> Array[Node]:
	var value = object.get(property)
	var type = typeof(value)
	var nodes: Array[Node] = []
	
	match type:
		TYPE_FLOAT,TYPE_INT:
			var int_val = type == TYPE_INT
			var range = data.get('range') if data else null
			var button
			if range:
				button = HSlider.new()
				button.min_value = range[0]
				button.max_value = range[1]
				if range.size() >= 3: button.step = range[2]
				elif not int_val: button.step = 0.1
			else:
				button = _create_property_button()
				button.text = property+': '
				button.value = value
				if int_val: button.int_value = true
				else: button.value_to_add = 0.1
			button.value_changed.connect(func(_v): object[property] = _v)
			nodes.append(button)
		
		TYPE_VECTOR2,TYPE_VECTOR3,TYPE_VECTOR4,TYPE_VECTOR2I,TYPE_VECTOR3I,TYPE_VECTOR4I:
			var int_val = (type == TYPE_VECTOR2I or type == TYPE_VECTOR3I or type == TYPE_VECTOR4I)
			var length = VectorUtils.get_vector_length_from_type(type)
			var vector_index = VectorUtils.vectors_index[length-1]
			for i in vector_index:
				var button = _create_property_button()
				button.text = property+' '+i+': '
				button.int_value = int_val
				if not int_val: button.value_to_add = 0.1
					
				button.value = value[i]
				match i:
					'x': button.value_changed.connect(func(_v): object[property].x = _v)
					'y': button.value_changed.connect(func(_v): object[property].y = _v)
					'z': button.value_changed.connect(func(_v): object[property].z = _v)
					'w': button.value_changed.connect(func(_v): object[property].w = _v)
				nodes.append(button)
	if !nodes: return []
	for i in nodes: 
		properties_tab.add_child(i)
		_create_interpolator_key_to_button(i)
	return nodes

func _create_property_button():
	var button: ButtonRange = ButtonRangeScene.instantiate()
	button.update_min_size_x = true
	button.update_min_size_y = true
	return button

func _create_interpolator_key_to_button(button: Control) -> void:
	var key = KeyValue.new()
	button.minimum_size_changed.connect(_update_interpolator_key_pos.bind(key).call_deferred)
	button.add_child(key)
	_update_interpolator_key_pos.call_deferred(key)

func _update_interpolator_key_pos(key: Control):
	key.position = Vector2(key.get_parent().size.x + 15,key.get_parent().size.y/2.0 - 8)
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
	updateShadersPopup()
	removeAllGrids()
	playState.clear()
	playState._reset_values()
	FunkinGD._clear_scripts(true)
	
	playState.loadSong(dir_absolute)
	playState.loadSongObjects()
	
	if playState.process_mode != ProcessMode.PROCESS_MODE_DISABLED: playState.startSong()
	
	if playState.Song.songName: 
		if Paths.curMod: DiscordRPC.details = 'Editing Modchart of: '+playState.Song.songName+' of the '+Paths.curMod+" mod"
		else: DiscordRPC.details = 'Editing Modchart of: '+playState.Song.songName
	else: DiscordRPC.details = 'Editing Modchart'
	DiscordRPC.refresh()
	
	timeline.steps = Conductor.get_step_count()
#endregion

#region Shader Area
func _on_select_shader_pressed() -> void: show_dialog(); connect_to_dialog(selected_shader)

func selected_shader(file: String = ''):
	disconnect_to_dialog(selected_shader)
	shader_menu.text = file.get_file().get_basename()
	
func addShader(tag: String = shader_tag.text, file: String = shader_menu.text, objects: PackedStringArray = []):
	var shader = EditorMaterial.new()
	shader.loadShader(file)
	
	if !shader.shader: return
	if !tag: tag = shader_tag.placeholder_text
	
	if !objects:
		if shader_objects.text: objects = StringHelper.split_no_space(shader_objects.text,',')
		else: objects = StringHelper.split_no_space(shader_objects.placeholder_text,',')
	
	shader.shader_name = file.get_base_dir().get_basename()
	shader.objects = objects
	
	for i in objects:
		var obj = FunkinGD._find_object(i)
		if !obj: Global.show_label_error("Can't add shader to "+i+", object don't found."); continue
		if obj is CameraCanvas: obj.addFilters(shader); continue
		
		if obj is CanvasItem:
			if obj.material: Global.show_label_error("Can't add shader to "+i+", object already as a material."); continue
			obj.material = shader
	addFileToEditor(tag,shader)

func updateShadersPopup() -> void:
	shader_menu_popup.clear()
	var cur_mod: String = Paths.game_name
	for i in Paths.getFilesAt('shaders',true,['gdshader','frag'],true):
		var mod_folder = Paths.getModFolder(i)
		if cur_mod != mod_folder:
			shader_menu_popup.add_separator(mod_folder)
			cur_mod = mod_folder
		shader_menu_popup.add_item(i.get_file())
#endregion

#region Modchart Area
func _process(delta: float) -> void:
	if playState.process_mode != playState.PROCESS_MODE_DISABLED: set_song_editor_position(Conductor.songPosition)
	
	if explorer_select_effect and explorer_object_selected:
		explorer_modulate_delta += delta
		explorer_object_selected.modulate = Color.WHITE.lerp(
			Color.CYAN,
			abs(sin(explorer_modulate_delta*3.0))
		)

func save_modchart(path_absolute: String):
	Paths.saveFile(ModchartState.get_keys_data(),path_absolute)

#endregion

#region Song Position
func set_song_editor_position(new_pos: float) -> void:
	if new_pos == songPosition: return
	
	if Conductor.step_float < 0: grid_x = -24
	else: grid_x = maxf(0,Conductor.step_float - 15)
	
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

#region Grid
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

func updateGridY(grid: Grid) -> void:
	grid.position.y = grid.dropdownBox.position.y + 24.0

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
	if not typeof(value) in MathHelper.math_types:
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
func updateKeysPositions():
	for i in grids: for key in grids[i]._keys_created: key.updatePos()

#region Key Setters
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
	
	if is_duration_different: duration.text = '...'

func set_keys_transition(trans: Tween.TransitionType):
	for i in keys_selected: i.data.transition = trans

func set_keys_ease(ease: Tween.EaseType):
	for i in keys_selected: i.data.ease = ease

func set_keys_value(value: float):
	for i in keys_selected: 
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


func getMouseXStep(mouse_pos: float, rounded: bool = !is_shift_pressed):
	mouse_pos /= grid_size.x
	return roundf(mouse_pos) if !rounded else mouse_pos

#region Inputs
func dropdown_box_input(event: InputEvent, grid: Grid):
	if event is InputEventMouseButton:
		if !event.pressed: return
		match event.button_index:
			2: 
				var properties = getGridObjectProperties(grid)
				if !properties:
					Global.show_label_error("Error on Properties: Object don't exists or don't have any property.")
					return
				property_options.visible = true
				property_options.position = get_viewport().get_mouse_position()
				properties_names.clear()
				property_remove.clear()
				for i in properties: if not i in grid.keys: properties_names.add_item(i)
				
				if !grid.keys: property_options.set_item_disabled(1,true)
				else: 
					for i in grid.keys: property_remove.add_item(i); 
					property_options.set_item_disabled(1,false)
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
				cur_transition,
				cur_ease
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
			KEY_SPACE,KEY_ENTER: pausePlaystate(Conductor.is_playing)
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
	if pause:
		Conductor.pauseSongs()
		playState.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		Conductor.resumeSongs()
		playState.process_mode = Node.PROCESS_MODE_INHERIT

func _set_playstate_value(value: Variant, property: String): playState.set(property,value)
#endregion

#region Signals
func object_submitted(obj_name: String):
	object_options.release_focus()
	object_options.visible = false
	obj_name = obj_name.strip_edges()
	if !obj_name: return
	addFileToEditor(obj_name,null)

func _on_property_index_selected(index: int): addPropertyToGrid(grid_selected,properties_names.get_item_text(index))

func _on_property_remove_index_selected(index: int): removeGridProperty(grid_selected,property_remove.get_item_text(index))

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
