
@icon("res://icons/note.svg")

##The Note Base Class
extends "res://source/objects/Sprite/Sprite.gd"



const NoteSplash = preload("res://source/objects/Notes/NoteSplash.gd")
const Note = preload("res://source/objects/Notes/Note.gd")
const StrumNote = preload("res://source/objects/Notes/StrumNote.gd")

const directions: PackedStringArray = ['left','down','up','right']
const note_colors: PackedStringArray = ['Purple','Blue','Green','Red']
const _rating_string: PackedStringArray = ['marvellous','sick','good','bad','shit']

const _ratings_length: int = 4 #The same as _rating_string.size()

const key_actions: Array[PackedStringArray] = [
	[""],
	["note_left"],
	["note_left","note_right"],
	["note_left","note_center","note_right"],
	["note_left","note_down","note_up","note_right"],
	["note_left","note_down","note_center","note_up","note_right"],
]
static var _rating_offset: Array[float] = [-1.0,45.0,130.0,150.0]

static var noteStylesLoaded: Dictionary = {}

static var miraculousRating: bool = false

##The Note prefix, allowing to changing the name of the xml to add animations to the note.
var styleData: Dictionary
var styleName: String

##If [code]true[/code], the note will follow the x position from his [member strum].
var copyX: bool = true 

##If [code]true[/code], the note will follow the y position from his [member strum].
var copyY: bool = true

##If [code]true[/code], the note will follow the alpha from his [member strum].
var copyAlpha: bool = true

var _is_processing: bool = true

var downscroll: bool = ClientPrefs.data.downscroll ##If [code]true[/code], the note will come from top.

var isSustainNote: bool = false ##If the note is a Sustain. See also ["source/objects/NoteSustain.gd"]
var isEndSustain: bool = false

var hitHealth: float = 0.023 ##the amount of life will gain by hitting the note
var missHealth: float = 0.0475##the amount of life will lose by missing the note

var strumConfirm: bool = true ##If [code]true[/code], the strum will play animation when hit the note
var strumTime: float = 0.0 ##Position of the note in the song

var strumNote: StrumNote ##Strum Parent that note will follow

var noteColor: StringName = '' ## Note color name

var wasHit: bool = false
var judgementTime: float = INF##Used in ModchartEditor

var noteData: int = 0: ##Note Direction
	set(dir):
		noteData = dir
		noteColor = note_colors[noteData]

##The group the note will be added when spawned,
##see [method "source/states/StrumState.gd".spawnNote] in his script for more information.[br][br]
##[b]Tip:[/b] Is recommend to set this value as a [SpriteGroup]!! 
var noteGroup: Node

var distance: float = 0.0  ##The distance between the note and the strum
var canBeHit: bool = false  ##If the note can be hit
var lowPriority: bool = false ##if two notes are close to the strum and this variable is true, the game will prioritize the another one

##Is Pixel Note
var isPixelNote: bool = false: set = setPixelNote

##Note Type
var noteType: StringName = ""

var texture: String: set = setTexture ##Note Texture
var _real_texture: String = ''

var autoHit: bool = false
var noAnimation: bool = false ##When hit the note and this variable is [code]true[/code], the character will dont play animation
var mustPress: bool = false ##player note

var missOffset: float = -150.0 ##The time distance to miss the note

var missed: bool = false ##Detect if the note is missed

var multSpeed: float = 1.0:##Note Speed multiplier
	set(value):
		if multSpeed == value: return
		multSpeed = value
		_update_note_speed() 

var multAlpha: float = 1.0 ##Note Alpha multiplier

var multScale: Vector2 = Vector2.ONE

var blockHit: bool = false ##Unable to hit the note

var offsetX: float = 0 ##Distance on x axis
var offsetY: float = 0 ##Distance on y axis

var animSuffix: StringName = ''

var ratingMod: int = 0 ## The Rating of the note in [int]. [param 0 = nothing, 1 = sick, 2 = good, 3 = bad, 4 = shit]
var rating: StringName = '' ## The Rating ot the note in [String]. [param sick, good, bad, shit]

var ratingDisabled: bool = false ##Disable Rating. If [code]true[/code], the rating will always be "sick".

var gfNote: bool = false ##Is GF Note
var ignoreNote: bool = false ##if is opponent note or a bot playing, they will ignore this note



var sustainLength: float = 0.0 ##The Sustain time

var noteSpeed: float = 1.0: ##Note Speed
	set(value):
		if noteSpeed == value: return
		noteSpeed = value
		_update_note_speed()
	
var _real_note_speed: float = 1.0
#var rgbShader: ShaderMaterial = RGBPalette.new()

## Note Splash Data.[br]
##A [Dictionary] that can contain: {[br]
##[code]disabled[/code]: Disable splash for this  note.[br]
##[code]scale[/code]: Splash Scale(default: Vector2.ONE)[br]
##[code]prefix[/code]: Splash prefix[br]
##[code]type[/code]: Splash type(default: "noteSplash")[br]
##[code]style[/code]: Splash Style Json(default: "NoteSplashes")[br]
##[code]parent[/code]: Splash parents, can be used to change splash camera(default: null)[br][br]
##}
var noteSplashData: Dictionary = { 
	'disabled': false,
	'prefix': '',
	'type': 'noteSplash',
	'style': 'NoteSplashes',
	'parent': null
}

