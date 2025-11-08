@icon("res://icons/letter.svg")
extends Sprite2D
const Anim = preload("res://source/general/animation/Anim.gd")

var imageFile: StringName:
	set(path):
		texture = Paths.texture(path)

		imageFile = path

var _frame_offset: Vector2 = Vector2.ZERO:
	set(value):
		position = _position + value
		_frame_offset = value

var _position: Vector2 = Vector2.ZERO:
	set(value):
		_position = value
		position = value + _frame_offset
		

var pivot_offset: Vector2 = Vector2.ZERO
var animation: Anim = Anim.new()

var letter: StringName = '': set = set_letter

var suffix: String = ' bold instance 1'
func _init(imagePath: StringName = ''):
	centered = false
	region_enabled = true
	animation.image = self
	if imagePath: imageFile = imagePath

func set_letter(_letter: StringName):
	var prefix = _letter.to_lower()+suffix
	letter = _letter
	animation.addAnimByPrefix('anim',prefix,24,true)

func _process(delta: float) -> void:
	animation.curAnim.process_frame(delta)
