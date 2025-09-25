extends Object
const KeyInterpolator = preload("res://source/states/Modchart/KeyInterpolator.gd")
#Key Data
var time: float: set = _set_time
var length: float = 0.0

var object: Variant: set = _set_object
var property: String: set = _set_property
var duration: float: set = _set_duration
var init_val: Variant: set = _set_init_val
var prev_val: Variant: set = _set_prev_val
var value: Variant: set = _set_value
var transition: Tween.TransitionType: set = _set_trans
var ease: Tween.EaseType: set = _set_ease
var array: Array = [
	time,
	object,
	property,
	init_val,
	value,
	duration,
	transition,
	ease
]: set = _set_array

var key_node: CanvasItem

#EditorProperties
var tween_started: bool = false
var is_shader: bool = false
var _need_to_find_obj: bool = false

func _process() -> void:
	if !object or !property: return
	if Conductor.songPosition >= time:
		if duration: 
			set_object_value(_get_cur_value())
			tween_started = true
		else:  
			set_object_value(value)
	else: 
		set_object_value(prev_val)
		
func _get_cur_value() -> Variant:
	return Tween.interpolate_value(
			init_val,
			value - init_val,
			clampf(Conductor.songPosition - time,0.0,duration),
			duration,
			transition,
			ease
	)

func set_object_value(value: Variant):
	if _need_to_find_obj:
		var obj = FunkinGD.getProperty(object)
		if obj: _set_obj_value_no_check(obj,value)
	elif object: _set_obj_value_no_check(object,value)

func _set_obj_value_no_check(obj: Object, value: Variant):
	if is_shader: obj.set_shader_parameter(property,value)
	else: FunkinGD.setProperty(property,value,obj)

#region Data
func _set_time(_time: float):
	time = _time
	length = time + duration
	array[0] = _time

func _set_object(obj_name: Variant):
	_need_to_find_obj = obj_name is String
	object = obj_name
	if !_need_to_find_obj: is_shader = object is ShaderMaterial
	array[1] = obj_name

func _set_property(prop: String):
	property = prop
	array[2] = prop

func _set_init_val(val: Variant):
	init_val = val
	array[3] = val
	if tween_started: set_object_value(_get_cur_value())
	
func _set_value(val: Variant):
	value = val
	array[4] = val
	if tween_started: set_object_value(_get_cur_value())

func _set_duration(_duration: float):
	duration = _duration
	array[5] = _duration
	length = time + duration
	if tween_started: set_object_value(_get_cur_value())
	if key_node: key_node.queue_redraw()
	
func _set_trans(_trans: Tween.TransitionType):
	transition = _trans
	array[6] = _trans
	if tween_started: set_object_value(_get_cur_value())
	
func _set_ease(_ease: Tween.EaseType):
	ease = _ease
	array[7] = ease
	if tween_started: set_object_value(_get_cur_value())
#endregion

#region Setters
func _set_prev_val(val: Variant):
	if prev_val == init_val: init_val = val
	prev_val = val

func _set_array(new_data: Array):
	time = new_data[0]
	object = new_data[1]
	property = new_data[2]
	init_val = new_data[3]
	value = new_data[4]
	duration = new_data[5]
	transition = new_data[6]
	ease = new_data[7]
	
func duplicate() -> KeyInterpolator:
	var new_key: KeyInterpolator = KeyInterpolator.new()
	new_key.array = array.duplicate()
	return new_key
#endregion
