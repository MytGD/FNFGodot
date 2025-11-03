extends FunkinSprite

const Note = preload("res://source/objects/Notes/Note.gd")
const directions: PackedStringArray = ['left','down','up','right']
const note_colors: PackedStringArray = ['Purple','Blue','Green','Red']

var styleData: Dictionary
var styleName: String: set = setStyleName

var noteData: int = 0: set = setNoteData ##The direction of this Note.

var noteColor: StringName = '' ## The color name of this Note.

#region Note Styles
var isPixelNote: bool = false: set = setPixelNote ##Is Pixel Note
var texture: String: set = setTexture ##Note Texture
var _real_texture: String = ''
#endregion

func reloadNote() -> void: ##Reload the Note animation and his texture.
	animation.clearLibrary()
	_animOffsets.clear()
	offset = Vector2.ZERO
	
	var dir = directions[noteData]
	var prefix = styleData.data.get(dir)
	if prefix:
		var fps = prefix.get('fps',24.0)
		animation.addAnimByPrefix('static',prefix.prefix,fps,true)
	else:
		image.region_rect.size = imageSize/Vector2(Conductor.keyCount,5)
		animation.addFrameAnim('static',[noteData + Conductor.keyCount])
		
	var note_scale = styleData.get('scale',0.7)
	setGraphicScale(Vector2(note_scale,note_scale))

func loadFromStyle(noteStyle: String):
	styleName = noteStyle
	if !styleData: return
	
	isPixelNote = styleData.get('isPixel',false)
	texture = styleData.assetPath

#region Setters
func setStyleName(_name: String) -> void:
	styleName = _name
	styleData = getStyleData(_name)
	
func setNoteData(_data: int):
	noteData = _data
	noteColor = note_colors[noteData]

func setPixelNote(isPixel: bool) -> void:
	texture_filter = TEXTURE_FILTER_NEAREST if isPixel else TEXTURE_FILTER_PARENT_NODE 
	isPixelNote = isPixel


func setTexture(_new_texture: String) -> void:
	var real_tex = getNoteTexture(_new_texture, isPixelNote)
	if _real_texture == real_tex: return
	_real_texture = real_tex
	texture = _new_texture
	
	image.texture = Paths.imageTexture(real_tex)
	reloadNote()

#region Static Funcs
static func getStyleData(style: String): return Paths.loadJson('data/notestyles/'+style).get('notes',{})
	
static func getNoteTexture(_texture: String, is_pixel: bool = false) -> String:
	if !_texture: _texture = 'noteSkins/NOTE_assets'
	if is_pixel and not _texture.begins_with('pixelUI/'): return 'pixelUI/'+_texture
	return _texture
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
