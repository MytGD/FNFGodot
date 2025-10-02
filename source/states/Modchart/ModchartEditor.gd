extends Node

const GRID_SIZE = Vector2(40,24)

const KeyInterpolator = preload("res://source/states/Modchart/KeyInterpolator.gd")
const KeyInterpolatorNode = preload("res://source/states/Modchart/KeyInterpolatorNode.gd")

const ButtonRange = preload("res://scenes/objects/ButtonRange.gd")
const ModchartState = preload("res://source/states/Modchart/ModchartState.gd")
const Grid = preload("res://source/states/Modchart/Grid.gd")

var modchart_keys = ModchartState.keys
var modchart_upating = ModchartState.keys_updating

@onready var dialog_bg = $BG
@onready var dialog: FileDialog = $FileDialog
@onready var confirm_dialog: ConfirmationDialog = $ConfirmationDialog
@onready var playState = $SubViewport/PlayState

var songPosition: float = 0.0: set = set_song_editor_position
var properties: Dictionary = {}

#Song Data
@onready var bpm: LineEdit = $"VSplit/HSplit/PanelContainer/Song Data/Bpm"

#Property Area
@onready var duration: ButtonRange = $VSplit/HSplit/HSplit/Property/List/Duration

@onready var transition_menu: MenuButton = $VSplit/HSplit/HSplit/Property/List/Transition/Options
var cur_transition: Tween.TransitionType
@onready var transition_popup = transition_menu.get_popup()

@onready var ease_menu: MenuButton = $VSplit/HSplit/HSplit/Property/List/Ease/Options
var cur_ease: Tween.EaseType
@onready var ease_popup: PopupMenu = ease_menu.get_popup()

@onready var property_name = $PropertyName

@onready var property_value = $VSplit/HSplit/HSplit/Property/List/Value
@onready var property_value_x = $VSplit/HSplit/HSplit/Property/List/ValueX
@onready var property_value_y = $VSplit/HSplit/HSplit/Property/List/ValueY
@onready var property_value_z = $VSplit/HSplit/HSplit/Property/List/ValueZ
@onready var property_value_w = $VSplit/HSplit/HSplit/Property/List/ValueW

@onready var property_init_value = $VSplit/HSplit/HSplit/Property/List/initVal
@onready var property_init_value_x = $VSplit/HSplit/HSplit/Property/List/initValX
@onready var property_init_value_y = $VSplit/HSplit/HSplit/Property/List/initValY
@onready var property_init_value_z = $VSplit/HSplit/HSplit/Property/List/initValZ
@onready var property_init_value_w = $VSplit/HSplit/HSplit/Property/List/initValW

@onready var property_values: Dictionary[Variant.Type,Array] = {
	TYPE_FLOAT: [property_value],
	TYPE_VECTOR2: [property_value_x,property_value_y],
	TYPE_VECTOR3: [property_value_x,property_value_y,property_value_x,property_value_z],
	TYPE_VECTOR4: [property_value_x,property_value_y,property_value_z,property_value_w],
}

@onready var property_init_values: Dictionary[Variant.Type,Array] = {
	TYPE_FLOAT: [property_init_value],
	TYPE_VECTOR2: [property_init_value_x,property_init_value_y],
	TYPE_VECTOR3: [property_init_value_x,property_init_value_y,property_init_value_x,property_init_value_z],
	TYPE_VECTOR4: [property_init_value_x,property_init_value_y,property_init_value_z,property_init_value_w],
}

#Timeline
@onready var position_line = $VSplit/HSplitP/HTimeline/Timeline/Time/PositionLine
@onready var timeline_panel = $VSplit/HSplitP/HTimeline/Timeline
@onready var timeline = $VSplit/HSplitP/HTimeline/Timeline/Time

#Grid Area
var grid_x: float = 0.0
var grid_real_x: float = 0.0

static var grid_size: Vector2 = GRID_SIZE
var grid_zoom: float = 1.0

var is_moving_line: bool = false
var last_position_line: Vector2 = Vector2.ZERO
var position_line_offset: float = 0.0

const grid_shader = preload("res://source/states/Modchart/Grid.gdshader")

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

var data_selected: Dictionary
var keys_selected: Array[KeyInterpolatorNode] = []
var is_key_mouse_pressed: bool = false
var is_moving_keys: bool = false

var key_last_mouse_pos: float = 0.0
var key_type: Variant.Type = TYPE_NIL
var key_is_int: bool = false
var keys_copied: Array[KeyInterpolator] = []

var key_moving_first_pos: float = 0
#endregion

