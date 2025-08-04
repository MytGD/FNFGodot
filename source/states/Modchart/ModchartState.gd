const KeyInterpolator = preload("res://source/states/Modchart/KeyInterpolator.gd")
static var keys: Array[KeyInterpolator] = []

static var keys_to_update: Array[KeyInterpolator] = []
static var cur_key_index: int = 0
static var songPos: float = 0.0: set = set_song_position

enum PROPERTY_TYPES{
	TYPE_SHADER,
	TYPE_OBJECT
}

static func set_song_position(value: float):
	var old_value = songPos
	songPos = value
	if songPos < old_value:
		process_back_keys()
	else:
		process_keys()
		
static func process_keys():
	if !keys: return
	while cur_key_index < keys.size():
		var key = keys[cur_key_index]
		if key.time > songPos: break
		if !key.duration or songPos >= key.end_time:  setKeyValue(key,key.value)
		else: keys_to_update.append(key)
		cur_key_index += 1
	process_keys_values()
	
static func process_keys_values():
	if !keys_to_update: return
	var index: int = 0
	while index < keys_to_update.size():
		var key = keys_to_update[index]
		if !key: keys_to_update.remove_at(index); continue
		if songPos >= key.end_time:
			setKeyValue(key,key.value)
			keys_to_update.remove_at(index)
			continue
		elif songPos <= key.time:
			setKeyValueFromPrev(key)
			keys_to_update.remove_at(index)
			continue
		updateKeyValue(key)
		index += 1


static func process_back_keys():
	if !keys: return
	while cur_key_index > 0:
		var key = keys[cur_key_index-1]
		if songPos >= key.end_time: break
		
		if !key.duration or songPos < key.time: setKeyValue(key,key.value)
		else: keys_to_update.append(key)
		cur_key_index -= 1
	process_keys_values()

static func updateKeyValue(key: KeyInterpolator):
	var duration: float = key.duration*1000
	setKeyValue(key,Tween.interpolate_value(
		key.init_value, #init_value
		key.value - key.init_value, #end_value
		(Conductor.songPosition - key.time)/duration, #process
		1.0, #duration
		key.trans, #Transition
		key.ease #Easing
	))



static func removeKey(key: KeyInterpolator):
	if key.time <= Conductor.songPosition: setKeyValueFromPrev(key)
	
	if cur_key_index >= keys.size(): cur_key_index -= 1
	keys.erase(key)

static func setKeyValueFromPrev(key: KeyInterpolator):
	var keys_in_line = key.keys_in_same_line
	var index: int = keys_in_line.find(key)
	if index > 0: setKeyValue(key,keys_in_line[index-1].value)
	else: setKeyValue(key,key.default_object_value)

static func setKeyValue(key: KeyInterpolator, value: Variant):
	match key.object_type:
		PROPERTY_TYPES.TYPE_SHADER: FunkinGD.setShaderParameter(key.object_tag,key.parameter,value)
		_: FunkinGD.setProperty(key.object_tag+'.'+key.parameter,value)
	
static func loadShader(shader_tag: String,shader_material: String, cameras: PackedStringArray):
	var shader = Paths.loadShader(shader_material)
	if !shader: return
	
	shader.resource_name = shader_tag
	FunkinGD.shadersCreated[shader_tag] = shader
	for i in cameras:
		var cam = FunkinGD.getCamera(i)
		if cam: cam.addFilters([shader])
	return shader
static func removeShader(shader_tag: String):
	pass
