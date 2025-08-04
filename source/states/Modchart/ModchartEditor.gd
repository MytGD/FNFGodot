extends Node2D

const Grid = preload("res://source/states/Modchart/Grid.gd")
const GridSize = 50
const Character = preload("res://source/objects/Sprite/Character.gd")
const ModchartState = preload("res://source/states/Modchart/ModchartState.gd")

const DropdownBox = preload("res://source/states/Modchart/DropdownBox.gd")

const KeyNode = preload("res://source/states/Modchart/KeyNode.gd")
const KeyInterpolator = preload("res://source/states/Modchart/KeyInterpolator.gd")
const KeySelectedColor = Color.CYAN
const KeyStaticColor = Color.WHITE

const MouseSelection = preload("res://source/general/mouse/MouseSelection.gd")

var mouse_selection = MouseSelection.new()

@onready var game = $GameView
var paused: bool = false

#region Grid
enum PROPERTY_TYPES{
	TYPE_CHARACTER,
	TYPE_OBJECT,
	TYPE_CAMERA,
	TYPE_SHADER
}

var zoom: float = 1.0
@onready var zoom_scroll := $Split/P_Split/P_Keys/VBoxContainer/Zoom
var grid_x: float = 0 #Setted in PositionLine
var grid_size_x: float = GridSize
#endregion

var json: Dictionary = {
	'keys': [],
	'objects': {},
}
@onready var song_bpm := $Split/O_Split/TabContainer/Song/BPM

#region Keys Methods
var is_shift_pressed: bool = false
#endregion

#region Properties
var keys_created: Array[KeyInterpolator] = []
var cur_key_index: int = 0
@onready var song_position := $Split/P_Split/P_Keys/VBoxContainer/SongPosition



@onready var property_vbox := $Split/P_Split/P_Container/S_Container/Scroll/VBoxContainer
@onready var property_values_grid := $Split/P_Split/P_Keys

@onready var property_values_panel := $Split/O_Split/V_Split/P_Panel/P_Scroll/Property/Values
@onready var property_value := $Split/O_Split/V_Split/P_Panel/P_Scroll/Property/Values/Value
@onready var property_vectors := [
	$Split/O_Split/V_Split/P_Panel/P_Scroll/Property/Values/ValueX,
	$Split/O_Split/V_Split/P_Panel/P_Scroll/Property/Values/ValueY,
	$Split/O_Split/V_Split/P_Panel/P_Scroll/Property/Values/ValueZ,
	$Split/O_Split/V_Split/P_Panel/P_Scroll/Property/Values/ValueW,
]

@onready var property_vectors_init := [
	$Split/O_Split/V_Split/P_Panel/P_Scroll/Property/Values/InitValueX,
	$Split/O_Split/V_Split/P_Panel/P_Scroll/Property/Values/InitValueY,
	$Split/O_Split/V_Split/P_Panel/P_Scroll/Property/Values/InitValueZ,
	$Split/O_Split/V_Split/P_Panel/P_Scroll/Property/Values/InitValueW,
]

@onready var property_init_value := $Split/O_Split/V_Split/P_Panel/P_Scroll/Property/Values/InitValue
@onready var property_duration := $Split/O_Split/V_Split/P_Panel/P_Scroll/Property/TweenProperty/Duration
@onready var property_trans := $Split/O_Split/V_Split/P_Panel/P_Scroll/Property/TweenProperty/TransitionType
@onready var property_ease := $Split/O_Split/V_Split/P_Panel/P_Scroll/Property/TweenProperty/EasingType

@onready var property_nodes: Array = [
	property_value,
	property_init_value,
	property_duration,
	property_trans,
	property_ease
]
#endregion

var objects_created: Dictionary[StringName,Dictionary] = {}

var keys_mapping: Array:
	get():
		return ModchartState.keys

var keys_created_back_index: int = 0
var keys_created_front_index: int = 0

var keys_selected: Array[KeyInterpolator] = []
var keys_copied: Array[Array] = []
var keys_to_update: Array[KeyInterpolator] = []

