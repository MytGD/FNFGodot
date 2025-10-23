extends Button
var line_edit = LineEdit.new()
var media: Resource: set = set_media
func _init() -> void:
	focus_mode = Control.FOCUS_CLICK
	line_edit.position.x = 30
	line_edit.flat = true
	line_edit.focus_mode = Control.FOCUS_NONE
	line_edit.text_changed.connect(_line_edit_text_changed)
	line_edit.text_submitted.connect(func(_t): line_edit.focus_mode = Control.FOCUS_NONE)
	line_edit.expand_to_text_length = true
	add_child(line_edit)

func _line_edit_text_changed(new_text: String):
	if !new_text: line_edit.text = line_edit.placeholder_text

func set_media(_media: Resource):
	media = _media
	line_edit.placeholder_text = _media.resource_name.get_file()

func _line_grab_focus():
	line_edit.focus_mode = Control.FOCUS_CLICK
	line_edit.grab_focus()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_F2: _line_grab_focus()
	elif event is InputEventMouseButton:
		if event.double_click and event.button_index == 1: _line_grab_focus()
