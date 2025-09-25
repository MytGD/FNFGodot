@tool
extends Label

signal value_changed(value: float) ##Called when the value changes.
signal value_added(value: float) ##Called when the value changes, returns the value added

@export var min: float = 0

##The max value. If [code]0[/code], the value can be ilimited.
@export var max: float:
	set(value):
		max = value
		value = value

@export var value: float = 0.0:
	set(_value):
		if limit_min: _value = max(_value,min)
		if limit_max: _value = min(_value,max)
		
		var emit: bool = _call_emit and value != _value
		var difference: float = _value - value
		value = _value
		update_value_text()
		if emit:
			value_changed.emit(value)
			value_added.emit(difference)
			
			
var _call_emit: bool = true
@export var limit_min: bool = false
@export var limit_max: bool = false

@onready var value_text := $Value
@onready var _value_nodes: Array = [$Value,$ButtonUp,$ButtonDown]
@export var value_to_add: float = 1.0##The value that will be added when the arrows are been pressed.

@export var shift_value: float = 1.0##The value to add when pressing SHIFT key([param KEY_SHIFT])
var _cur_min_size: Vector2 = Vector2.ZERO

@export var int_value: bool = false:
	set(value):
		int_value = value
		update_value_text()

func _ready():
	update_value_text()

func addValue() -> void:
	value += shift_value if Input.is_action_pressed("shift") else value_to_add

func subValue() -> void:
	value -= shift_value if Input.is_action_pressed("shift") else value_to_add

func _draw() -> void:
	var min_size = get_minimum_size()
	size = min_size
	
	var width: float = size.x + 8
	for i in _value_nodes:
		i.position.x = width
		width += i.size.x + 2
		i.position.y = size.y/2.0 - 20
	$Value.position.x -= 4
func _on_value_text_submitted(new_text: String) -> void:
	value = float(new_text)
	value_text.release_focus()

func _on_value_text_changed(new_text: String) -> void:
	var tex: String = ''
	for i in new_text:
		if i == '.' or i == '-' or i >= '0' and i <= '9':
			tex += i
	if tex != new_text:
		value = float(tex)

func set_value_no_signal(_value: float):
	_call_emit = false
	value = _value
	_call_emit = true
	
func update_value_text():
	if !value_text: return
	var value_int = int(value)
	if int_value or value_int == value: value_text.text = str(value_int)
	else: value_text.text = str(value)
