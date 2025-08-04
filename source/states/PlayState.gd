extends "res://source/states/PlayStateBase.gd"

@export var boyfriend: Character
@export var dad: Character
@export var gf: Character
		
static var boyfriendCameraOffset: Vector2 = Vector2.ZERO
static var girlfriendCameraOffset: Vector2 = Vector2.ZERO
static var opponentCameraOffset: Vector2 = Vector2.ZERO


var camFollow: Vector2 = Vector2(0.0,0.0)
var camFollowOffset: Vector2 = ScreenUtils.defaultSize/2.0
@export_category('Groups')
var boyfriendGroup: SpriteGroup = SpriteGroup.new() #Added in Stage.loadSprites()
var dadGroup: SpriteGroup = SpriteGroup.new()# Added in Stage.loadSprites()
var gfGroup: SpriteGroup = SpriteGroup.new()# Also added in Stage.loadSprites()

var camGame: CameraCanvas = CameraCanvas.new()

@export_category('Game Over')
const GameOverSubstate := preload("res://source/substates/GameOverSubstate.gd")

func _ready():
	add_child(camGame)
	camGame.name = 'camGame'
	
	boyfriendGroup.name = 'boyfriendGroup'
	dadGroup.name = 'dadGroup'
	gfGroup.name = 'gfGroup'
	
	Stage.charactersGroup = {
		'bf': boyfriendGroup,
		'dad': dadGroup,
		'gf': gfGroup
	}
	super._ready()

#Set GameOverState
func loadSongObjects():
	if isPixelStage:
		GameOverSubstate.characterName = 'bf-pixel'
		GameOverSubstate.opponentName = 'bf-pixel'
		GameOverSubstate.deathSoundName = 'gameplay/gameover/fnf_loss_sfx-pixel'
		GameOverSubstate.loopSoundName = 'gameplay/gameover/gameOver-pixel'
		GameOverSubstate.endSoundName = 'gameplay/gameover/gameOverEnd-pixel'
	else:
		GameOverSubstate.characterName = 'bf'
		GameOverSubstate.opponentName = 'bf'
		GameOverSubstate.deathSoundName = 'gameplay/gameover/fnf_loss_sfx-pixel'
		GameOverSubstate.loopSoundName = 'gameplay/gameover/gameOver'
		GameOverSubstate.endSoundName = 'gameplay/gameover/gameOverEnd'
	super.loadSongObjects()

func gameOver():
	var state = GameOverSubstate.new()
	state.scale = Vector2(camGame.zoom,camGame.zoom)
	state.transform = camGame.camera.transform
	state.isOpponent = playAsOpponent
	state.character = dad if playAsOpponent else boyfriend
	Global.scene.add_child(state)
	for cams in [camGame,camHUD,camOther]: cams.visible = false
	super.gameOver()

func loadStage(stage: StringName,loadScript: bool = true):
	super.loadStage(stage,loadScript)
	
	boyfriendCameraOffset = VectorHelper.array_to_vector(stageJson.characters.bf.cameraOffsets)
	girlfriendCameraOffset = VectorHelper.array_to_vector(stageJson.characters.gf.cameraOffsets)
	opponentCameraOffset = VectorHelper.array_to_vector(stageJson.characters.dad.cameraOffsets)
	
	defaultCamZoom = stageJson.cameraZoom
	cameraSpeed = stageJson.cameraSpeed
	camGame.zoom = defaultCamZoom
	
	boyfriendGroup.x = stageJson.characters.bf.position[0]
	boyfriendGroup.y = stageJson.characters.bf.position[1]
	dadGroup.x = stageJson.characters.dad.position[0]
	dadGroup.y = stageJson.characters.dad.position[1]
	gfGroup.x = stageJson.characters.gf.position[0]
	gfGroup.y = stageJson.characters.gf.position[1]
	
	if stageJson.get('hide_girlfriend') and gf: gf.kill()
	moveCamera(detectSection())
func _process(delta: float) -> void:
	if camZooming: camGame.zoom = lerpf(camGame.zoom,defaultCamZoom,delta*3*zoomSpeed)
	super._process(delta)
	var follow = camFollow - ScreenUtils.screenCenter
	if ScreenUtils.screenOffset != Vector2.ZERO:
		follow += (ScreenUtils.screenOffset/2.0).max(Vector2.ZERO)
	camGame.scroll = camGame.scroll.lerp(
		follow,
		cameraSpeed*delta*3.5
	)

