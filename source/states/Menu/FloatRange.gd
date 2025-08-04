extends "res://source/general/animation/SpriteBase.gd"

##The Float Value.
var value: float:
	set(number):
		value = clamp(number,min_value,max_value)
		if object_to_set and variable != null:
			FunkinGD.setProperty(variable,number,object_to_set)
		
##The [Object] that have the variable. Can also be a [Array] or a [Dictionary].
var object_to_set: Object

##Variable to set the float. Can be a [String]
##or a [int] if [member object_to_set] is a [Array]).[br][br]
##If is [String], 
##instead of using [code].[/code], use [code]:[/code], for example: 
##[code]"Node.position"[/code] to [code]"Node:position"[/code]
var variable: Variant:
	set(v):
		variable = v
		if !object_to_set:
			return
		animation.play('selected' if object_to_set.get_indexed(variable) else 'unselected')


var min_value: float = -9999
var max_value: float = 9999

var is_selected: bool:
	set(value):
		set_process_input(value)
		is_selected = value

var value_to_add: float = 1
func _ready():
	set_process_input(is_selected)
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				value += value_to_add
			KEY_DOWN:
				value -= value_to_add
