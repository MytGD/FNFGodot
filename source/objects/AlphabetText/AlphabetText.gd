@icon("res://icons/alphabet.svg")
extends Node2D

const AnimatedLetter = preload("res://source/objects/AlphabetText/AnimatedLetter.gd")

enum Alignment{
	LEFT,
	CENTER,
	RIGHT
}
@export var text: String = '': set = set_text

@export var x: float = 0.0: set = set_x
@export var y: float = 0.0: set = set_y
@export var imageFile: String = 'alphabet'

var text_width: float = -1

var width: float = 0.0
var height: float = 0.0

var letters: Array = []

var letters_in_lines: Array = []

var alignment = Alignment.LEFT

@export var antialiasing: bool = true:
	set(value):
		antialiasing = value
		texture_filter = TextureFilter.TEXTURE_FILTER_PARENT_NODE if value else TextureFilter.TEXTURE_FILTER_NEAREST

var lettersPrefix: Dictionary = {}

signal text_changed(new_text: String)
func _init(curText: String = '', textWidth: float = -1.0):
	Paths.image(imageFile)
	if curText:
		text = curText
	text_width = textWidth
	
func set_text(newText: String):
	if newText == text:
		return
	text = newText

	for childs in get_children():
		remove_child(childs)
	
	var lastLetter: AnimatedLetter
	var curTextPos: float = 0.0
	var closeOrigin: float = 0.0
	
	var curHeight: float = 0.0
	
	var cur_width: float = 0.0
	
	
	var cur_line: int = 0
	letters_in_lines.clear()
	letters_in_lines.append([])
	for letter in newText:
		if letter == " ":
			curTextPos += closeOrigin * 1.5
			cur_width += closeOrigin * 1.5
			lastLetter = null
			continue
		var newLetter = AnimatedLetter.new(imageFile)
		#newLetter.image.texture = Paths.texture(imageFile,true)
		newLetter.animation.addAnimByPrefix('anim',letter.to_lower()+lettersPrefix.get(letter,' bold instance 1'),24,true)
		add_child(newLetter)
		if lastLetter:
			curTextPos = lastLetter.position.x
			closeOrigin = lastLetter.pivot_offset.x*2.0 + 5.0
			cur_width += closeOrigin
			
		if text_width != -1 and width >= text_width or letter == '\n':
			letters_in_lines.append([])
			cur_line += 1
			newLetter.position.x = 0
			curTextPos = 0
			height += curHeight
			cur_width = 0
			curHeight = max(curHeight,height + lastLetter._midpoint.y)
		
		if cur_width > width:
			width = cur_width
		newLetter._position = Vector2(curTextPos + closeOrigin,curHeight)
		lastLetter = newLetter
		letters.append(newLetter)
		letters_in_lines[cur_line].append(newLetter)
	text_changed.emit(text)
func update_letters_position():
	#Set Text Position
	for i in letters_in_lines:
		for letter in letters_in_lines[i]:
			pass
func set_x(newX):
	x = newX
	position.x = x
	
func set_y(newY):
	y = newY
	position.y = y
