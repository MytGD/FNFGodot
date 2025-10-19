const KeyInterpolator = preload("res://source/states/Modchart/Keys/KeyInterpolator.gd")
const EditorShader = preload("res://source/states/Modchart/Shaders/EditorShader.gd")
##Keys to Update:
##Must be like that:
##[codeblock]{"camGame":{
##"x": [
##      [time,value,time,Tween.TransType,Tween.EasingType]
##],
##"y": [
##   [50000,5,time,Tween.TRANS_CUBIC,Tween.Ease_OUT],
##   [55000,0,time,Tween.TRANS_CUBIC,Tween.Ease_OUT]
##}
##[/codeblock]
static var keys: Dictionary[String,Dictionary] = {}
static var keys_index: Dictionary[String,Dictionary] = {}

static func process_keys(back: bool = false):
	for obj in keys:
		var key_index_array = keys_index[obj]
		var obj_keys = keys[obj].keys
		for prop in obj_keys:
			var index = _check_key_index(obj_keys[prop],key_index_array,prop,back)
			key_index_array[prop] = index
	#update_keys()

static func _check_key_index(_keys: Array,key_index_array: Dictionary,prop: String, backward: bool) -> int:
	if !_keys: return 0
	var key_index: int = key_index_array[prop]
	var keys_size = _keys.size()
	var keys_length = keys_size-1
	if backward:
		while true:
			if key_index >= keys_size: key_index = keys_length
			var key = _keys[key_index]
			update_key(key)
			if !key_index or Conductor.songPosition > key.time: break
			key_index -= 1
		
	else:
		while key_index < keys_size:
			var key = _keys[key_index]
			update_key(key)
			if Conductor.songPosition < key.length: break
			key_index += 1
	
	return key_index

##Data = [time,init_val,value,duration,transition,easing]
static func update_key(key: KeyInterpolator):
	var value: Variant
	if Conductor.songPosition >= key.length: value = key.value
	elif Conductor.songPosition < key.time:  value = key.prev_val
	else:
		value = Tween.interpolate_value(
			key.init_val,
			key.value - key.init_val,
			Conductor.songPosition - key.time,
			key.duration,
			key.transition,
			key.ease
		)
	if key.object: setObjectValue(key.object,key.property,value)
	else: 
		setObjectValue(FunkinGD._find_object(key.object_name),key.property,value)
static func setObjectValue(obj: Variant, prop: String, value: Variant):
	if !obj: return
	if obj is ShaderMaterial: obj.set_shader_parameter(prop,value)
	else: obj.set(prop,value)

static func getObjectValue(obj: Variant, prop: String) -> Variant:
	if obj is String: obj = FunkinGD._find_object(obj)
	if !obj: return
	if obj is ShaderMaterial: return obj.get_shader_parameter(prop)
	return obj.get(prop)
static func loadFromData(data: Dictionary):
	for i in data:
		var c_data = data[i]
		var obj = i
		var shader_name = c_data.get('shader_name')
		if shader_name:
			obj = EditorShader.new()
			obj.shader_name = shader_name
			obj.objects = c_data.objects
			obj.material = Paths.loadShader(shader_name)
	
		var keys = c_data.keys
		for prop in keys:
			addProperty(i,prop)
			var _keys = keys[i][prop]
			for key in keys[prop]:
				var keyi = KeyInterpolator.new()
				keyi.time = key[0]
				keyi.value = key[1]
				keyi.init_val = key[2]
				keyi.duration = key[3]
				keyi.transition = key[4]
				keyi.ease = key[5]
				_keys.append(keyi)
			
static func get_keys_data() -> Dictionary:
	var new_data = {}
	for i in keys:
		var i_data = keys[i]
		var _keys = i_data.keys
		var data = {'keys': {}}
		if i_data.has('shader_name'): 
			data.objects = i_data.objects
			data.shader_name = keys[i].shader_name
		
		for prop in _keys: 
			var prop_keys = []
			for key in _keys[prop]: prop_keys.append(
				[
					key.time,
					key.init_val,
					key.value,
					key.duration,
					key.transition,
					key.ease
				]
			)
			data.keys[prop] = prop_keys
		new_data[i] = data
	return new_data


static func addProperty(obj_name: Variant, property: String):
	keys.get_or_add(obj_name,{'keys': {},'is_material': false}).keys[property] = []
	addPropertyIndex(obj_name, property)

static func addPropertyIndex(obj_name: Variant, property: String):
	keys_index.get_or_add(obj_name,{})[property] = 0
	
static func removeObject(obj_name: String):
	keys.erase(obj_name)
	keys_index.erase(obj_name)
	
static func removeProperty(obj_name: String, prop: String): pass
static func clear():
	keys.clear()
	keys_index.clear()
