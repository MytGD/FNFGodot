const KeyNode = preload("res://source/states/Modchart/KeyNode.gd")
var key_node: KeyNode #Setted in ModchartEditor

#[position, object_tag, parameter, value, first_value, duration, transition, easing]
var array: Array = []
var keys_in_same_line: Array = []

var time: float: set = set_time
var object_type: int #See ModchartState.PROPERTY_TYPES
var object_tag: StringName = ''
var parameter: StringName: set = set_parameter

var value: Variant: set = set_value
var init_value: Variant: set = set_init_value
var default_object_value: Variant

var trans: Tween.TransitionType: set = set_trans
var ease: Tween.EaseType: set = set_ease
var duration: float = 0: set = set_duration
var end_time: float = 0.0
var step: float = 0.0

var add_at_previews_value: bool = false


var _cur_value = null

func update_step() -> void:
	step = Conductor.get_step(time)
	_update_end_time()

func update_data() -> void:
	time = array[0]
	object_tag = array[1]
	parameter = array[2]
	value = array[3]
	init_value = array[4]
	duration = array[5]
	trans = array[6]
	ease = array[7]
func _update_end_time() -> void:
	end_time = time + duration*1000
	
#region Setters
func set_time(value: float) -> void:
	time = value
	array[0] = value
	_update_end_time()
	update_step()
	
func set_parameter(new_parameter: StringName) -> void:
	parameter = new_parameter
	array[2] = new_parameter
	
func set_value(_new_value: Variant) -> void:
	value = _new_value
	array[3] = _new_value

func set_init_value(value: Variant) -> void:
	init_value = value
	array[4] = value

func set_duration(value: float) -> void:
	duration = value
	array[5] = value
	_update_end_time()
	if key_node:
		key_node.queue_redraw()

func set_trans(value: Tween.TransitionType) -> void:
	trans = value
	array[6] = value
	
func set_ease(_ease: Tween.EaseType) -> void:
	ease = _ease
	array[7] = _ease
#endregion