#region Different values
var is_type_different: bool = false
var is_duration_different: bool = false
var is_transition_different: bool = false
var is_ease_different: bool = false
#endregion

@onready var key_options = $KeyOptions
@onready var object_options = $VSplit/HSplitP/Panel/HBox/Object/Name
@onready var property_options = $PropertyOptions

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
	
	dialog.file_selected.connect(func(file): show_dialog(false))
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

#region Song
func bpm_changes() -> void:
	bpm.text = str(Conductor.bpm)
	bpm.placeholder_text = bpm.text

func load_json() -> void:
	show_dialog()
	dialog.add_filter('*.json')
	connect_to_dialog(selected_json)

func selected_json(file: String = ''):
	if !file: return
	
	if properties:
		confirm_dialog.visible = true
		confirm_dialog.confirmed.connect(func():
			_load_song_from_json(file); dialog_bg.visible = false,ConnectFlags.CONNECT_ONE_SHOT
		)
		return
	show_dialog(false)
	confirm_dialog.visible = false
	_load_song_from_json(file)

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
	
	if playState.Song.songName: 
		if Paths.curMod: DiscordRPC.details = 'Editing: '+playState.Song.songName+' of the '+Paths.curMod+" mod"
		else: DiscordRPC.details = 'Editing: '+playState.Song.songName
	else: DiscordRPC.details = ''
	
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
	shader.shader = Paths.loadShaderCode(file)
	
	if !shader.shader: return
	
	if !objects:
		if shader_objects.text: objects = StringHelper.split_no_space(shader_objects.text,',')
		else: objects = StringHelper.split_no_space(shader_objects.placeholder_text,',')
		
	shader.objects = objects
	if !tag: tag = shader_tag.placeholder_text
	
	for i in objects:
		var obj = FunkinGD._find_object(i)
		if !obj: Global.show_label_error("Can't add shader to "+i+", object don't found."); continue
		if obj is CameraCanvas: obj.addFilters(shader); continue
		
		if obj is CanvasItem:
			if obj.material: Global.show_label_error("Can't add shader to "+i+", object already as a material."); continue
			obj.material = shader
	addFileToGrid(tag,shader)
	
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
	if Conductor.is_playing: set_song_editor_position(Conductor.songPosition)
	
func on_save_modchart_pressed():
	show_dialog(true,FileDialog.FILE_MODE_SAVE_FILE)
	connect_to_dialog(save_modchart)
func save_modchart(path_absolute: String):
	Paths.saveFile(ModchartState.get_keys_data(),path_absolute)
	
#endregion
#region Song Position
func set_song_editor_position(new_pos: float) -> void:
	if new_pos == songPosition: return
	
	grid_x = maxf(0,Conductor.step_float - 15)
	
	grid_real_x = grid_x*grid_size.x
	position_line.position.x = grid_size.x*Conductor.step_float
	grid_scroll.position.x = -grid_real_x
	timeline.position.x = -grid_real_x
	
	var is_processing_back: bool = new_pos < songPosition
	songPosition = new_pos
	
	if is_processing_back: 
		ModchartState.process_keys_back()
		playState.updateRespawnNotes()
	else: ModchartState.process_keys_front()
	
	
	for i in properties:
		var grid = properties[i].grid
		updateGridX(grid)
		updateGridKeys(grid,is_processing_back)
	updateKeysPositions()

func set_song_position(pos: float):
	Conductor.setSongPosition(pos)
	playState.updateNotes()
	set_song_editor_position(pos)

func set_song_position_from_line() -> void:
	set_song_position(Conductor.get_step_time(position_line.position.x/GRID_SIZE.x))
#endregion

#region Grid
func createGrid(object: Variant) -> Grid:
	var grid: Grid = Grid.new()
	grid.object = object
	grid.material = grid_material.duplicate()
	grid.size = Vector2(ScreenUtils.screenWidth,10)
	
	grid_scroll.add_child(grid)
	grid.gui_input.connect(grid_input.bind(grid))
	return grid

func updateGridKeys(grid: Grid, from_back: bool = false) -> void:
	if from_back: grid.process_keys_behind()
	else: grid.process_keys_front()

func updateGridX(grid: Grid, is_going_back: bool = false) -> void:
	grid.material.set_shader_parameter('x',grid_x)
	grid.position.x = grid_real_x

func updateGridY(grid_data: Dictionary) -> void:
	var grid = grid_data.grid
	grid.position.y = grid_data.dropdownBox.position.y + 24.0

