extends "res://source/objects/AlphabetText/AlphabetText.gd"

var value: float = 0: set = set_value

var value_max: float = 999
var value_min: float = -999
var value_to_add: float = 0.1
var int_value: bool = false

var limit_max: bool = false
var limit_min: bool = false

signal value_changed(new_value: float)
func set_value(number: float) -> void:
	if limit_max and limit_min: number = clampf(number,value_min,value_max)
	elif limit_max: number = minf(number,value_max)
	elif limit_max: number = maxf(number,value_min)
	if number == value: return
	value = number
	text = str(get_value())
	value_changed.emit(number)

func get_value() -> Variant: 
	var value_int = int(value)
	if int_value or value_int == value: return value_int
	return value
func _ready() -> void:
	text = str(get_value())
