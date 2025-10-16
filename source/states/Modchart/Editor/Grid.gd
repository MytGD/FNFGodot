@tool
extends ColorRect
const ModchartEditor = preload("res://source/states/Modchart/Editor/ModchartEditor.gd")
const ModchartState = preload("res://source/states/Modchart/ModchartState.gd")
const KeyInterpolator = preload("res://source/states/Modchart/KeyInterpolator.gd")
const KeyInterpolatorNode = preload("res://source/states/Modchart/Editor/KeyInterpolatorNode.gd")

var keys: Dictionary[String,Array] = {}
var keys_index: Dictionary[String,PackedInt64Array] = {}
var properties: Dictionary[String,Dictionary] = {}

var _keys_created: Array = []

var dropdownBox: DropdownBox

var object: Variant
var object_name: String
var property_list: Dictionary
func process_keys_front() -> void:
	for i in keys:
		var _k = keys[i]
		var array = keys_index[i]
 		
		while array[0] < _k.size():
			var key = _k[array[0]].key_node
			
			if key.position.x+key.length > 0: break
			array[0] += 1
			destroy_key(key)
			
		while array[1] < _k.size()-1:
			var key = _k[array[1]+1].key_node
			if key.step*ModchartEditor.grid_size.x - position.x >= size.x: break
			
			spawn_key(key)
			array[1] += 1

func spawn_key(key: KeyInterpolatorNode):
	if key in _keys_created: return
	add_child(key)
	_keys_created.append(key)

func destroy_key(key: KeyInterpolatorNode):
	remove_child(key)
	_keys_created.erase(key)
	
func process_keys_behind():
	for i in keys:
		var _k = keys[i]
		var array = keys_index[i]
		while array[0]:
			var key =  _k[array[0]-1].key_node
			if key.step*ModchartEditor.grid_size.x+key.length - position.x <= -10: break
			array[0] -= 1
			spawn_key(key)
	
		while array[1]:
			var key= _k[array[1]-1].key_node
			if key.position.x <= size.x: break
			array[1] -= 1
			destroy_key(key)

##Add Key
func addKey(step: float, property: String, value: Variant, duration: float,transition: Tween.TransitionType,ease: Tween.EaseType) -> int:
	if !keys.has(property): return -1
	var key_node = KeyInterpolatorNode.new()

	var key = key_node.data
	
	key.object = object
	key.object_name = object_name
	key.time = Conductor.get_step_time(step)
	key.duration = duration
	key.transition = transition
	key.value = value
	key.property = property
	key.ease = ease


	key_node.step = step
	return insertKeyToArray(key_node)

func insertKeyToArray(key_node: KeyInterpolatorNode) -> int:
	key_node.parent = self
	var key = key_node.data
	
	var changes = Conductor.get_bpm_changes_from_pos(key.time)
	if changes: key_node.step_crochet = Conductor.get_step_crochet(changes.bpm)
	else: key_node.step_crochet = Conductor.stepCrochet
	
	
	var property = key.property
	var _keys = keys[property]
	var index: int = _keys.size()
	while index > 0:
		if _keys[index-1].time > key.time: index -= 1
		break
	
	var key_index = keys_index[property]
	if index <= key_index[0]: key_index[0] += 1
	if index < key_index[1]: key_index[1] += 1
	
	if index > 0: 
		var prev_key = _keys[index-1]
		key.prev_val = prev_key.value
		
		if key.time <= prev_key.length:
			if prev_key.duration:
				prev_key.duration = key.time - prev_key.time
				prev_key.key_node.queue_redraw()
			else: return index
			
	else: key.prev_val = properties[property].default
	
	key_node.position.y = size.y/keys.size()/2.0 - key_node.size.y/2.0 + ModchartEditor.grid_size.y*keys.keys().find(property)
	_keys.insert(index,key)
	spawn_key(key.key_node)
	return index

func removeKey(key: KeyInterpolatorNode):
	var data = key.data
	var keys_array = keys[data.property]
	
	var index = keys_array.find(data)
	var key_index = keys_index[data.property]
	
	
	if key_index[0] and index <= key_index[0]: key_index[0] -= 1
	if key_index[1] and index <= key_index[1]: key_index[1] -= 1
	
	print(data)
	keys_array.erase(data)
	_keys_created.erase(key)
	key.queue_free()
	
func createProperty(prop: String) -> bool:
	if properties.has(prop): return true
	keys[prop] = []
	keys_index[prop] = PackedInt64Array([0,0])
	
	var obj = object
	if !obj: obj = FunkinGD._find_object(object_name)
	if !obj: return false
	
	var value: Variant
	if object is ShaderMaterial: value = RenderingServer.shader_get_parameter_default(object.shader.get_rid(),prop)
	else: value = obj.get(prop)
	properties[prop] = {'default': value,'type': typeof(value)}
	updateSize()
	return true

func removeProperty(prop: String):
	if properties.has(prop): return
func updateSize():
	size.y = keys.size()*ModchartEditor.grid_size.y
	material.set_shader_parameter('parent_size',size)
