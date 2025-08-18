extends "res://source/objects/AlphabetText/AlphabetText.gd"

var index: int = -1: set = set_index
var variables: Dictionary = {}
var keys: Array

signal index_changed(value: Variant)
signal index_changed_key(value: Variant)
signal index_changed_text(value: Variant)
func set_index_keys(values: Dictionary):
	variables = values
	keys = values.keys()
	
func set_index(i: int) -> void:
	if i >= keys.size():i = 0
	elif i < 0:  i = keys.size()-1
	if i == index: return
	index = i
	var key_text = variables[keys[i]]
	text = str(key_text)
	index_changed.emit(i)
	index_changed_key.emit(keys[i])
	index_changed_text.emit(key_text)
