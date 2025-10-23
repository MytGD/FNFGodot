@tool
class_name DropdownBox extends Button

@export var texts: PackedStringArray = []

var separator: VBoxContainer = VBoxContainer.new()
var text_label: Label = Label.new()

var text_name: String
func _init():
	toggle_mode = true
	toggled.connect(show_separator)
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_FILL
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_label.mouse_filter = Control.MOUSE_FILTER_STOP
	text_label.gui_input.connect(label_input)
	flat = true
	add_child(text_label)
	text_label.show_behind_parent = true
	separator.show_behind_parent = true
	add_child(separator)
	resized.connect(update_separator_pos)

func show_separator(show: bool = false):
	separator.visible = show
	update_text()

func _ready():
	update_text()
	update_texts()
	update_separator_pos()
	
func update_separator_pos():
	separator.position = Vector2(30,text_label.size.y+6)

func set_texts(_texts: PackedStringArray) -> void:
	texts = _texts
	update_texts()
	
func update_texts():
	for i in separator.get_children(): i.queue_free()
	for i in texts:
		var H_Separator = HSeparator.new()
		separator.add_child(H_Separator)
		
		var label = Label.new()
		label.text = i
		label.name = i
		separator.add_child(label)

func update_text():
	var label_text = text_name
	if !label_text:
		label_text = name
	if separator.visible:
		custom_minimum_size.y = 24+separator.get_minimum_size().y
		text_label.text = 'v '+label_text
	else:
		custom_minimum_size.y = 24
		text_label.text = '> '+label_text

func label_input(event: InputEvent):
	if event is InputEventMouseButton and !event.pressed and event.button_index == 1:
		button_pressed = !separator.visible
		
func _notification(what: int) -> void:
	if what == NOTIFICATION_PATH_RENAMED:
		update_text()
