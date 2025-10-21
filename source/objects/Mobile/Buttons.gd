extends Node

var positions_type: int = 0
static var buttons_positions: Dictionary = {
	KEY_UP: Vector2(),
	KEY_DOWN: Vector2(),
	KEY_LEFT: Vector2(),
	KEY_RIGHT: Vector2(),
	KEY_ENTER: Vector2()
}

var buttons: Array = []


const button_texts: Dictionary = {
	KEY_UP: '>',
	KEY_DOWN: '<',
	KEY_LEFT: '<',
	KEY_RIGHT: '>',
	KEY_ENTER: 'A',
	KEY_BACK: 'B',
	KEY_SHIFT: 'Z'
}
class ButtonMobile extends Sprite2D:
	var key: int = KEY_UP
	
	var text = Label.new()
	var pressed: bool = false:
		set(value):
			if pressed == value:
				return
			if pressed:
				InputUtils.set_key_just_pressed_and_just_pressed(key)
				modulate.a = 1
			else:
				InputUtils.set_key_just_released(key)
				modulate.a = 0.2
			pressed = value
		
	func _init(button_key: int = 0):
		texture = Paths.imageTexture('button')
		
		add_child(text)
		if texture:
			text.size = texture.get_size()
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		if button_key in button_texts:
			text.text = button_texts[button_key]
		
		key = button_key
		
	func _process(delta: float):
		pressed = InputUtils.is_touching_object(self)
	

func _ready():
	for i in buttons_positions:
		var button = ButtonMobile.new()
		button.position = buttons_positions[i]
		buttons.append(button)
		add_child(button)
