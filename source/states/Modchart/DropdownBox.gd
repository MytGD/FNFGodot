extends Button

var texts: PackedStringArray = []
var text_label: Label = Label.new()
var separator: VBoxContainer = VBoxContainer.new()

func _init():
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_FILL
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	flat = true
	
func _ready():
	add_child(text_label)
	add_child(separator)
	separator.position = Vector2(30,text_label.get_line_height()+5)
	update_text()
	update_texts()
	separator.visible = button_pressed
	toggled.connect(func(toggled_on):
		separator.visible = toggled_on
		update_text()
	)
	
func set_texts(_texts: PackedStringArray) -> void:
	texts = _texts
	update_texts()
	
func update_texts():
	for i in texts:
		var H_Separator = HSeparator.new()
		separator.add_child(H_Separator)
		
		var label = Label.new()
		label.text = i
		label.name = i
		separator.add_child(label)

func update_text():
	if button_pressed:
		custom_minimum_size.y = 24+separator.get_minimum_size().y
		text_label.text = 'v '+name
	else:
		custom_minimum_size.y = 24
		text_label.text = '> '+name