var _key_found: KeyInterpolator

var is_moving_keys: bool = false
var keys_moved: bool = false

var move_first_pos: float = 0
var keys_to_move: Array = []
var is_removing_keys: bool = false


var songPos: float = 0.0
var song_step: float = 0.0
var is_selecting_keys: bool = false

signal key_insert()
signal zoom_changed(value: float)
signal song_position_changed(value: float)

func _ready() -> void:
	Conductor.song_loaded.connect(func():
		song_position.max_value = Conductor.songLength
	)
	song_position.scrolling.connect(func():
		pauseSong()
		if !is_shift_pressed:
			setSongPosition(roundf(song_position.value/Conductor.stepCrochet)*Conductor.stepCrochet,true)
		else:
			setSongPosition(song_position.value,true)
	)
	Conductor.bpm_changes.connect(updateBpm)
	song_position.max_value = Conductor.songLength
	updateBpm()
	
	for i in property_nodes:
		pass
	
	for i in ClassDB.class_get_enum_constants("Tween","TransitionType",true):
		property_trans.add_item(StringHelper.first_letter_upper(i.right(-6).to_lower()))
	
	for i in ClassDB.class_get_enum_constants("Tween","EaseType",true):
		property_ease.add_item(StringHelper.first_letter_upper(i.right(-5).to_lower()))
	
	mouse_selection.can_select = false
	mouse_selection.released.connect(func():
		if mouse_selection.size > Vector2(10,10):
			is_selecting_keys = true
			selectKeys(findKeysAtRegion(mouse_selection.get_rect(),true))
		)
		
	add_child(mouse_selection)
func updateBpm():
	song_bpm.set_value_no_signal(Conductor.bpm)
	song_position.min_value = -Conductor.stepCrochet*24.0
	property_duration.value_to_add = Conductor.stepCrochet/1000.0
	property_duration.shift_value = property_duration.value_to_add*2.0
	
func _process(delta: float) -> void:
	if is_removing_keys:
		removeKey(findKeyAtMouse(get_viewport().get_mouse_position(),true),true)
	if paused: return
	song_position.value = Conductor.songPosition
	song_step = Conductor.step_float
	setSongPosition(Conductor.songPosition)
	
	
	
#keys: [[time,material,value,init_value,duration,trans,easing]]
#
#
#
#shaders: [shader1,[cameras],ta]
func loadModchart(data: Dictionary):
	for i in data.get('shaders',[]): insertShader(i[0],i[1],i[2])
	for i in data.get('keys',[]): pass

#region Editor Methods
func insertShader(shader_name: StringName, tag: StringName, cameras: PackedStringArray = []):
	if !tag: tag = shader_name
	
	var shader = ModchartState.loadShader(tag,shader_name,cameras)
	
	if !shader or !shader.shader: return
	var uniforms: Dictionary = {}
	for i in shader.shader.get_shader_uniform_list(true):
		var type = i.type
		match type:
			TYPE_NIL,TYPE_STRING,TYPE_STRING_NAME,TYPE_OBJECT,TYPE_DICTIONARY,TYPE_ARRAY: continue
		var default_value = shader.get_shader_parameter(i.name)
		if default_value == null: default_value = MathHelper.get_new_value(type)
		
		uniforms[i.name] = {
			'type': i.type,
			'default_value': default_value
		}
	
	var shader_data: Dictionary = {
		'object': shader,
		'type': ModchartState.PROPERTY_TYPES.TYPE_SHADER,
		'properties': uniforms,
		'properties_names': uniforms.keys(),
		'cameras': cameras,
		'keys': []
	}
	objects_created[tag] = shader_data
	json.objects[tag] = {
		'type': 'Material',
		'cameras': cameras
	}
	createGrid(tag,shader_data)
	for i in cameras: 
		if objects_created.has(i): objects_created[i].object.addFilters([shader])
	
func removeShader(shader_tag: StringName):
	if !objects_created.has(shader_tag): return
	var shader_data = objects_created[shader_tag]
	for i in shader_data.get('cameras',[]): i.removeFilter(shader_data.material)
	removeObject(shader_tag)
	
