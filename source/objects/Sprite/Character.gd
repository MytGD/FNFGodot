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


var _images: Dictionary[StringName,Texture2D] = {}
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

var healthBarColors: Color = Color.WHITE ##The color of the character bar.

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

var json: Dictionary = getCharacterBaseData() ##The character json. See also [method loadCharacter]

var origin_offset: Vector2 = Vector2.ZERO

var _flipped_sing_anims: bool = false
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

const dance_anim: Array[StringName] = ['danceLeft','danceRight']

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
	json.merge(new_json,true)
	
	image.texture = Paths.imageTexture(json.assetPath)
	if image.texture: _images[json.assetPath] = image.texture
	
	_update_texture()
	
	
	reloadAnims()
	loadData()
	

	return json
	
func loadData():
	var health_color = json.healthbar_colors
	healthBarColors = Color(
		health_color[0]/255.0,
		health_color[1]/255.0,
		health_color[2]/255.0
	)
	healthIcon = json.healthIcon.id
	imageFile = json.assetPath
	antialiasing = not json.isPixel
	positionArray = VectorHelper.array_to_vec(json.offsets)
	cameraPosition = VectorHelper.array_to_vec(json.camera_position)
	jsonScale = json.scale
	offset_follow_flip = json.offset_follow_flip
	offset_follow_scale = json.offset_follow_scale
	origin_offset = VectorHelper.array_to_vec(json.origin_offset)
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
	hasDanceAnim = false
	danceEveryNumBeats = 2
	hasMissAnimations = false
	animation.animations_use_textures = false
	_flipped_sing_anims = json.sing_follow_flip and flipX
	
	for anims in json.animations:
		var animName: StringName = anims.name
		#Invert singLEFT and singRIGHT if "sing_follow_flip" are true and the character is flipped.
		if _flipped_sing_anims:
			if animName.begins_with('singLEFT'): animName = 'singRIGHT'+animName.right(-8)
			elif animName.begins_with('singRIGHT'): animName = 'singLEFT'+animName.right(-9)
		
		if !hasDanceAnim and (animName == 'danceLeft' or animName == 'danceRight'):
			hasDanceAnim = true
			danceEveryNumBeats = 1
			
		if !hasMissAnimations and animName.ends_with('miss'): hasMissAnimations = true
		
		
		addCharacterAnimation(
			animName,
			{
				'prefix': anims.prefix,
				'fps': anims.get('fps',24.0),
				'looped': anims.get('looped',false),
				'indices': anims.get('frameIndices',[]),
				'asset': anims.get('assetPath',json.assetPath)
			}
		)
		addAnimOffset(animName,anims.offsets)
		animation.setLoopFrame(animName,anims.get('loop_frame',0))
	
	var anim_signal = animation.animation_started
	if hasDanceAnim and not anim_signal.is_connected(_check_dance_anim):
		anim_signal.connect(_check_dance_anim)
	elif !hasDanceAnim and anim_signal.is_connected(_check_dance_anim):
		anim_signal.disconnect(_check_dance_anim)

func _clear() -> void:
	animation.clearLibrary()
	_animOffsets.clear()
	_images.clear()
	#json = getCharacterBase() Not used to prevent the same reference
	json.clear()
	json.assign(getCharacterBaseData())

func addCharacterAnimation(animName: StringName,anim_data: Dictionary):
	var search_in: Array[Texture2D]
	
	var tex = anim_data.get('asset','')
	if tex is String: 
		tex = addCharacterImage(tex)
		anim_data.asset = tex
	if tex: search_in = [tex]
		
	else: search_in =  _images.values()
	
	var prefix = anim_data.get('prefix')
	if !prefix: return {}
	var indices = anim_data.get('indices',[])
	for asset in search_in:
		var anim_frames = animation.getFramesFromPrefix(
			prefix,
			indices,
			AnimationService.findAnimFile(asset.resource_name)
		)
		if !anim_frames: continue
		anim_data.frames =  anim_frames
		
		return animation.insertAnim(animName,anim_data)
	return {}
	
func addCharacterImage(path) -> Texture2D:
	if path is Texture2D: return
	if !path: path = json.assetPath
	if _images.has(path): return _images[path]
	var asset = Paths.imageTexture(path)
	if !asset: return null
	_images[path] = asset
	animation.setup_animation_textures()
	return asset

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
			-100 + cam_offset.y
		)
	return getMidpoint() + Vector2(150,-100) + cam_offset



func _check_dance_anim(anim_name: StringName) -> void:
	if anim_name.begins_with('singLEFT'): danced = false
	elif anim_name.begins_with('singRIGHT'): danced = true
	
func flip_sing_animations() -> void:
	for i in animationsArray.keys():
		if !i.begins_with('singLEFT'): continue
		var left_data = animationsArray[i]
		var right_name = 'singRIGHT'+i.right(-8)
		var right_data = animationsArray.get(right_name)
		if right_data: addCharacterAnimation(i,right_data)
		else: animationsArray.erase(i)
		addCharacterAnimation(right_name,left_data)
	_flipped_sing_anims = true
	animation.update_anim()

func set_pivot_offset(pivot: Vector2):
	pivot += origin_offset
	super.set_pivot_offset(pivot)

func flip_h(flip: bool = flipX) -> void:
	if flipX == flip: return
	super.flip_h(flip)
	if json.sing_follow_flip and !_flipped_sing_anims: flip_sing_animations()

static func _convert_psych_to_original(json: Dictionary):
	var new_json = getCharacterBaseData()
	
	var anims = json.get('animations')
	json.erase('animations')
	if anims:
		for i in anims:
			var anim = getAnimBaseData()
			
			DictionaryHelper.merge_existing(anim,i)
			if i.has('indices'): anim.frameIndices = i.indices
			if i.has('loop'): anim.looped = i.loop
			if i.has('anim'):  anim.name = i.anim; if i.has('name'): anim.prefix = i.name
			
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
	
	DictionaryHelper.merge_existing(new_json,json)
	return new_json

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
			'canScale': false
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
		for i in Paths.getFilesAt('characters',true,'.json'):
			directory[i.get_file().left(-5)] = Paths.loadJson(i)
		return directory
	return Paths.getFilesAt('characters',false,'.json')
	
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
