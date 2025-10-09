extends "res://source/objects/AlphabetText/AlphabetText.gd"

var value: int = -1: set = set_index
var key_value: Variant: set = set_key_index
var variables: Dictionary = {}

signal index_changed(value: Variant)
signal index_changed_key(value: Variant)
signal index_changed_text(value: Variant)
	
func set_index(i: int) -> void:
	var keys = variables.keys()
	if !keys: return
	if i >= keys.size():i = 0
	elif i < 0:  i = keys.size()-1
	if i == value: return
	value = i
	key_value = keys[i]
	index_changed.emit(i)
	index_changed_key.emit(keys[i])
	
func set_index_from_key(key: Variant):
	value = variables.keys().find(key)
func set_key_index(value: Variant):
	key_value = value
	var key_text = variables[value]
	index_changed_text.emit(key_text)
	text = str(key_text)
