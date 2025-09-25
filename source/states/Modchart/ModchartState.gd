const KeyInterpolator = preload("res://source/states/Modchart/KeyInterpolator.gd")
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

static var keys_updating: Array[KeyInterpolator] = []

static var objects_first_values: Dictionary = {}

static func process_keys_front():
	for obj in keys:
		var obj_keys = keys[obj]
		for prop in obj_keys:
			var _keys = obj_keys[prop]
			if !_keys: continue
			
			
			var key_index_array = keys_index[obj] #[back,front]
			var key_index = mini(key_index_array[prop],_keys.size()-1)
			
			while true:
				var key = _keys[key_index]
				update_key(key)
				if Conductor.songPosition < key.time or key_index >= _keys.size()-1: break
				key_index += 1
			key_index_array[prop] = key_index
	update_keys()

static func update_key(key: KeyInterpolator):
	if Conductor.songPosition >= key.time:
		if key.duration and Conductor.songPosition < key.length: keys_updating.append(key)
		else: key.set_object_value(key.value)
	else: key.set_object_value(key.prev_val)
	
static func update_keys():
	var i: int = 0
	while i < keys_updating.size():
		var key = keys_updating[i]
		key._process()
		if Conductor.songPosition < key.time:
			key.set_object_value(key.prev_val)
			keys_updating.remove_at(i)
			continue
		elif Conductor.songPosition >= key.length:
			key.set_object_value(key.value)
			keys_updating.remove_at(i)
			continue
		i += 1
			
static func process_keys_back():
	for obj in keys:
		var obj_keys = keys[obj]
		for prop in obj_keys:
			var _keys = obj_keys[prop]
			if !_keys: continue
			
			var key_index_array = keys_index[obj] #[back,front]
			var key_index = mini(key_index_array[prop],_keys.size()-1)
			print(key_index)
			while true:
				var key = _keys[key_index]
				update_key(key)
				if !key_index or key.time < Conductor.songPosition: break
				key_index -= 1
			
			key_index_array[prop] = key_index
	update_keys()
static func addProperty(obj_name: String, property: String):
	keys.get_or_add(obj_name,{})[property] = []
	keys_index.get_or_add(obj_name,{})[property] = 0

static func removeObject(obj_name: String):
	keys.erase(obj_name)
	keys_index.erase(obj_name)
	
static func clear():
	keys.clear()
	keys_index.clear()
