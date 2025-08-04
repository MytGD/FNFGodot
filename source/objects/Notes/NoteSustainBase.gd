extends "res://source/objects/Notes/Note.gd"
##Sustain Base Note Class

const NoteHit = preload("res://source/objects/Notes/NoteHit.gd")

var isBeingDestroyed: bool = false
var hit_action: String: 
	get(): return noteParent.hit_action if noteParent else ''
		
var isEndSustain: bool = false
var noteParent: NoteHit ##Sustain's Note Parent

func _init(data: int, length: float = 0) -> void:
	isSustainNote = true
	sustainLength = length
	super._init(data)
	
func updateNote() -> void:
	distance = getNoteDistance()
	if isBeingDestroyed: updateSustain();
	else: detectCanHit(distance)
	followStrum()
	
func updateSustain():
	if distance > 0.0: return
	var fill = distance/scale.y
	var current_sus_rect = animation.curAnim.curFrameData.region_rect
	
	var sustain_size = current_sus_rect.size.y + fill
	
	image.region_rect.position.y = current_sus_rect.position.y - fill
	image.region_rect.size.y = sustain_size
	distance = 0.0
	
	if image.region_rect.size.y <= 0.0:  kill(); _is_processing = false

func detectCanHit(_distance: float):
	canBeHit = noteParent and noteParent.wasHit and not isBeingDestroyed and _distance <= 30.0
	
func resetNote() -> void:
	super.resetNote()
	image.region_rect = animation.curAnim.curFrameData.region_rect
	canBeHit = false
	isBeingDestroyed = false
	offsetX = 32.0 if isPixelNote else 38.0
	offsetY = 53.0
	
func killNote() -> void:
	canBeHit = false
	isBeingDestroyed = true

##Reload Note Texture
func reloadNote() -> void:
	animation.clearLibrary()
	if isPixelNote:
		image.region_rect.size = imageSize/Vector2(Conductor.keyCount,2)
		animation.addFrameAnim('holdend',[noteData + Conductor.keyCount])
		setGraphicScale(Vector2(6,6))
	else:
		animation.addAnimByPrefix('holdend',prefix.get(noteColor.to_lower()+'HoldEnd',''),24,true)
		setGraphicScale(Vector2(0.7,0.7))

##Update the Note position from the his [param strumNote].
func followStrum(strum: StrumNote = strumNote) -> void:
	var posX: float = strumNote.x + offsetX
	var posY: float = strumNote.y + offsetY + (-distance if downscroll else distance)
	
	if strumNote.direction:
		if copyX: x = lerpf(posX,posY,sin(strumNote.direction*0.017))#0.017 = PI/180.0
		if copyY: y = lerpf(posY,posX,sin(strumNote.direction*0.017))
	else:
		if copyX: x = posX
		if copyY: y = posY
	
	if copyAlpha: modulate.a = strumNote.modulate.a * multAlpha
	
	angle = strumNote.direction

func _load_data() -> void:
	super._load_data()
	noteSplashData.texture = 'noteSplashes/hold/holdCover'+noteColor
	noteSplashData.prefix = 'holdCoverEnd'+noteColor
				
static func getNoteTexture(_texture: String, is_pixel: bool = false) -> String:
	var tex = super.getNoteTexture(_texture,is_pixel)
	if is_pixel and not tex.ends_with('ENDS'): return tex+'ENDS'
	return tex

func set_pivot_offset(value: Vector2) -> void:
	value.y = 0
	image.pivot_offset.y = 0
	super.set_pivot_offset(value)