func _init(data: int = 0) -> void:
	noteData = data
	_load_data()
	super._init(null,true)
	_update_note_speed()

##Update Note Position
func updateNote() -> void:
	distance = getNoteDistance()
	detectCanHit(distance)
	followStrum()

func detectCanHit(_distance: float) -> void:
	var limit = _rating_offset[3]
	canBeHit = not blockHit and _distance >= -limit and _distance <= limit
	if !canBeHit: return

func followStrum(strum: StrumNote = strumNote) -> void:
	if !strum: return
	var posX: float = strumNote.x + offsetX
	var posY: float = strumNote.y + offsetY + distance * strumNote.multSpeed
	
	if strumNote.direction:
		if copyX: x = lerpf(posX,posY,cos(strumNote.direction))
		if copyY: y = lerpf(posY,posX,sin(strumNote.direction))
	else:
		if copyX: x = posX
		if copyY: y = posY
	
	if copyAlpha: modulate.a = strumNote.modulate.a * multAlpha

##Reset Note values when spawned.
func resetNote() -> void: #Replaced in NoteSustain
	judgementTime = INF
	wasHit = false
	_is_processing = true
	missed = false
	offset = Vector2.ZERO
	noteSplashData.parent = null
	
func reloadNote() -> void: ##Reload Note Texture
	animation.clearLibrary()
	_animOffsets.clear()
	offset = Vector2.ZERO
	
	var prefix = styleData.data.get(directions[noteData])
	if prefix:
		animation.addAnimByPrefix('static',prefix.prefix,prefix.get('fps',24.0),true)
	else:
		image.region_rect.size = imageSize/Vector2(Conductor.keyCount,5)
		animation.addFrameAnim('static',[noteData])
		
	var note_scale = styleData.get('scale',0.7)
	setGraphicScale(Vector2(note_scale,note_scale))

func loadFromStyle(noteStyle: String):
	styleName = noteStyle
	styleData = getStyleData(noteStyle)
	if !styleData: return
	isPixelNote = styleData.get('isPixel',false)
	texture = styleData.assetPath

func killNote():
	_is_processing = false
	kill()

func setPixelNote(isPixel: bool) -> void:
	antialiasing = !isPixel
	isPixelNote = isPixel

func setTexture(_new_texture: String):
	var real_tex = getNoteTexture(_new_texture, isPixelNote)
	if _real_texture == real_tex: return
	_real_texture = real_tex
	texture = _new_texture
	
	image.texture = Paths.imageTexture(real_tex)
	reloadNote()

func getNoteDistance() -> float:
	return (strumTime - Conductor.songPositionDelayed) * _real_note_speed


func _load_data() -> void: 
	noteSplashData.prefix = directions[noteData]+'Splashes'


func _update_note_speed() -> void: _real_note_speed = noteSpeed * 0.45 * multSpeed

#region Statics Funcs
static func getStyleData(style: String):
	return Paths.loadJson('data/notestyles/'+style).get('notes',{})
	
static func getNoteTexture(_texture: String, is_pixel: bool = false) -> String:
	if !_texture: _texture = 'noteSkins/NOTE_assets'
	if is_pixel and not _texture.begins_with('pixelUI/'): return 'pixelUI/'+_texture
	return _texture

##Return the closer note from his [member Note.strumNote]
static func detectCloseNote(array: Array):
	if !array:return null
	
	var closeNote = array.pop_front()
	for i in array:
		if not i: continue
		if absf(i.distance) < absf(closeNote.distance): closeNote = i 
	return closeNote

##Returns the keys to hit the note, depending of the [param keyCount].
static func getNoteAction(keyCount: int = Conductor.keyCount) -> Array: return key_actions[keyCount]
	

##Detect if [param note1] is the same as [param note2].
static func sameNote(note1: Note, note2: Note) -> bool:
	return note1 and note2 and \
	note1.strumTime == note2.strumTime and \
	note1.noteData == note2.noteData and \
	note1.mustPress == note2.mustPress and \
	note1.isSustainNote == note2.isSustainNote and \
	note1.noteType == note2.noteType

##Returns the note colors, depending of the [param keyCount].
static func get_note_colors(keyCount: int = Conductor.keyCount) -> PackedStringArray:
	match keyCount:
		2: return ['Purple','Red']
		3: return ['Purple','Blue','Red']
		5: return ['Purple','Blue','White','Green','Red']
		6: return ['Purple','Blue','Yellow','Pink','Green','Red']
		7: return ['Purple','Blue','Yellow','White','Pink','Green','Red']
		8: return ['Purple','Blue','Green','Red','White','Pink','Green','Red']
		_: return ['Purple','Blue','Green','Red']
#endregion
