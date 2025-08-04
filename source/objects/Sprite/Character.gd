@icon("res://icons/icon.png")
##A Character 2D Class
extends Sprite
const Note = preload("res://source/objects/Notes/Note.gd")
const AnimationService = preload("res://source/general/animation/AnimationService.gd")
@export var curCharacter: StringName = '': set = loadCharacter ##The name of the character json.

##how many beats should pass before the character dances again.[br][br]For example: 
##If it's [code]2[/code], 
##the character will dance every second beat. If it's [code]1[/code], they dance on every beat.
var danceEveryNumBeats: int = 2

var forceDance: bool = false
var holdLimit: float = 1.0 ##The time limit to return to idle animation.
var holdTimer: float = 0.0 ##The time the character is in singing animation.
var heyTimer: float = 0.0 ##The time the character is in the "Hey" animation.
var singDuration: float = 4.1 ##The duration of the sing animations.
var returnDance: bool = true ##If [code]false[/code], the character will not return to the idle anim.


var healthIcon: String = '' ##The Character Icon


var specialAnim: bool = false ##If [code]true[/code], the character will not return to dance while the current animation ends.

var isPlayer: bool = false: ##If is a player character.
	set(player):
		isPlayer = player
		flipX = !json.flipX if player else json.flipX
		


var autoDance: bool = true ##If [code]false[/code], the character will not return to dance while pressing the sing keys.

var hasMissAnimations: bool = false ##If the character have any miss animation, used to play a miss animation when miss a note.

var positionArray: Vector2 = Vector2.ZERO ##The character position offset.
var cameraPosition: Vector2 = Vector2.ZERO ##The camera position offset.

var jsonScale: float = 1. ##The Character Scale from his json.

var isGF: bool = false ##If this is a "[u]GF[/u]" character.

var healthBarColors: PackedInt32Array = [0,0,0] ##The color of the character bar.

var hasDanceAnim: bool = false ##If character have "danceLeft" or "danceRight" animation.
var danced: bool = false ##Used to make the "danceLeft/danceRight" animation.

var animationsArray:
	get(): return animation.animationsArray

##If is not blank, it will be added to the "idle" animation name, for example:[codeblock]
##var character = Character.new()
##character.dance() #Will play "idle" animation
##
##character.idleSuffix = '-alt'
##character.dance() #Will play "idle-alt" animation
##
##character.idleSuffix = '-alt2'
##character.dance() #Will play "idle-alt2"
##[/codeblock]
var idleSuffix: String = ''

var _images: Dictionary = {}
var json: Dictionary = getCharacterBaseData() ##The character json. See also [method loadCharacter]

var origin_offset: Vector2 = Vector2.ZERO

signal on_load_character(new_character: StringName, old_character: StringName)
func _init(character:String = '', player: bool = false):
	autoDance = not isPlayer
	super._init('',true)
	
	animation.auto_loop = true
	autoUpdateImage = false
	
	if character: loadCharacter(character)
	
	isPlayer = player
	animation.animation_finished.connect(
		func(_anim): if specialAnim and returnDance: dance()
	)
	
	
func _ready() -> void: Conductor.bpm_changes.connect(updateBPM)

func _enter_tree() -> void: updateBPM()

const dance_anim = ['danceLeft','danceRight']

##Update the character frequency.
func updateBPM():
	holdLimit = (Conductor.stepCrochet * (0.0011 / Conductor.music_pitch))
	for dances in dance_anim:
		var animData = animation.getAnimData(dances)
		if animData:
			var anim_length = 1.0/animData.fps * animData.frames.size()
			animData.speed_scale = clamp(anim_length/(Conductor.crochet/700.0),1.0,3.0)
			#animData.speed_scale = clamp(550.0/(Conductor.crochet),2.6,1.0)
	
##Load Character. Returns a [Dictionary] with the json found data.
func loadCharacter(char_name: StringName) -> Dictionary:
	if char_name and char_name == curCharacter: return json
	var new_json = Paths.character(char_name)
	
	if not new_json:
		char_name = 'bf'
		new_json = Paths.character('bf')
		
	
	if !new_json:
		_clear()
		on_load_character.emit(char_name,curCharacter)
		curCharacter = ''
		return new_json
	
	loadCharacterFromJson(new_json)
	on_load_character.emit(char_name,curCharacter)
	curCharacter = char_name
	name = char_name
	return json

