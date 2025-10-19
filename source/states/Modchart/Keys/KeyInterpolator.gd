extends Object
const KeyInterpolator = preload("res://source/states/Modchart/Keys/KeyInterpolator.gd")
#Key Data
var time: float: set = _set_time
var length: float = 0.0

var object: Variant
var object_name: String
var property: String
var duration: float: set = _set_duration
var init_val: Variant: set = _set_init_val
var prev_val: Variant: set = _set_prev_val
var value: Variant: set = _set_value
var transition: Tween.TransitionType: set = _set_trans
var ease: Tween.EaseType: set = _set_ease

var array: Array = [
	time,
	init_val,
	value,
	duration,
	transition,
	ease
]: set = _set_array

var key_node: CanvasItem

#EditorProperties
var tween_started: bool = false

#region Data
func _set_time(_time: float):
	time = _time
	length = time + duration
	array[0] = _time

func _set_init_val(val: Variant):
	init_val = val
	array[1] = val
	
func _set_value(val: Variant):
	value = val
	array[2] = val

func _set_duration(_duration: float):
	duration = _duration
	array[3] = _duration
	length = time + duration
	if key_node: key_node.queue_redraw()
	
func _set_trans(_trans: Tween.TransitionType):
	transition = _trans
	array[4] = _trans
	
func _set_ease(_ease: Tween.EaseType):
	ease = _ease
	array[5] = ease
#endregion

#region Setters
func _set_prev_val(val: Variant):
	if prev_val == init_val: init_val = val
	prev_val = val

func _set_array(new_data: Array):
	time = new_data[0]
	init_val = new_data[1]
	value = new_data[2]
	duration = new_data[3]
	transition = new_data[4]
	ease = new_data[5]
	
func duplicate() -> KeyInterpolator:
	var new_key: KeyInterpolator = KeyInterpolator.new()
	new_key.array = array.duplicate()
	return new_key
#endregion
