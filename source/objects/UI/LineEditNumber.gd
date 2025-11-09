@tool
extends LineEdit
@export var characters_allowed: PackedStringArray = ['0','1','2','3','4','5','6','7','8','9','-','.']

@export var min_value: float = -999999.0
@export var max_value: float = 999999.0

var value: float = 0.0: set = set_value

var int_value: bool = false
var _call_signal: bool = true
signal value_changed(value: float)
func _ready() -> void: 
	text = String.num(value)
	text_changed.connect(_on_text_changed)
	if int_value: characters_allowed.erase('.')

var _need_to_check_text_edit: bool = true

func _on_text_submitted(new_text: String): value = float(new_text);release_focus()

func _on_text_changed(new_text: String) -> void:
	if !is_editing() or !_need_to_check_text_edit: return
	var focus = has_focus()
	
	var text_replace: String = _check_text(new_text)
	if text_replace == new_text: return
	var last_column = caret_column
	value = float(text_replace)
	
	_need_to_check_text_edit = false
	text = text_replace
	_need_to_check_text_edit = true 	
	
	if focus: grab_focus(); caret_column = last_column

func _check_text(t: String) -> String:
	var new_text: String = ''
	for i in t: if i in characters_allowed: new_text += i
	return new_text
	
func set_value(_v: float) -> void:
	_v = clampf(_v,min_value,max_value)
	if _v == value: return
	value = _v
	text = String.num(value)
	if _call_signal and is_node_ready(): value_changed.emit(value)

func set_value_no_signal(_v: float) -> void:
	_call_signal = false
	set_value(_v)
	_call_signal = true
