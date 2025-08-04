extends "res://source/objects/Sprite/SpriteAnimated.gd"
const Note = preload("res://source/objects/Notes/Note.gd")

static var keyCount: int = 4
static var chess_rect_size: Vector2 = Vector2(30,30)

var isPixelNote: bool = false
var sustain: ColorRect
var sustain_scale: float = 0.0:
	set(value):
		if sustain:
			sustain.scale.y = value
		sustain_scale = value

var strumTime: float = 0

var noteData: int: set = set_data

var note_color: String = ''

var noteType: StringName: set = set_type

var section_data: Array = [strumTime,noteData,sustainLength,''] #[strumTime, direction, sustain length, type]

var mustPress: bool = false

var sustainLength: float = 0.0:
	set(value):
		value = max(value,0.0)
		if value <= 0.0:
			value = 0.0
			if sustain:
				sustain.queue_free()
		else:
			if !sustain:
				sustain = ColorRect.new()
				sustain.position = Vector2(chess_rect_size.x/2.0 - 5,chess_rect_size.y)
				sustain.size.x = 10
				sustain.scale.y = sustain_scale
				add_child(sustain)
			sustain.size.y = value/Conductor.stepCrochet * chess_rect_size.y
		sustainLength = value
		section_data[2] = value


func _init(direction: int = 0):
	add_child(image)
	is_animated = true
	image.region_enabled = true
	image.centered = false
	noteData = direction
	image.item_rect_changed.connect(func():
		var size = image.region_rect.size
		image.scale = (chess_rect_size/size).min(Vector2(1,1))
	)

func reloadNote(image_texture: StringName = '') -> void:
	animation.clearLibrary()
	image.texture = Paths.imageTexture(Note.getNoteTexture(image_texture))
	animation.addAnimByPrefix('static',note_color,24,true)
	pivot_offset = Vector2.ZERO
	image.pivot_offset = Vector2.ZERO
	
func set_data(data: int) -> void:
	noteData = data
	section_data[1] = data
	note_color = Note.note_colors[data%keyCount].to_lower()
	
func set_type(type: StringName) -> void:
	if !type and section_data.size() > 3:
		section_data.remove_at(3)
	section_data.resize(4)
	section_data[3] = type
	noteType = type