func onBeatHit(beat: int = Conductor.beat) -> void:
	for character in [dad,boyfriend,gf]:
		if !character or character.specialAnim or character.holdTimer > 0 or character.heyTimer > 0: continue
		if fmod(beat,character.danceEveryNumBeats) == 0.0: character.dance()
	super.onBeatHit(beat)


func insertCharacterInGroup(character: Character,group: SpriteGroup) -> void:
	if !character or !group: return
	character._position = Vector2(group.x,group.y) + character.positionArray
	group.add(character,true)

func addCharacterToList(type: int = 0,charFile: StringName = 'bf') -> Character:
	var group
	var charType: String = 'boyfriend'
	match type:
		1: group = dadGroup; charType = 'dad'
		2: group = gfGroup; charType = 'gf'
		_: group = boyfriendGroup
		
	if !Paths.detectFileFolder('characters/'+charFile+'.json'): charFile = 'bf'
	
	#Check if the character is already created.
	for chars in group.members:
		if chars and chars.curCharacter == charFile: return chars
	
	var newCharacter: Character = Character.new(charFile,type == 0)
	
	if group: group.add(newCharacter,false)
	
	newCharacter._position += newCharacter.positionArray
	newCharacter.name = charType
	newCharacter.isGF = (type == 2)
	newCharacter.isPlayer = (type == 0)
	
	Paths.image(newCharacter.healthIcon)
	
	FunkinGD.addScript('characters/'+charFile+'.gd')
	FunkinGD.callOnScripts('onLoadCharacter',[newCharacter,charType])
	
	insertCharacterInGroup(newCharacter,group)
	newCharacter.visible = false
	newCharacter.process_mode = Node.PROCESS_MODE_DISABLED
	return newCharacter

	
func hitNote(note: Note, character: Variant = getCharacterNote(note)):
	if not note: return
	if note.noAnimation:super.hitNote(note,character); return
	
	var mustPress: bool = note.mustPress
	var gfNote = note.gfNote or (gfSection and mustPress == mustHitSection)
	#var character: Character = gf if gfNote else (dad if mustPress else boyfriend)
	var dance: bool = not (mustPress != playAsOpponent and not botplay)
	
	if not mustPress and dad: dad.autoDance = dance
	
	elif mustPress and boyfriend: boyfriend.autoDance = dance and not gfNote
	
	elif gf: gf.autoDance = gfNote and dance
	
	
	if character:
		var animNote = singAnimations[note.noteData]+note.animSuffix
		var anim = character.animation
		character.holdTimer = 0.0
		character.heyTimer = 0.0
		character.specialAnim = false
		anim.play(animNote if anim.has_animation(animNote) else singAnimations[note.noteData],true)
	super.hitNote(note,character)
	
func noteMiss(note: Note, character: Variant = getCharacterNote(note)):
	if character: character.animation.play(singAnimations[note.noteData]+'miss',true)
	super.noteMiss(note,character)
	
func moveCamera(target: StringName = 'boyfriend') -> void:
	camFollow = getCameraPos(get(target))
	super.moveCamera(target)

func screenBeat() -> void:
	camGame.zoom += 0.015
	super.screenBeat()

static func getCameraPos(obj: Node, add_camera_json_offset: bool = true) -> Vector2:
	if !obj: return Vector2(0.0,0.0)
	
	var pos: Vector2
	if obj is Character:
		pos = obj.getAbsoluteCameraPosition()
		if add_camera_json_offset: pos += getCameraOffset(obj)
		return pos
			
	if obj is Sprite: return obj.getMidPoint()
	return obj.position

static func getCameraOffset(obj: Node) -> Vector2:
	if obj.isGF: return girlfriendCameraOffset
	if obj.isPlayer: return boyfriendCameraOffset
	else: return opponentCameraOffset
	
func getCharacterNote(note: Note) -> Character:
	if note.gfNote: return gf
	if note.mustPress: return boyfriend
	return dad
