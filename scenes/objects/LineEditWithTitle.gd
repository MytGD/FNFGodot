@tool
extends Label

@export var edit_text: String: set = set_edit_text 
@onready var line_edit: LineEdit = $LineEdit

var _edit_text_sets_line_edit_text: bool = true
signal edit_text_changed(_text: String)
func _ready() -> void:
	minimum_size_changed.connect(_update_pos)
	line_edit.text = edit_text
	line_edit.text_submitted.connect(func(_t):
		_edit_text_sets_line_edit_text = false
		edit_text = _t
		_edit_text_sets_line_edit_text = true
	)
	_update_pos()
	
func _update_pos(): line_edit.position.x = get_minimum_size().x

func set_edit_text(new_text: String) -> void:
	edit_text = new_text
	edit_text_changed.emit(new_text)
	if line_edit and _edit_text_sets_line_edit_text: line_edit.text = new_text
