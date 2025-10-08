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
		GameOverSubstate.deathSoundName = 'gameplay/gameover/fnf_loss_sfx'
		GameOverSubstate.loopSoundName = 'gameplay/gameover/gameOver'
		GameOverSubstate.endSoundName = 'gameplay/gameover/gameOverEnd'
	super.loadSongObjects()

func destroy(absolute: bool = true):
	super.destroy(absolute)
	camGame.removeFilters()

func gameOver():
	var state = GameOverSubstate.new()
	state.scale = Vector2(camGame.zoom,camGame.zoom)
	state.transform = camGame.scroll_camera.transform
	state.isOpponent = playAsOpponent
	state.character = dad if playAsOpponent else boyfriend
	Global.scene.add_child(state)
	for cams in [camGame,camHUD,camOther]: cams.visible = false
	super.gameOver()

func loadStage(stage: StringName,loadScript: bool = true):
	super.loadStage(stage,loadScript)
	
	boyfriendCameraOffset = VectorHelper.array_to_vec(stageJson.characters.bf.cameraOffsets)
	girlfriendCameraOffset = VectorHelper.array_to_vec(stageJson.characters.gf.cameraOffsets)
	opponentCameraOffset = VectorHelper.array_to_vec(stageJson.characters.dad.cameraOffsets)
	
	defaultCamZoom = stageJson.cameraZoom
	cameraSpeed = stageJson.cameraSpeed
	camGame.zoom = defaultCamZoom
	
	boyfriendGroup.x = stageJson.characters.bf.position[0]
	boyfriendGroup.y = stageJson.characters.bf.position[1]
	dadGroup.x = stageJson.characters.dad.position[0]
	dadGroup.y = stageJson.characters.dad.position[1]
	gfGroup.x = stageJson.characters.gf.position[0]
	gfGroup.y = stageJson.characters.gf.position[1]
	
	if stageJson.get('hide_girlfriend'): 
		gfGroup.visible = false
	else: gfGroup.visible = true
	
	
	if stageJson.get('hide_boyfriend'): boyfriendGroup.visible = false
	else:  boyfriendGroup.visible = true
	moveCamera(detectSection())
	
func _process(delta: float) -> void:
	if camZooming: camGame.zoom = lerpf(camGame.zoom,defaultCamZoom,delta*3*zoomSpeed)
	super._process(delta)
	camGame.scroll = camGame.scroll.lerp(
		camFollow - ScreenUtils.defaultSizeCenter + ScreenUtils.screenOffset,
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
		
	if !Paths.file_exists('characters/'+charFile+'.json'): charFile = 'bf'
	
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
	FunkinGD.callScript('characters/'+charFile+'.gd','onLoadThisCharacter',[newCharacter,charType])
	FunkinGD.callOnScripts('onLoadCharacter',[newCharacter,charType])
	insertCharacterInGroup(newCharacter,group)
	newCharacter.visible = false
	newCharacter.process_mode = Node.PROCESS_MODE_DISABLED
	return newCharacter

	
func hitNote(note: Note, character: Variant = getCharacterNote(note)):
	if not note: return
	if note.noAnimation: super.hitNote(note,character); return
	
	var mustPress: bool = note.mustPress
	var gfNote = note.gfNote or (gfSection and mustPress == mustHitSection)
	var dance: bool = not (mustPress != playAsOpponent and not botplay)
	
	if gfNote:
		if character: character.autoDance = false
		if gf: gf.autoDance = dance
	else:
		if character: character.autoDance = dance
		if gf: gf.autoDance = true

	if !character: super.hitNote(note,character); return;
	var animNote = singAnimations[note.noteData]
	
	var anim = character.animation
	character.holdTimer = 0.0
	character.heyTimer = 0.0
	character.specialAnim = false
	if !note.animSuffix or !anim.play(animNote+note.animSuffix,true): anim.play(animNote,true)
	super.hitNote(note,character)
	
func noteMiss(note: Note, character: Variant = getCharacterNote(note)):
	if character: character.animation.play(singAnimations[note.noteData]+'miss',true)
	super.noteMiss(note,character)

#Set in scripts/cameraMoviment.gd in game's folder.
#func moveCamera(target: StringName = 'boyfriend') -> void:
	#camFollow = getCameraPos(get(target)) 
	#super.moveCamera(target)

func screenBeat() -> void:
	camGame.zoom += 0.015
	super.screenBeat()

func changeCharacter(type: int = 0, character: StringName = 'bf') -> Object:
	var char_name: StringName = get_character_type_name(type)
	var character_obj = get(char_name)
	if character_obj and character_obj.curCharacter == character: return
	
	var group: SpriteGroup = get(char_name+'Group')
	if !group: return
	
	var newCharacter = addCharacterToList(type,character)
	if not newCharacter: return
	
	newCharacter.name = char_name
	newCharacter.holdTimer = 0.0
	newCharacter.visible = true
	newCharacter.process_mode = Node.PROCESS_MODE_INHERIT
	set(char_name,newCharacter)
	
	if character_obj:
		var char_anim = character_obj.animation
		if newCharacter.animation.has_animation(char_anim.current_animation): 
			newCharacter.animation.play(char_anim.current_animation)
			newCharacter.animation.curAnim.curFrame = char_anim.curAnim.curFrame
		else: newCharacter.dance()
		
		newCharacter.material = character_obj.material
		character_obj.material = null
		
		character_obj.visible = false
		character_obj.process_mode = PROCESS_MODE_DISABLED
	else:
		newCharacter.dance()
	match type:
		0:
			iconP1.reloadIconFromCharacterJson(newCharacter.json)
			healthBar.set_colors(null,newCharacter.healthBarColors)
		1:
			healthBar.set_colors(newCharacter.healthBarColors)
			iconP2.reloadIconFromCharacterJson(newCharacter.json)
	updateIconsImage(healthBar_State)
	
	FunkinGD.callOnScripts('onChangeCharacter',[type,newCharacter,character_obj])
	updateIconsPivot()
	if !isCameraOnForcedPos and detectSection() == char_name: moveCamera(char_name)
	
	return newCharacter

func clear():
	super.clear()
	camGame.removeFilters()
	for g in [boyfriendGroup,gfGroup,dadGroup]:
		for i in g.members: i.queue_free()
		g.members.clear()
	boyfriend = null
	dad = null
	gf = null

static func getCameraPos(obj: Node, add_camera_json_offset: bool = true) -> Vector2:
	if !obj: return Vector2(0.0,0.0)
	
	var pos: Vector2
	if obj is Character:
		pos = obj.getCameraPosition()
		if add_camera_json_offset: pos += getCameraOffset(obj)
		if ScreenUtils.screenOffset.x: pos.x -= ScreenUtils.screenOffset.x/2.0
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
