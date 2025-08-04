class_name Character3D extends "res://source/general/Sprite3D.gd"

var danceBeats: int = 2
var curCharacter: String = '': set = loadCharacter

var imageFile: String = 'characters/BOYFRIEND'
var imagePath: String = ''

var holdTimer: float = 0.0
var holdLimit: float = 1.0
var heyTimer: float = 0.0

var singDuration: float = 4.1
var healthIcon: String = ''

var hasWinningIcon: bool = false
var specialAnim: bool = false
var isPlayer: bool = false

var autoDance: bool = true

var hasMissAnimations: bool = false
var scroll_factor: Vector2 = Vector2(1,1)
var positionArray: PackedFloat32Array = [0,0]
var cameraPosition: PackedFloat32Array = [0,0]
var jsonScale: float = 1
var isGF: bool = false

var healthBarColors: PackedFloat32Array = [0,0,0]

var hasDanceAnim: bool = false
var danced: bool = false

var animationsArray: Dictionary = {}

var idleSuffix: StringName = ''

func _init(posX: float = 0, posY:float = 0, character:String = 'bf', player: bool = false):
	isPlayer = player
	autoDance = not isPlayer
	name = character
	
	#super._init()
	loadCharacter(character)
	x = posX
	y = posY
func _ready():
	#Update bpm when the character is added to the game
	animation.animation_finished.connect(
	func(_anim):
		if specialAnim:
			specialAnim = false
	)
	Conductor.updatingBPM.connect(updateBPM)
	updateBPM()
	
func updateBPM():
	if holdLimit >= 0.0: #the player will dont back to the idle anim when hit the note if == -1
		holdLimit = (Conductor.stepCrochet * (0.0011 / Conductor.music_pitch))
	var danceSpeed = min(2.0,max(1.0,420.0/Conductor.crochet))
	for dances in ['danceLeft','danceRight']:
		if animation.animExists(dances):
			animation.animationsArray[dances].fps = 24.0*danceSpeed
	
func loadCharacter(json: StringName) -> void:
	if json == curCharacter:
		return
	var detectJson = Paths.character(json)
	if detectJson.is_empty():
		json = 'bf'
		detectJson = Paths.character('bf')
	
	if detectJson.is_empty():
		return
	curCharacter = json
	var charData = {
		"animations": {},
		"no_antialiasing": false,
		"has_win_frame": false,
		"position": [0,0],
		"camera_position": [0,0],
		"image": "",
		"healthbar_colors": [255,255,255],
		"healthicon": "face",
		"flip_x": false,
		"sing_duration": 4.0,
		"scale": 1
	}
	charData.merge(Paths.loadJson(detectJson),true)
	#Load Sprite
	loadModel(charData.image)
	hasWinningIcon = charData.has_win_frame
	positionArray = charData.position
	cameraPosition = charData.camera_position
	
	jsonScale = charData.scale
	animationsArray.clear()
	healthBarColors = charData.healthbar_colors
	healthIcon = charData.healthicon
	imageFile = charData.image
	
		
	hasMissAnimations = false
	hasDanceAnim = false
	for anims in charData.animations:
		if anims.anim == 'danceLeft' or anims.anim == 'danceRight':
			hasDanceAnim = true
			danceBeats = 1
		if anims.anim.ends_with('miss'):
			hasMissAnimations = true
		
		var animOffset: Vector2 =  Vector2(
			float(anims.offsets[0]),
			float(anims.offsets[1])
		)
		
		animationsArray[anims.anim] = {
			offsets = animOffset,
			name = anims.name,
			fps = anims.fps,
			loop = anims.loop
		}
	scale = Vector3(charData.scale,charData.scale,charData.scale)
	dance()

func _process(delta):
	if not specialAnim and holdLimit and animation.curAnim.name.begins_with('sing') and not animation.curAnim.name.ends_with('miss'):
		holdTimer += delta
		if holdTimer >= holdLimit * singDuration:
			if autoDance or not autoDance and not InputHelper.detectKeysPressed(['note_left','note_down','note_up','note_right']):
				dance()
	if heyTimer:
		heyTimer -= delta
		if heyTimer <= 0.0:
			dance()
			heyTimer = 0.0
	super._process(delta)

func dance() -> void:
	holdTimer = 0.0
	if not hasDanceAnim:
		animation.current_animation = 'idle'+idleSuffix
	else:
		animation.current_animation = 'danceLeft' if danced else 'danceRight'
		danced = !danced
	specialAnim = false