func loadCharacterFromJson(new_json: Dictionary):
	_clear()
	_animOffsets.clear()
	json.merge(new_json,true)
	
	hasMissAnimations = false
	hasDanceAnim = false
	
	setCharacterImage(json.assetPath)
	_update_texture()
	
	reloadAnims()
	
	loadData()
	
	if !_images: return json
	return json
	
func loadData():
	healthBarColors = json.healthbar_colors
	healthIcon = json.healthIcon.id
	imageFile = json.assetPath
	antialiasing = not json.isPixel
	positionArray = VectorHelper.array_to_vector(json.offsets)
	cameraPosition = VectorHelper.array_to_vector(json.camera_position)
	jsonScale = json.scale
	offset_follow_flip = json.get_or_add('offset_follow_flip',false)
	offset_follow_scale = json.get_or_add('offset_follow_scale',false)
	origin_offset = VectorHelper.array_to_vector(json.get('origin_offset',[0,0]))
	scale = Vector2(json.scale,json.scale)
	centerOrigin()
	
func _process(delta) -> void:
	super._process(delta)
	if !returnDance: return
	
	if not specialAnim and animation.curAnim.name.begins_with('sing'):
		holdTimer += delta
		if holdTimer >= holdLimit * singDuration and (autoDance or !InputHelper.is_any_actions_pressed(Note.getNoteAction())):
			dance()
		
	if heyTimer:
		heyTimer -= delta
		if heyTimer <= 0.0:
			dance()
			heyTimer = 0.0
	
##Reload the character animations, used also in Character Editor.
func reloadAnims():
	animation.clearLibrary()
	for anims in json.animations:
		var animName = anims.name
		#Invert singLEFT and singRIGHT if "sing_follow_flip" are true and the character is flipped.
		if json.sing_follow_flip and flipX:
			if animName.begins_with('singLEFT'): animName = 'singRIGHT'+animName.right(-8)
				
			elif animName.begins_with('singRIGHT'): animName = 'singLEFT'+animName.right(-9)
		
		if animName == 'danceLeft' or animName == 'danceRight':
			hasDanceAnim = true
			danceEveryNumBeats = 1
			
		if animName.ends_with('miss'): hasMissAnimations = true
		
		
		var assetPath = anims.get('assetPath',json.assetPath)
		if assetPath != json.assetPath: addCharacterImage(assetPath)
		
		addCharacterAnimation(
			animName,
			anims.prefix,
			anims.fps,
			anims.looped,
			anims.frameIndices,
			assetPath
		)
		addAnimOffset(animName,anims.offsets)
		animation.setLoopFrame(animName,anims.loop_frame)
	
	if animation.animation_started.is_connected(_verify_image):
		if _images.size() <= 1: animation.animation_started.disconnect(_verify_image)
		
	elif _images.size() > 1: animation.animation_started.connect(_verify_image)
		
	
func _clear() -> void:
	_images.clear()
	animation.clearLibrary()
	
	#json = getCharacterBase() Not used to prevent the same reference
	json.clear()
	json.assign(getCharacterBaseData())

func addCharacterAnimation(animName: String,prefix: String,fps: float = 24.0,looped: bool = false,indices: Variant = [], assetPath: String = ''):
	var search_in: Array
	if assetPath and _images.has(assetPath): search_in = [assetPath]
	else: search_in = _images.keys()
		
	for asset in search_in:
		var _image = _images[asset]
		var anim_frames = animation.getFramesFromPrefix(
			prefix,
			indices,
			AnimationService.findAnimFile(_image.texture.resource_name)
		)
		if !anim_frames: continue
		var anim_data = animation.getAnimBaseData()
		anim_data.frames = anim_frames
		anim_data.fps = fps
		anim_data.prefix = prefix
		anim_data.assetPath = asset
		anim_data.looped = looped
		return animation.insertAnim(animName,anim_data)
	return {}
	
func addCharacterImage(path: String) -> Dictionary:
	if !path: return {}
	
	var is_map: bool = !!Paths.folder('images/'+path)
	var tex = Paths.imageTexture(path if !is_map else path+'/spritemap1')
	
	if not tex: return {}
	
	var tex_name = tex.resource_name
	if _images.has(tex_name): return _images[tex_name]
	
	var data = {'texture': tex,'is_map': is_map}
	_images[tex_name] = data
	return data

func dance() -> void: ##Make character returns to his dance animation.
	if not hasDanceAnim: animation.play('idle'+idleSuffix,forceDance)
	else:
		animation.play('danceRight' if danced else 'danceLeft',forceDance)
		danced = !danced
	holdTimer = 0.0
	specialAnim = false