func insertObject(object_name: StringName, type: PROPERTY_TYPES):
	var obj = FunkinGD._find_object(object_name)
	if !obj:
		Global.show_label_error('Cannot insert a non-existent object.'); return
	var properties = getPropertyList(type)
	var object_data: Dictionary = {
		'object': obj,
		'type': ModchartState.PROPERTY_TYPES.TYPE_OBJECT,
		'properties': properties,
		'properties_names': properties.keys(),
		'keys': []
	}
	json.objects[object_name] = {
		'type': ModchartState.PROPERTY_TYPES.TYPE_OBJECT
	}
	createGrid(object_name,object_data)

func removeObject(tag: StringName):
	if !objects_created.has(tag): return
	
	var object_data = objects_created.get(tag)
	for i in object_data.keys: removeKey(i,true)
	
	object_data.tab.queue_free()
	object_data.grid.queue_free()
	objects_created.erase(tag)
	json.objects.erase(tag)
	
func createGrid(tag: StringName,object_data: Dictionary):
	var tab = DropdownBox.new()
	tab.name = tag
	object_data.tab = tab
	for i in object_data.properties_names: tab.texts.append(i)
	property_vbox.add_child(tab)
	
	var grid = property_values_grid.createGrid(tab)
	object_data.grid = grid
	
	var remove_button = TextureButton.new()
	remove_button.texture_normal = load("res://icons/basic/Remove.svg")
	remove_button.name = 'Remove'
	remove_button.focus_mode = Control.FOCUS_NONE
	remove_button.anchor_left = 1
	remove_button.anchor_right = 1
	remove_button.offset_left = -remove_button.get_minimum_size().x - 5
	tab.add_child(remove_button)
	
	var visible_button = TextureButton.new()
	visible_button.texture_normal = load("res://icons/basic/GuiVisibilityVisible.svg")
	visible_button.texture_pressed = load("res://icons/basic/GuiVisibilityHidden.svg")
	visible_button.name = 'Visible'
	visible_button.focus_mode = Control.FOCUS_NONE
	visible_button.toggle_mode = true
	visible_button.anchor_left = 1
	visible_button.anchor_right = 1
	visible_button.offset_left = -visible_button.get_minimum_size().x*2 - 15
	tab.add_child(visible_button)
	
	match object_data.type:
		PROPERTY_TYPES.TYPE_SHADER: remove_button.button_down.connect(removeShader.bind(tag))
		_: remove_button.button_down.connect(removeObject.bind(tag))
	objects_created[tag] = object_data
	grid.gui_input.connect(_grid_input.bind(grid,object_data))
	return grid

func getMouseRoundGridX(mouse_x: float) -> float: return getGridIndexFromMouseX(mouse_x) * grid_size_x

func getGridIndexFromMouseX(mouse_x, rounded: bool = true):
	var cal = (mouse_x + grid_size_x * grid_x)/grid_size_x
	return roundf(cal) if rounded else cal

func getGridIndexFromMouseY(mouse_y,grid, rounded: bool = true):
	var cal = (mouse_y)/grid_size_x
	return roundf(cal) if rounded else cal

func getMouseRoundGridY(mouse_y: float,grid: Grid): return int(mouse_y/grid.grid_size.y) * grid.grid_size.y + grid.grid_size.y/2.0
func getSongPositionFromMouseX(mouse_x: float, rounded: bool = true):
	return getGridIndexFromMouseX(mouse_x,rounded) * Conductor.stepCrochet - Conductor.step_offset
	

	
func setZoom(zoom_value: float):
	grid_size_x = GridSize*zoom_value
	for i in objects_created.values(): i.grid.grid_size.x = grid_size_x
	
	for i in keys_created: i.key_node.queue_redraw()
	zoom = zoom_value
