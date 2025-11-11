extends "res://source/objects/AlphabetText/AlphabetText.gd"

var value: Variant = 0: set = set_value

var value_max: float = 999
var value_min: float = -999
var step: float = 0.1
var int_value: bool = false

var limit_max: bool = false
var limit_min: bool = false

signal value_changed(new_value: Variant)
func set_value(number: Variant) -> void:
	if limit_max and limit_min: number = clampf(number,value_min,value_max)
	elif limit_max: number = minf(number,value_max)
	elif limit_max: number = maxf(number,value_min)
	if number == value: return
	value = get_value(number)
	_update_text()
	value_changed.emit(value)
	
func _update_text(): text = String.num_int64(value) if int_value else String.num(value)

@warning_ignore("incompatible_ternary")
func add_value(): value += ceili(step) if int_value else step
@warning_ignore("incompatible_ternary")
func sub_value(): value -= ceili(step) if int_value else step

func get_value(val: Variant = value) -> Variant: 
	var value_int = int(val)
	if int_value or value_int == val: return value_int
	return val
	
func _ready() -> void: _update_text()