func getCameraPosition() -> Vector2: 
	var cam_offset = cameraPosition
	if isGF: return getMidpoint() + cam_offset 
	if isPlayer: 
		return getMidpoint() + Vector2(
			-100 - cam_offset.x,
			-100 + cam_offset.y)
	return getMidpoint() + Vector2(150,-100) + cam_offset

func getAbsoluteCameraPosition() -> Vector2:
	if isPlayer or isGF: return getCameraPosition()
	var camPos = getCameraPosition()
	return Vector2(camPos.x - ScreenUtils.screenOffset.x/2.09,camPos.y)
	
func setCharacterImage(new_image: String):
	new_image = Paths.getPath(new_image)
	
	_images.erase(json.assetPath)
	
	var data = addCharacterImage(new_image)
	if !data: 
		image.texture = null
		new_image = ''
	else: image.texture = data.texture
	
	json.assetPath = new_image
	
	
func _verify_image(animName: StringName = animation.curAnim.name):
	var anim_data = animationsArray[animName]
	if image.texture.resource_name == anim_data.assetPath: return
	image.texture = _images[anim_data.assetPath].texture
	animation.curAnim.set_frame()
	
static func _convert_psych_to_original(json: Dictionary):
	var new_json = getCharacterBaseData()
	for i in json.get('animations',[]):
		var anim = getAnimBaseData()
		#Detect if the animation data is similar to original
		DictionaryHelper.merge_existing(anim,i)
		if i.has('indices'): anim.frameIndices = i.indices
		if i.has('loop'): anim.looped = i.loop
		if i.has('anim'):  
			anim.name = i.anim
			if i.has('name'): anim.prefix = i.name
		
		anim.offsets = i.get('offsets',[0,0])
		anim.fps = i.get('fps',24.0)
		
		new_json.animations.append(anim)
	
	new_json.offsets = json.get('position',[0,0])
	new_json.flipX = json.get('flip_x',false)
	new_json.healthbar_colors = json.get("healthbar_colors",[255,255,255])
	new_json.assetPath = json.get('image','')
	new_json.singTime = json.get('sing_duration',4.0)*2.0
	new_json.isPixel = json.get('no_antialiasing',false)
	new_json.healthIcon.id = json.get('healthicon','icon-face')
	new_json.healthIcon.isPixel = new_json.healthIcon.id.ends_with('-pixel')
	new_json.camera_position = json.get('camera_position',[0,0])
	new_json.scale = json.get('scale',1.0)
	
	json.erase('animations') #Removing animations to avoid overwriting them in the original dictionary
	DictionaryHelper.merge_existing(new_json,json)
	return new_json

func flip_sing_animations() -> void:
	animation.renameAnimation('singLEFT','__')
	animation.renameAnimation('singRIGHT','singLEFT')
	animation.renameAnimation('__','singRIGHT')
	animation._update_anim()
func set_pivot_offset(pivot: Vector2):
	pivot += origin_offset
	super.set_pivot_offset(pivot)

func flip_h(flip: bool = flipX) -> void:
	if flipX == flip: return
	super.flip_h(flip)
	if json.sing_follow_flip: flip_sing_animations()
		
static func getCharacterBaseData() -> Dictionary: ##Returns a base to character data.
	return {
		"animations": [],
		"isPixel": false,
		"offsets": [0,0],
		"camera_position": [0,0],
		"assetPath": "",
		"healthbar_colors": [255,255,255],
		"healthIcon": {
			"id": "icon-face",
			"isPixel": false,
			'canScale': false,
		},
		"flipX": false,
		"singTime": 4.0,
		"scale": 1,
		"origin_offset": [0,0],
		"offset_follow_flip": false,
		'offset_follow_scale': false,
		'sing_follow_flip': false
	}

static func getCharactersList(return_jsons: bool = false) -> Variant:
	if return_jsons:
		var directory = {}
		for i in Paths.getFilesAtDirectory('characters',true,'.json'):
			directory[i.get_file().left(-5)] = Paths.loadJson(i)
		return directory
	return Paths.getFilesAtDirectory('characters',false,'.json')
	
static func getAnimBaseData(): ##Returns a base for the character animation data.
	return {
		'name': '',
		'prefix': '',
		'fps': 24,
		'loop_frame': 0,
		'looped': false,
		'frameIndices': [],
		'offsets': [0,0],
		'assetPath': ''
	}