#region Key Methods
##Insert a Key in the Song. 
##[param key_data] is a [Array] that contains: 
##[br][code][key_position, object_tag, parameter, first_value, end_value, duration, transition, easing][/code]
func insertKey(key_data: Array) -> KeyInterpolator:
	var object_data: Dictionary = objects_created.get(key_data[1])
	if !object_data: return

	var parameter_index: int = object_data.properties_names.find(key_data[2])
	
	var object: Object = objects_created.get(key_data[1]).object
	
	var grid: Grid = object_data.grid
	
	var key = KeyInterpolator.new()
	var key_node = KeyNode.new()
	
	key.key_node = key_node
	
	var prev_keys = object_data.keys
	key.array = key_data
	key.keys_in_same_line = prev_keys
	key.object_type = object_data.type
	key.update_data()
	
	key_node.position.y = grid.grid_size.y*parameter_index + grid.grid_size.y/2.0
	key_node.grid = grid
	key_node.key_data = key
	
	#Insert Key in Map
	var key_index: int = 0
	for i in prev_keys:
		if i.time > key.time: break
		key_index += 1
	prev_keys.insert(key_index,key)
	#If init_value is null, will try to set from the previous key or from the object.
	if key.init_value == null:
		if key_index:
			key.init_value = prev_keys[key_index-1].value
		elif object:
			if object_data.type == PROPERTY_TYPES.TYPE_SHADER: key.init_value = object.get_shader_parameter(key.parameter)
			else: key.init_value = object.get(key.parameter)
		
		if key.init_value == null:
			key.init_value = MathHelper.get_new_value(object_data.properties[key.parameter].type)
	
	if key.value == null:
		key.value = key.init_value
	
	key.default_object_value = key.init_value
	
	addKeyToScene(key,insertKeySortToArray(key,keys_mapping))
	return key


func insertKeyInGrid(key_position: Vector2, object_data: Dictionary) -> KeyInterpolator:
	var grid = object_data.grid
	
	var props_size = object_data.properties_names.size() 
	var index: int = key_position.y / (grid.size.y /props_size )
	
	if index < 0 or index >= props_size: return
	
	var object: Object = object_data.object
		
	var time: float = Conductor.get_step_time(key_position.x/grid_size_x)
	
	var property = object_data.properties_names[index]
	
	var value: Variant 
	
	return insertKey([time,grid.name,property,null,null,0,Tween.TRANS_LINEAR,Tween.EASE_OUT])
	

func findKeyAtMouse(mouse_pos: Vector2, global_pos: bool = false) -> KeyInterpolator:
	for i in keys_created:
		var key_size = i.key_node.size + Vector2(i.key_node.key_length - 10,0).max(Vector2.ZERO)
		var key_area = Rect2(
			(i.key_node.global_position if global_pos else i.key_node.position), 
			key_size
		)
		if Rect2(mouse_pos,Vector2(2,2)).intersects(key_area): return i
	return null

func findKeysAtRegion(rect: Rect2, global: bool = true) -> Array[KeyInterpolator]:
	var keys: Array[KeyInterpolator] = []
	for i in keys_created:
		if rect.intersects(Rect2(
			(i.key_node["global_position" if global else "position"])-i.key_node.size/2.0,
			i.key_node.size),true): keys.append(i)
	return keys

		
func addKeyToScene(key: KeyInterpolator, at: int = -1) -> int:
	var grid = objects_created[key.object_tag].grid
	grid.add_child(key.key_node)
	if at != -1: grid.move_child(key.key_node,at)
	
	var key_index = insertKeySortToArray(key,keys_created)
	if key_index < keys_created_front_index: keys_created_front_index += 1
	return key_index

func removeKeyFromScene(key: KeyInterpolator):
	var grid = objects_created[key.object_tag].grid
	grid.remove_child(key.key_node)
	keys_created.erase(key)

func removeKey(key: KeyInterpolator,remove_from_modchart: bool = false):
	if !key: return
	key.key_node.get_parent().remove_child(key.key_node)
	keys_created.erase(key)
	cur_key_index = mini(cur_key_index,keys_created.size())
	if remove_from_modchart:
		unselectKey(key)
		ModchartState.removeKey(key)
		objects_created[key.object_tag].keys.erase(key)
		key.key_node.queue_free()

