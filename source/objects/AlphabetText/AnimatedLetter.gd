@icon("res://icons/letter.svg")
extends SpriteAnimated

var imageFile: StringName:
	set(path):
		image.texture = Paths.imageTexture(path)
		imageFile = path

var _frame_offset: Vector2 = Vector2.ZERO:
	set(value):
		position = _position + value
		_frame_offset = value

var _position: Vector2 = Vector2.ZERO:
	set(value):
		position = value + _frame_offset
		_position = value
	
func _init(imagePath: StringName = ''):
	super._init()
	is_animated = true
	if imagePath: imageFile = imagePath
