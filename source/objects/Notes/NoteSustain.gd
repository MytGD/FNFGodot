extends "res://source/objects/Notes/NoteSustainBase.gd"

var sus_size: float = 0
##Sustain Note Class
func reloadNote() -> void:
	animation.clearLibrary()
	if isPixelNote:
		image.region_rect.size = imageSize/Vector2(Conductor.keyCount,2)
		animation.addFrameAnim('hold',[noteData])
		setGraphicScale(Vector2(6,6))
	else:
		animation.addAnimByPrefix('hold',prefix.get(noteColor.to_lower()+'Hold',''),24,true)
		setGraphicScale(Vector2(0.7,0.7))
	resetNote()
func updateNote():
	if isPixelNote:
		scale.y = sus_size/animation.curAnim.curFrameData.region_rect.size.y
	else:
		scale.y = sus_size/(animation.curAnim.curFrameData.region_rect.size.y-1)
	super.updateNote()

func _load_data() -> void:
	super._load_data()
	noteSplashData.texture = 'noteSplashes/hold/holdCover'+noteColor
	noteSplashData.prefix = 'holdCover'+noteColor
	noteSplashData.looped = true
	
func _update_note_speed() -> void:
	super._update_note_speed()
	sus_size = sustainLength * _real_note_speed