func selectKey(key: KeyInterpolator, add: bool = true):
	if !key: unselectKeys(); return
	
	if not add:
		unselectKeys()
		keys_selected.append(key)
	else: insertKeySortToArray(key,keys_selected)
		
	key.key_node.modulate = KeySelectedColor

	updateKeyData()

func toggleKey(key: KeyInterpolator, add: bool = true):
	if key in keys_selected:
		unselectKey(key)
		return
	selectKey(key,add)
	
func unselectKey(key: KeyInterpolator):
	if !key in keys_selected: return
	key.key_node.modulate = KeyStaticColor
	keys_selected.erase(key)
	updateKeyData()
	
func insertKeySortToArray(key: KeyInterpolator, array: Array[KeyInterpolator]) -> int:
	var index: int = 0
	for i in array:
		if i.time > key.time or i.time == key.time and i.duration >= key.duration:
			array.insert(index,key)
			return index
		index += 1
	array.append(key)
	return index
	
func selectKeys(keys_array: Array[KeyInterpolator]):
	unselectKeys()
	for i in keys_array:
		i.key_node.modulate = KeySelectedColor
		insertKeySortToArray(i,keys_selected)
	

func unselectKeys():
	for i in keys_created: 
		i.key_node.modulate = KeyStaticColor
	keys_selected.clear()

func updateKeyData():
	if !keys_selected: return
	
	var key = keys_selected[0]
	
	var type =  typeof(key.value)
	
	var vector_dimensions: int = 1
	if VectorHelper.is_vector_type(type) or type == TYPE_COLOR:
		vector_dimensions = detectVectorDimension(type)
		for i in property_vectors.slice(vector_dimensions):
			i.set_value_no_signal(key.value[i.name.right(1).to_lower()])
		
		for i in property_vectors_init.slice(vector_dimensions):
			i.set_value_no_signal(key.init_value[i.name.right(1).to_lower()])
		
	elif type == TYPE_INT or type == TYPE_FLOAT:
		property_value.set_value_no_signal(key.value)
		property_init_value.set_value_no_signal(key.init_value)
	
	property_duration.set_value_no_signal(key.duration)
	property_trans.selected = key.trans
	property_ease.selected = key.ease
	
	if keys_selected.size() > 1: updateMultipleKeysData(); return
	
	showValueNodes(vector_dimensions)
	property_values_panel.visible = true

func detectVectorDimension(value_type: Variant.Type) -> int:
	match value_type:
		TYPE_VECTOR2,TYPE_VECTOR2I: return 2
		TYPE_VECTOR3,TYPE_VECTOR3I: return 3
		TYPE_VECTOR4,TYPE_VECTOR4I,TYPE_COLOR: return 4
		_: return 1
func showValueNodes(vector_size: int):
	for i in property_vectors: i.visible = false
	
	if vector_size <= 1: property_value.show(); property_init_value.show(); return
	
	property_value.hide()
	property_init_value.hide()
	for i in property_vectors.slice(vector_size): i.visible = true
	
func updateMultipleKeysData():
	var key_data_length: PackedInt32Array = [3,4,5,6,7]
	var key_data_size = range(key_data_length.size())
	var old_key: KeyInterpolator = keys_selected[0]
	
	var have_different_values: bool = false
	for key in keys_selected.slice(1):
		for i in key_data_size:
			var index = key_data_length[i]
			if old_key.array[index] == key.array[index]: continue
			have_different_values = true
			key_data_size.remove_at(i)
	
	if !have_different_values:
		property_values_panel.visible = true
		showValueNodes(detectVectorDimension(typeof(old_key.value)))
	else: property_values_panel.visible = false
		

func checkKeysToUpdate() -> Array[KeyInterpolator]:
	var keys: Array[KeyInterpolator] = []
	for i in keys_created:
		if songPos <= i.time or songPos > i.time + i.duration*1000: continue
		keys.append(i)
	return keys
	
