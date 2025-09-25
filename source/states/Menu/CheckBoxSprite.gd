##A Check Box Class.
##
##A Example of code using a [Dictionary]: [codeblock]
##var data = {'enable': false}
##var checkBox = CheckBoxSprite.new()
##
##checkBox.object_to_set = data
##checkBox.variable = 'enable'
##checkBox.value = true #Automatically changes the data.enable.
##[/codeblock]
##A Example of code using a [Array]: [codeblock]
##var data = ['Object',Vector2.ZERO,false]
##var checkBox = CheckBoxSprite.new()
##
##checkBox.object_to_set = data
##checkBox.variable = 2 #The array index.
##checkBox.value = true #Changes data[2] to true.
##[/codeblock]

extends "res://source/objects/Sprite/SpriteAnimated.gd"

signal toggled(toogle_on: bool)
##Boolean.
var value: bool:
	set(boolean):
		if boolean == value: return
		value = boolean
		if value: animation.play('selection',true)
		else: animation.play_reverse('selection',true)
		toggled.emit(value)

var offset: Vector2 = Vector2.ZERO:
	set(value):
		position -= value - offset
		offset = value
func _init():
	super._init()
	image.texture = Paths.imageTexture('checkboxThingie')
	animation.animation_finished.connect(func(anim):
		if anim == 'selection': 
			animation.play('unselected' if animation.curAnim.reverse else 'selected')
	)
	animation.animation_started.connect(func(anim):
		match anim:
			'selection','selected': offset = Vector2(10,50)
			_: offset = Vector2.ZERO
	)
	animation.addAnimByPrefix('unselected','Check Box unselected')
	animation.addAnimByPrefix('selection','Check Box selecting animation')
	animation.addAnimByPrefix('selected','Check Box selected')
	
	animation.curAnim.curFrame = animation.curAnim.maxFrames
