extends Node
const Sparrow = preload("res://source/general/animation/Sparrow.gd")
const Atlas = preload("res://source/general/animation/Atlas.gd")
const Map = preload("res://source/general/animation/Map.gd")

const AnimationController = preload("res://source/general/animation/AnimationController.gd")
const spriteSheet = preload("res://source/general/animation/spriteSheet.gd")
const formats: PackedStringArray = ['xml','json','txt']
##Will store the created animations, containing the name and an array with its frames
static var animations_loaded: Dictionary[StringName,Array] = {}
static var _anims_created: Dictionary = {}
static var _anims_file_founded: Dictionary[String,String] = {}

const animation_formats: PackedStringArray = ['.xml','.txt','.json']

var anims_to_update: Dictionary[int,AnimationController] = {}

static func getPrefixList(file: String) -> Dictionary[String,Array]:
	match file.get_extension():
		'xml': return Sparrow.loadSparrow(file)
		'txt': return Atlas.loadAtlas(file)
		'json': return Map.loadMap(file)
		_: return {}

##Get the Animation data using the prefix. [br][br]
##It will return the data and the [Animation] in [[Array][[Rect2]],[Animation]]
static func getAnimFrames(prefix: String,file: String = '') -> Array:
	var fileFounded: Dictionary[String,Array] = getPrefixList(file)
	if !fileFounded:
		return []
	
	if fileFounded.has(prefix): return fileFounded[prefix]
	var data: Array = []
	for anims in fileFounded:
		if (anims+'0000').begins_with(prefix): 
			data.append_array(fileFounded[anims])
	return data

static func getAnim(preffix: String, file: StringName, indices: PackedInt32Array = []) -> Array:
	var _animData: Dictionary = _anims_created.get_or_add(file,{})
	
	var tracks: Array
	#Save anim if don't have indices set.
	if _animData.has(preffix):
		tracks = _anims_created[file][preffix]
		if !indices:
			return tracks
	
	tracks = getAnimFrames(preffix,file)
	if !tracks:
		return []
	
	var frames: Array = []
	if !indices:
		_animData[preffix] = frames
		indices = PackedInt32Array(range(tracks.size()))
	
	var length = tracks.size()-1
	for i in indices:
		if i < 0 or i > length: continue
		frames.append(tracks[i])
	return frames

static func findAnimFile(tex: String):
	if _anims_file_founded.has(tex): return _anims_file_founded[tex]
	
	for formats in animation_formats:
		if tex.ends_with(formats): return tex
		var file = tex+formats
		if FileAccess.file_exists(file): 
			_anims_file_founded[tex] = file
			return file
	return ''

static func _clearAnims() -> void:
	Sparrow.sparrows_loaded.clear()
	Atlas.atlas_loaded.clear()
	Map.maps_created.clear()
	_anims_file_founded.clear()
	
func _process(delta: float):
	if !anims_to_update: return
	for i in anims_to_update.values():
		if !i.playing: anims_to_update.erase(i.get_instance_id()); continue
		i.process_frame(delta)