func set_grid_zoom(new_zoom: float):
	grid_size = Vector2(GRID_SIZE.x*new_zoom,GRID_SIZE.y)
	for i in properties:
		var grid = properties[i].grid
		grid.material.set_shader_parameter('grid_size',grid_size)
		for key in grid._keys_created: key.updatePos()
	timeline.queue_redraw()

func updateAllGrids(update_size: bool = false) -> void: 
	for i in properties:
		updateGridY(properties[i])
		if update_size: properties[i].grid.updateSize()

func removeAllGrids() -> void:
	ModchartState.clear()
	for i in properties:
		properties[i].grid.queue_free()
		properties[i].dropdownBox.queue_free()
	properties.clear()
	keys_selected.clear()

func removeGrid(grid: Grid) -> void:
	for i in grid.keys.values(): for k in i: keys_selected.erase(k.key_node)
	grid.queue_free()

func addFileToGrid(object_name: String, property: Object) -> void:
	var grid_data = properties.get(object_name)
	if grid_data:
		Global.show_label_error('Object "'+object_name+'" alredy exists!')
		return
	
	var property_list: Dictionary[String,Dictionary]
	
	if property is ShaderMaterial:
		var uniform_list = property.shader.get_shader_uniform_list(true)
		if !uniform_list:
			Global.show_label_error("Error on Loading Shader: Shader don't have uniforms.")
			return
			
		for i in uniform_list:
			var type = i.type
			var default_value = property.get_shader_parameter(i.name)
			if default_value == null: default_value = MathHelper.get_new_value(type)
			property_list[i.name] = {'default': default_value,'type': type}
		
	var grid = createGrid(property) if property else createGrid(object_name)
	ModchartState.keys[object_name] = grid.keys
	
	
	var icon = Sprite2D.new()
	icon.texture = load("res://icons/basic/"+("Shader.svg" if property is ShaderMaterial else "Object.svg"))
	icon.position = Vector2(20,8)
	
	var dropdownBox = DropdownBox.new()
	dropdownBox.add_child(icon)
	dropdownBox.name = object_name
	dropdownBox.button_pressed = true
	dropdownBox.toggled.connect(
		func(toggled):
			grid.visible = toggled
			call_deferred('call_deferred','updateAllGrids')
	)
	dropdownBox.text_name = '  '+object_name
	
	grid_data = {
		'object_name': object_name,
		'object': property,
		'grid': grid,
		'dropdownBox': dropdownBox,
		'property_list': property_list
	}
	
	dropdownBox.text_label.gui_input.connect(dropdown_box_input.bind(grid_data))
	
	for i in property_list: addPropertyToGridFromData(grid_data,i)
	grid_property.add_child(dropdownBox)
	properties[object_name] = grid_data
	
	updateGridX(grid)
	grid.updateSize()
	call_deferred('call_deferred','updateAllGrids')

func addPropertyToGridFromData(data: Dictionary, prop: String):
	data.grid.createProperty(prop)
	data.dropdownBox.texts.append(prop)
	data.dropdownBox.update_texts()
	ModchartState.addProperty(data.object_name,prop)

func removeObjectFromData(data: Dictionary):
	if !data: return
	
	var obj = getObjectFromData(data)
	var grid = data.grid
	
	if obj is EditorMaterial:
		for i in obj.objects:
			var node = FunkinGD._find_object(i)
			if !node: continue
			if node is CameraCanvas: node.removeFilter(obj)
			elif node.material == obj: node.material = null
	elif obj:
		var grid_keys = grid.properties
		for i in grid_keys: obj.set(i,grid_keys[i].default)
	
	ModchartState.removeObject(data.object_name)
	
	removeGrid(grid)
	data.dropdownBox.queue_free()
	properties.erase(data.object_name)
#endregion

