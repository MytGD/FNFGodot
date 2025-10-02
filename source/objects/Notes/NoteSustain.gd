extends "res://source/objects/Notes/Note.gd"
##Sustain Base Note Class

const NoteHit = preload("res://source/objects/Notes/NoteHit.gd")

var isBeingDestroyed: bool = false
var hit_action: String: 
	get(): return noteParent.hit_action if noteParent else ''
	
var noteParent: NoteHit ##Sustain's Note Parent

var sus_size: float = 0
func _init(data: int, length: float = 0) -> void:
	isSustainNote = true
	sustainLength = length
	super._init(data)


func reloadNote() -> void: ##Reload Note Texture
	animation.clearLibrary()
	_animOffsets.clear()
	offset = Vector2.ZERO
	
	var prefix = styleData.data.get((directions[noteData]+'End') if isEndSustain else directions[noteData])
	var anim_name = 'holdEnd' if isEndSustain else 'hold'
	if prefix: 
		animation.addAnimByPrefix(anim_name,prefix,24,true)
	else:
		image.region_rect.size = Vector2(imageSize.x/(Conductor.keyCount*2),imageSize.y)
		var data = noteData*2
		animation.addFrameAnim(anim_name,[(data+1) if isEndSustain else data])
	var note_scale = styleData.get('scale',0.7)
	setGraphicScale(Vector2(note_scale,note_scale))

func updateNote() -> void:
	if !isEndSustain: 
		var rect = animation.curAnim.curFrameData.get('region_rect')
		if rect: scale.y = sus_size/rect.size.y
	distance = getNoteDistance()
	if isBeingDestroyed: updateSustain();
	else: detectCanHit(distance)
	followStrum()
	
func updateSustain():
	if distance > 0.0: return
	var fill = distance/scale.y
	var current_sus_rect = animation.curAnim.curFrameData.get('region_rect')
	if current_sus_rect:
		var sustain_size = current_sus_rect.size.y + fill
		image.region_rect.position.y = current_sus_rect.position.y - fill
		image.region_rect.size.y = sustain_size
	distance = 0.0
	
	if image.region_rect.size.y <= 0.0:  kill(); _is_processing = false

func detectCanHit(_distance: float):
	canBeHit = noteParent and noteParent.wasHit and not isBeingDestroyed and _distance <= 30.0
	
func resetNote() -> void:
	super.resetNote()
	var rect = animation.curAnim.curFrameData.get('region_rect')
	if rect: image.region_rect = rect
	
	canBeHit = false
	isBeingDestroyed = false
	offsetX = 32.0 if isPixelNote else 38.0
	offsetY = 53.0
	
func killNote() -> void:
	canBeHit = false
	isBeingDestroyed = true

##Update the Note position from the his [param strumNote].
func followStrum(strum: StrumNote = strumNote) -> void:
	super.followStrum(strum)
	angle = strumNote.direction

func _update_note_speed() -> void:
	super._update_note_speed()
	sus_size = sustainLength * _real_note_speed

func _load_data() -> void:
	super._load_data()
	noteSplashData.style = 'HoldNoteSplashes'
	noteSplashData.type = 'holdNoteCover'
	noteSplashData.prefix = directions[noteData]

static func getStyleData(style: String):
	return Paths.loadJson('data/notestyles/'+style,false).get('holdNote',{})
	
static func getNoteTexture(_texture: String, is_pixel: bool = false) -> String:
	var tex = super.getNoteTexture(_texture,is_pixel)
	if is_pixel and not tex.ends_with('ENDS'): return tex+'ENDS'
	return tex

func set_pivot_offset(value: Vector2) -> void:
	value.y = 0
	image.pivot_offset.y = 0
	super.set_pivot_offset(value)