#region Process Keys
func can_insert_key(show_error: bool = true) -> bool:
	if !Conductor.songs:
		if show_error: Global.show_label_error('Insert a Song first!')
		return false
		
	if !Conductor.bpm:
		if show_error: Global.show_label_error('Insert a BPM first!')
		return false
	return !keys_moved




#endregion

#region Set Key Values
func setKeyValue(value: float):
	for i in keys_selected:
		i.value = value
		if i.time >= songPos and i.end_time <= songPos:
			ModchartState.setKeyValue(i,i.value)

func setKeyInitValue(value: float):
	for i in keys_selected:
		i.init_value = value
	
#Vectors/Colors
func setKeyValueVector(index: String, value: float):
	for i in keys_selected:
		match index:
			'x': i.value.x = value
			'y': i.value.y = value
			'z': i.value.z = value
			'w': i.value.w = value

func setKeyInitValueVector(index: String,value: float):
	for i in keys_selected:
		match index:
			'x': i.init_value.x = value
			'y': i.init_value.y = value
			'z': i.init_value.z = value
			'w': i.init_value.w = value
#endregion

func setKeyDuration(duration: float):
	for i in keys_selected:
		i.duration = duration

func setKeyTransType(tween: Tween.TransitionType):
	for i in keys_selected:
		i.trans = tween

func setKeyEaseType(ease: Tween.EaseType):
	for i in keys_selected:
		i.ease = ease
#endregion

#region Song Methods
func setSongPosition(value: float, seek: bool = false) -> void:
	if value == songPos: return
	var old_pos = songPos
	songPos = value
	ModchartState.songPos = songPos
	
	if value == Conductor.songPosition: return
	
	song_step = Conductor.get_step(value)
	if seek: 
		Conductor.setSongPosition(value)
		game.view.updateNotes()
	
	#if songPos < old_pos:
		#spawnKeysBackward()
	#else:
		#spawnKeysForward()
	
	song_position_changed.emit()

func spawnKeysBackward():
	var key_size: int = keys_created.size()
	while keys_created_back_index:
		var key = keys_mapping[keys_created_back_index]
		if key.key_node.getKeyPosition() < 0: break
		addKeyToScene(key,0)
		keys_created_back_index += 1
		print("Key Added Backward: ",key)
	
	while keys_created_front_index:
		var key = keys_created[keys_created_front_index]
		if key.key_node.getKeyPosition() < property_values_grid.size.x: break
		removeKeyFromScene(key)
		keys_created_front_index -= 1
		print("Key Removed Backward: ",key)
func spawnKeysForward():
	var key_size: int = keys_created.size()
	while keys_created_back_index < key_size:
		var key = keys_created[keys_created_back_index]
		if key.key_node.getKeyPosition() > 0: break
		print("Key Removed Forward: ",key)
		removeKeyFromScene(key)
		keys_created_back_index -= 1
	
	while keys_created_front_index < key_size:
		var key = keys_mapping[keys_created_front_index]
		print("Key Added Forward: ",key)
		if key.key_node.getKeyPosition() > property_values_grid.size.x: break
		addKeyToScene(key)
		keys_created_front_index += 1
	
func setBpm(new_bpm: float): Conductor.setSongBpm(new_bpm)
#endregion


func pauseSong() -> void:
	if paused: return
	paused = true
	Conductor.pauseSongs()
	game.process_mode = Node.PROCESS_MODE_DISABLED

func resumeSong() -> void:
	if !paused: return
	paused = false
	Conductor.resumeSongs()
	game.process_mode = Node.PROCESS_MODE_INHERIT
	