#region Key Interpolator
func update_key_properties():
	if !keys_selected: return
	var first_key = keys_selected[0].data
	
	duration.value_to_add = 0
	is_type_different = false
	is_duration_different = false
	is_transition_different = false
	is_ease_different = false
	
	var first_key_type = typeof(first_key.value)
	duration.value_to_add = Conductor.stepCrochet
	for i in keys_selected:
		var key = i.data
		var bpm_change = Conductor.get_bpm_changes_from_pos(key.time)
		if bpm_change: duration.value_to_add = maxf(duration.value_to_add,Conductor.get_step_crochet(bpm_change.bpm))
		if !is_type_different: is_type_different = first_key_type != typeof(key.value)
		if !is_duration_different: is_duration_different = first_key.duration != key.duration
		if !is_transition_different: is_transition_different = first_key.transition != key.transition
		if !is_ease_different: is_duration_different = first_key.ease != key.ease
	
	if !duration.value_to_add: duration.value_to_add = Conductor.stepCrochet
	hide_properties()
	hide_init_properties()
	
	
	#Show Values
	if is_type_different: 
		key_type = TYPE_NIL
		return
	
	key_type = first_key_type as Variant.Type
	
	if !is_type_different: duration.set_value_no_signal(first_key.duration)
	else: 
		duration.text = '...'
		return
	
	var properties = property_values.get(first_key_type)
	key_is_int = false
	if !properties:
		match first_key_type:
			TYPE_INT: properties = property_values[TYPE_FLOAT]; key_is_int = true; key_type = TYPE_FLOAT
			TYPE_VECTOR2I: properties = property_values[TYPE_VECTOR2]; key_is_int = true; key_type = TYPE_VECTOR2
			TYPE_VECTOR3I: properties = property_values[TYPE_VECTOR3]; key_is_int = true; key_type = TYPE_VECTOR3
			TYPE_VECTOR4I: properties = property_values[TYPE_VECTOR4]; key_is_int = true; key_type = TYPE_VECTOR4
			TYPE_COLOR: properties = property_values[TYPE_VECTOR4]; key_type = TYPE_VECTOR4
			_: return
	
	show_properties(key_type)
	set_property_values_from_key(first_key.value,properties,key_type)
	if !is_duration_different and first_key.duration: 
		show_init_properties()
		set_property_values_from_key(first_key.init_val,property_init_values[key_type],key_type)

func updateKeysPositions():
	for i in properties:
		var grid = properties[i].grid
		for key in grid._keys_created: key.updatePos()

func set_property_values_from_key(value: Variant,value_buttons: Array,value_type: Variant.Type):
	match value_type:
		TYPE_FLOAT: value_buttons[0].set_value_no_signal(value)
		TYPE_VECTOR2: 
			value_buttons[0].set_value_no_signal(value.x)
			value_buttons[1].set_value_no_signal(value.y)
		TYPE_VECTOR3:
			value_buttons[0].set_value_no_signal(value.x)
			value_buttons[1].set_value_no_signal(value.y)
			value_buttons[2].set_value_no_signal(value.z)
		TYPE_VECTOR4:
			value_buttons[0].set_value_no_signal(value.x)
			value_buttons[1].set_value_no_signal(value.y)
			value_buttons[2].set_value_no_signal(value.z)
			value_buttons[3].set_value_no_signal(value.w)

func show_init_properties():
	match key_type:
		TYPE_NIL: return
		TYPE_FLOAT,TYPE_INT:
			property_init_value.int_value = key_is_int
			property_init_value.set_value_no_signal(keys_selected[0].data.init_val)
			property_init_value.visible = true
		_:
			var index: int = 0
			for i in property_init_values[key_type]: 
				i.int_value = key_is_int
				i.set_value_no_signal(keys_selected[0].data.init_val[index])
				i.visible = true
				index += 1

func hide_init_properties():
	property_init_value.visible = false
	for i in property_init_values[TYPE_VECTOR4]: i.visible = false

func show_properties(type: Variant.Type):
	match type:
		TYPE_NIL: return
		TYPE_FLOAT,TYPE_INT: property_value.visible = true
		_: 
			var index: int = 0
			for i in property_values[type]: 
				i.visible = true
				i.int_value = key_is_int
				i.set_value_no_signal(keys_selected[0].data.value[index])
				index += 1

func hide_properties():
	property_value.visible = false
	for i in property_values[TYPE_VECTOR4]: i.visible = false

func toggle_key(key: KeyInterpolatorNode, add: bool = is_shift_pressed):
	if key in keys_selected: unselect_key(key)
	else: select_key(key,add)

func select_key(key: KeyInterpolatorNode,add: bool = is_shift_pressed):
	if !add: unselect_keys()
	key.modulate = Color.CYAN
	keys_selected.append(key)
	update_key_properties()

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

func addKeyToArray(key: KeyInterpolator, array: Array[KeyInterpolator]):
	var index: int = array.size()
	while index:
		if array[index].time <= key.time: break
		index -= 1
	array.insert(index,key)

func removeKeysSelected():
	for i in keys_selected: 
		i.data.time = INF
		ModchartState.update_key(i.data)
		i.parent.removeKey(i)
	keys_selected.clear()

#region Key Setters
func add_keys_step(step: float):
	for i in keys_selected: 
		i.step += step
		i.data.time = Conductor.get_step_time(i.step)
		i.updatePos()
		if key_can_process(i.data): i.data._process()

