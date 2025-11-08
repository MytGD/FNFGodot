@abstract
extends FunkinSprite
const Song = preload("uid://cerxbopol4l1g")
const Note = preload("uid://deen57blmmd13")
const directions: PackedStringArray = ['left','down','up','right']
const note_colors: PackedStringArray = ['Purple','Blue','Green','Red']

var styleData: Dictionary
var styleName: String: set = setStyleName

var noteData: int = 0: set = setNoteData ##The direction of this Note.

var noteColor: StringName = '' ## The color name of this Note.
var noteDirection: String = ''

#region Note Styles
var isPixelNote: bool = false: set = setPixelNote ##Is Pixel Note
var texture: String: set = setTexture ##Note Texture
#endregion


func setNoteRect(region: Rect2):
	image.region_rect = region
	image.pivot_offset = region.size/2.0
	pivot_offset = image.pivot_offset

func loadFromStyle(noteStyle: String):
	styleName = noteStyle
	if !styleData: return
	isPixelNote = styleData.get(&'isPixel',false)
	texture = styleData.assetPath

func reloadNote() -> void: ##Reload the Note animation and his texture.
	offset = Vector2.ZERO
	
	var dir = directions[noteData]
	var data = styleData.data.get(dir)
	
	var note_scale: float = styleData.get('scale',0.7)
	if data:
		var prefix = data.get(&'prefix')
		if !prefix: return
		var fps = data.get(&'fps',24.0)
		animation.addAnimByPrefix(&'static',prefix,fps,true)
		note_scale = data.get('scale',note_scale)
	else: 
		var cut = imageSize/Vector2(Song.keyCount,5)
		setNoteRect(
			Rect2(
				Vector2(cut.x*noteData,cut.y),
				cut
			)
		)
	
	
	setGraphicScale(Vector2(note_scale,note_scale))

#region Setters
func setStyleName(_name: String) -> void: styleName = _name; styleData = getStyleData(_name)

func setNoteData(_data: int) -> void: noteData = _data; noteColor = note_colors[_data]; noteDirection = directions[_data]

func setPixelNote(isPixel: bool) -> void:
	antialiasing = !isPixel 
	isPixelNote = isPixel

func setTexture(_new_texture: String) -> void:
	if texture == _new_texture: return
	texture = _new_texture
	image.texture = Paths.texture(texture)
	reloadNote()

func _on_texture_changed() -> void: super._on_texture_changed(); animation.clearLibrary(); _animOffsets.clear()

#region Static Funcs
static func getStyleData(style: String): return Paths.loadJson('data/notestyles/'+style).get(&'notes',{})

static func sameNote(note1: Note, note2: Note) -> bool: ##Detect if [param note1] is the same as [param note2].
	return note1 and note2 and \
	note1.strumTime == note2.strumTime and \
	note1.noteData == note2.noteData and \
	note1.mustPress == note2.mustPress and \
	note1.isSustainNote == note2.isSustainNote and \
	note1.noteType == note2.noteType

##Returns the note colors, depending of the [param keyCount].
static func get_note_colors(keyCount: int = Song.keyCount) -> Array:
	match keyCount:
		2: return [&'Purple',&'Red']
		3: return [&'Purple',&'Blue',&'Red']
		5: return [&'Purple',&'Blue',&'White',&'Green',&'Red']
		6: return [&'Purple',&'Blue',&'Yellow',&'Pink',&'Green',&'Red']
		7: return [&'Purple',&'Blue',&'Yellow',&'White',&'Pink',&'Green',&'Red']
		8: return [&'Purple',&'Blue',&'Green',&'Red',&'White',&'Pink',&'Green',&'Red']
		_: return [&'Purple',&'Blue',&'Green',&'Red']