#region Input Methods
func _grid_input(event: InputEvent, grid: Grid, shader_data: Dictionary):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			var mouse_pos = event.position
			mouse_pos.y = getMouseRoundGridY(mouse_pos.y,grid)
			_key_found = findKeyAtMouse(mouse_pos)
			if !_key_found:
				mouse_pos.x = getMouseRoundGridX(mouse_pos.x)
				_key_found = findKeyAtMouse(mouse_pos)
			
			if !_key_found:
				unselectKeys()
				mouse_selection.start_selection()
			is_selecting_keys = false
			if keys_selected:
				#Move Keys
				is_moving_keys = true
				keys_moved = false
				move_first_pos = keys_selected[0].time
			
		else:
			if is_selecting_keys: return
			#Select Multiple Keys
			if keys_moved: return
			if _key_found: toggleKey(_key_found,is_shift_pressed)
			elif can_insert_key():
				if !is_shift_pressed: event.position.x = getMouseRoundGridX(event.position.x)
				else: event.position.x += grid_x + grid_size_x
				selectKey(insertKeyInGrid(event.position,shader_data),false)
				
	elif event is InputEventMouseMotion and is_moving_keys:
		var mouse_pos = getSongPositionFromMouseX(event.position.x,!is_shift_pressed)
		if mouse_pos == keys_selected[0].time: return
		
		keys_moved = true
		var difference = mouse_pos - move_first_pos
		
		for i in keys_selected: i.time += difference
		move_first_pos += difference
		
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			1:
				if !event.pressed: is_moving_keys = false
			2:
				is_removing_keys = event.pressed
			
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		match event.keycode:
			KEY_SPACE:
				if !event.pressed: return
				if paused: resumeSong()
				else: pauseSong()
			KEY_C:
				if !event.pressed or !Input.is_key_pressed(KEY_CTRL) or !keys_selected:return
				#Copy Keys
				keys_copied.clear()
				for i in keys_selected: keys_copied.append(i.array.duplicate())
				Global.show_label_error('Copied Keys')
			
			KEY_V:
				if !event.pressed or !Input.is_key_pressed(KEY_CTRL) or !keys_copied: return
				
				#Paste Keys
				var keys: Array[KeyInterpolator] = []
				
				var sub = (songPos if is_shift_pressed else Conductor.get_step_time(Conductor.step)) - keys_copied[0][0] 
				for i in keys_copied:
					i[0] += sub
					keys.append(insertKey(i))
				selectKeys(keys)
				
				var last_key = keys_copied.back()
				if !Conductor.is_playing:
					setSongPosition(last_key[0] + last_key[5],true)
				Global.show_label_error('Pasted Keys')
				
			KEY_SHIFT:
				is_shift_pressed = event.pressed
#endregion
#endregion

static func getPropertyList(type: PROPERTY_TYPES) -> Dictionary:
	match type:
		PROPERTY_TYPES.TYPE_CHARACTER:
			return {
				'x': {'type': TYPE_FLOAT,'default_value': 0.0},
				'y': {'type': TYPE_FLOAT,'default_value': 0.0},
				'_position': {'type': TYPE_VECTOR2,'default_value': Vector2.ZERO},
				'cameraOffset': {'type': TYPE_VECTOR2,'default_value': Vector2.ZERO},
				'scale': {'type': TYPE_VECTOR2,'default_value': Vector2.ONE},
				'alpha': {'type': TYPE_FLOAT,'default_value': 1.0},
				'angle': {'type': TYPE_FLOAT,'default_value': 0.0},
			}
		PROPERTY_TYPES.TYPE_CAMERA:
			return {
				'x': {'type': TYPE_FLOAT,'default_value': 0.0},
				'y': {'type': TYPE_FLOAT,'default_value': 0.0},
				'zoom': {'type': TYPE_FLOAT,'default_value': 1.0},
				'alpha': {'type': TYPE_FLOAT,'default_value': 1.0},
				'angle': {'type': TYPE_FLOAT,'default_value': 0.0},
				'shakeTime': {'type': TYPE_FLOAT, 'default_value': 0.0}
			}
		PROPERTY_TYPES.TYPE_OBJECT:
			return {
				'x': {'type': TYPE_FLOAT,'default_value': 0.0},
				'y': {'type': TYPE_FLOAT,'default_value': 0.0},
				'zoom': {'type': TYPE_FLOAT,'default_value': 1.0},
				'alpha': {'type': TYPE_FLOAT,'default_value': 1.0},
				'angle': {'type': TYPE_FLOAT,'default_value': 0.0},
			}
		_:
			return {}