func add_keys_duration(value: float):
	var has_duration: bool = false
	for i in keys_selected: 
		i.data.duration += value
		if !has_duration: has_duration = !!i.data.duration
	
	if !has_duration: hide_init_properties()
	else: show_init_properties()
	
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

func disable_moving_keys(): is_moving_keys = false
#endregion

func get_keys_grid_from_key(key: KeyInterpolatorNode) -> Array: return key.parent.keys[key.data.property]

func detect_key_index(key: KeyInterpolatorNode) -> int: return get_keys_grid_from_key(key).find(key.data)

func copy_keys_selected() -> void:
	keys_copied.clear()
	for i in keys_selected:
		keys_copied.append(i.data)

func paste_keys(round_step: bool = !is_shift_pressed):
	if !keys_copied: return
	var time_add: float = Conductor.step_float - keys_copied[0].key_node.step
	if round_step: time_add = roundf(time_add)
	var keys_created: Array[KeyInterpolatorNode]
	var last_key: KeyInterpolator
	for i in keys_copied:
		var grid = i.key_node.parent
		var index = grid.addKey(
			i.key_node.step + time_add,
			i.property,
			i.value,
			i.duration,
			i.transition,
			i.ease
		)
		last_key = grid.keys[i.property][index]
		last_key.init_val = i.init_val
		keys_created.append(last_key.key_node)
	
	select_keys(keys_created,false)
	set_song_editor_position(last_key.time + last_key.duration)
#endregion

#region Input
func getMouseXStep(mouse_pos: float, rounded: bool = !is_shift_pressed):
	mouse_pos /= grid_size.x
	return roundf(mouse_pos) if !is_shift_pressed else mouse_pos
	
func dropdown_box_input(event: InputEvent, data: Dictionary):
	if event is InputEventMouseButton:
		if !event.pressed: return
		match event.button_index:
			2: 
				property_options.visible = true
				property_options.position = get_viewport().get_mouse_position()
				property_options.set_item_disabled(0,data.object is ShaderMaterial)
				data_selected = data
	

func object_submitted(obj_name: String):
	object_options.release_focus()
	object_options.visible = false
	obj_name = obj_name.strip_edges()
	if !obj_name: return
	addFileToGrid(obj_name,null)
	
	
func object_input(input: InputEvent):
	pass

const valid_types: PackedInt32Array = [
	TYPE_FLOAT,TYPE_INT,TYPE_VECTOR2
]

func property_submitted(prop: String):
	prop = prop.strip_edges()
	property_name.release_focus()
	property_name.visible = false
	if !prop: return
	
	var obj = data_selected.object
	if !obj: 
		obj = FunkinGD._find_object(data_selected.object_name)
		if !obj: return
	
	var value = obj.get(prop) 
	if value == null:
		Global.show_label_error('Cannot add "'+prop+'" property: missing or undefined type.',1.0,600)
		return
	
	if not typeof(value) in MathHelper.math_types:
		Global.show_label_error('Cannot add "'+prop+'" property: property is not a numeric type.',1.0,600)
		return
	addPropertyToGridFromData(data_selected,prop)

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
		0:
			property_name.text = ''
			property_name.visible = true
			property_name.position = get_viewport().get_mouse_position()
			property_name.grab_focus()
		1: removeObjectFromData(data_selected)
		
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
		0: #Delete
			removeKeysSelected()

func timeline_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				4: 
					var pos = floorf((position_line.position.x + grid_size.x)/grid_size.x)*grid_size.x
					position_line.position.x = pos
					set_song_position_from_line()
				5:
					var pos = floorf((position_line.position.x - grid_size.x)/grid_size.x)*grid_size.x
					position_line.position.x = pos
					set_song_position_from_line()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if !event.pressed: return
		match event.keycode:
			KEY_SPACE,KEY_ENTER: pausePlaystate(Conductor.is_playing)
			KEY_C:
				if Input.is_key_pressed(KEY_CTRL): copy_keys_selected()
			KEY_V:
				if Input.is_key_pressed(KEY_CTRL): paste_keys()
			KEY_DELETE: removeKeysSelected()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and not event.pressed:
			is_key_mouse_pressed = false
			is_moving_line = false
			disable_moving_keys.call_deferred()
			
	elif event is InputEventKey: if event.keycode == KEY_SHIFT: is_shift_pressed = event.pressed
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
func getObjectFromData(data: Dictionary) -> Object:
	var obj: Object = data.object
	if !obj: obj = FunkinGD._find_object(data.object_name)
	return obj

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
#endregion
class EditorMaterial extends ShaderMaterial:
	var objects: PackedStringArray = []
