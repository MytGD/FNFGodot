extends "res://source/states/StrumState.gd"
##PlayState Base.
const GDText = preload("res://source/objects/Display/GDText.gd")
const CameraCanvas = preload("res://source/objects/Display/Camera.gd")
const PauseSubstate = preload("res://source/substates/PauseSubstate.gd")
const Character = preload("res://source/objects/Sprite/Character.gd")
const Bar = preload("res://source/objects/UI/Bar.gd")
const Stage = preload("res://source/gdscript/FunkinStage.gd")

const CharacterEditor = preload("res://scenes/states/CharacterEditor.tscn")
const ChartEditorScene = preload("res://scenes/states/ChartEditor.tscn")

static var back_state = preload("res://source/states/Menu/ModeSelect.gd")
var stateLoaded: bool = false #Used in FunkinGD


enum IconState{
	NORMAL,
	LOSING,
	WINNING
}
@export_group('Stage')
var stageJson: Dictionary = Stage.getStageBase()
var curStage: StringName = ''



@export_group('Camera')
var camHUD: CameraCanvas = CameraCanvas.new()
var camOther: CameraCanvas = CameraCanvas.new()

var cameraSpeed: float = 1.0
var zoomSpeed: float = 1.0

var isCameraOnForcedPos: bool = false
var defaultCamZoom: float = 1.0

@export_group('Play Options')
@export var singAnimations: PackedStringArray = ["singLEFT","singDOWN","singUP","singRIGHT"]

##The amount of beats for the camera to give a "beat" effect.
@export var bumpStrumBeat: float = 4.0
@export var canExitSong: bool = true
@export var canPause: bool = true
@export var canGameOver: bool = true

var camZooming: bool = false##If [code]true[/code], the camera make a beat effect every [member bumpStrumBeat] beats and the zoom will back automatically.

@export_subgroup('Events')
var eventNotes: Array[Dictionary] = []
@export var generateEvents: bool = true
var _is_first_event_load: bool = true

@export_group("Countdown Options")
@export var countDownEnabled: bool = true
@export var countSounds = ['introTHREE','introTWO','introONE','introGO']
@export var countDownImages = ['','ready','set','go']
var _countdown_started: bool = false
var skipCountdown: bool = false

@export_group("Hud Elements")
@export var hideHud: bool = ClientPrefs.data.hideHud: set = _set_hide_hud

var hideTimeBar: bool = ClientPrefs.data.timeBarType == "Disabled"
var timeBarType: StringName = ClientPrefs.data.timeBarType
var pauseState: PauseSubstate
var onPause: bool = false

var inGameOver: bool = false

@export_group('Objects')
const Icon := preload("res://source/objects/UI/Icon.gd")

var iconP1: Icon = Icon.new()
var iconP2: Icon = Icon.new()
var icons: Array[Icon] = [iconP1,iconP2]

var scoreTxt = GDText.new()

var healthBar: Bar = Bar.new('healthBar')
var health: float: set = set_health
var healthBar_State: IconState = IconState.NORMAL

var timeBar: Bar
var timeTxt: GDText

@export_category('Story Mode')
var story_song_notes: Dictionary = {}
var story_songs: PackedStringArray = []
var isStoryMode: bool = false

@export_category("Song Data")
var isSongStarted: bool = false
var songName: StringName = ''

@export_category("Cutscene")
var seenCutscene: bool = false
var skipCutscene: bool = true
var inCutscene: bool = false
var videoPlayer: VideoStreamPlayer

var introSoundsSuffix: StringName = ''

var altSection: bool = false


func _ready():
	Global.onSwapTree.connect(destroy)
	
	name = 'PlayState'
	
	FunkinGD.game = self
	
	camHUD.name = 'camHUD'
	camHUD.bg.modulate.a = 0.0
	
	camOther.name = 'camOther'
	camOther.bg.modulate.a = 0.0
	
	
	add_child(camHUD)
	add_child(camOther)
	
	camHUD.add(uiGroup,true)
	
	super._ready() #Load Song
	
	#Create hud
	if !hideHud:
		iconP1.name = 'iconP1'
		iconP1.scale_lerp = true
		
		iconP2.name = 'iconP2'
		iconP2.scale_lerp = true
		
		iconP1.flipX = true
		
		updateIconsPivot()
		
		healthBar.x = ScreenUtils.screenWidth/2.0 - healthBar.bg.width/2.0
		healthBar.y = ScreenUtils.screenHeight - 100 if not ClientPrefs.data.downscroll else 50
		
		uiGroup.add(iconP1)
		uiGroup.add(iconP2)
		
		healthBar.draw.connect(updateIconsPivot)
		
		uiGroup.insert(iconP1.get_index(),healthBar)
		healthBar.flip = true
		
		
		scoreTxt = GDText.new('Score: 0 | Misses: 0 | Accurancy: 0%(N/A)',ScreenUtils.screenWidth/2.0,ScreenUtils.screenHeight - 50.0)
		scoreTxt.name = 'scoreTxt'
		if isPixelStage: scoreTxt.font = 'pixel.otf'
			
		uiGroup.add(scoreTxt)
		
		healthBar.name = 'healthBar'
		#Time Bar
		if !hideTimeBar:
			timeBar = Bar.new('timeBar')
			timeBar.name = 'timeBar'
			timeTxt = GDText.new()
			
			if timeBarType == 'Song Name': timeTxt.text = songName
			
			if isPixelStage: timeTxt.font = 'pixel.otf'
			timeTxt.name = 'TimeTxt'
			timeTxt._position = Vector2(timeBar.x+timeBar.bg.pivot_offset.x,timeBar.y)
			
			timeBar.screenCenter('x')
			uiGroup.add_child(timeBar)
			uiGroup.add(timeTxt)

	
	for event in eventNotes: 
		FunkinGD.callOnScripts('onLoadEvent',[event.event,event.variables,event.strumTime])
		FunkinGD.callScript('custom_events/'+event.event,'onLoadThisEvent',[event.variables,event.strumTime])
		if _is_first_event_load:
			FunkinGD.callOnScripts('onInitEvent',[event.event,event.variables,event.strumTime])
			FunkinGD.callScript('custom_events/'+event.event,'onInitLocalEvent',[event.variables,event.strumTime])
	health = 1.0
	
	if splashesEnabled: 
		Paths.image(SONG.get('splashType') if SONG.get('splashType') else 'noteSplashes/noteSplashes')
	
	if !isCameraOnForcedPos: moveCamera(detectSection())
	_resetScore()
	
	
	#Set Signals
	Conductor.beat_hit.connect(onBeatHit)
	Conductor.section_hit.connect(onSectionHit)
	Conductor.section_hit_once.connect(onSectionHitOnce)
	FunkinGD.callOnScripts('onCreatePost')
	startCountdown()
	stateLoaded = true

func createMobileGUI():
	super.createMobileGUI()
	#Pause Button
	var button = TextureButton.new()
	button.texture_normal = Paths.imageTexture('mobile/pause_menu')
	button.scale = Vector2(1.2,1.2)
	button.position.x = ScreenUtils.screenCenter.x
	button.pressed.connect(pauseSong)
	add_child(button)
	
func loadCharactersFromData(json: Dictionary = SONG):
	changeCharacter(2,json.get('gfVersion','gf'))
	changeCharacter(0,json.get('player1','bf'))
	changeCharacter(1,json.get('player2','bf'))

func updateTimeBar():
	if !timeBar: return

	timeBar.progress = songPos/songLength
	var songSeconds
	
	if ClientPrefs.data.timeBarType == 'TimeLeft': songSeconds = int((songLength-songPos)/1000)
	else: songSeconds = int(songPos/1000.0)
	
	var songMinutes = songSeconds/60
	songSeconds %= 60
	
	songMinutes = str(songMinutes)
	songSeconds = str(songSeconds)
	if songMinutes.length() <= 1: songMinutes = '0'+songMinutes
	
	if songSeconds.length() <= 1: songSeconds = '0'+songSeconds
	
	
	timeTxt.text = songMinutes+':'+songSeconds
	
func _process(delta):
	if camZooming: camHUD.zoom = lerpf(camHUD.zoom,camHUD.defaultZoom,delta*3*zoomSpeed)
	
	#Count Down
	if Conductor.songPosition < 0:
		Conductor.songPosition += delta * 1000.0
		if Conductor.songPosition >= 0: startSong()
	
	FunkinGD.callOnScripts('onUpdate',[delta])
	updateTimeBar()
	
	super._process(delta)
	
	
	#Update Icons Positions
	for icon in icons: updateIconPos(icon)
	
	FunkinGD.callOnScripts('onUpdatePost',[delta])
	
	
	#Skip Cutscene
	if inCutscene and videoPlayer and skipCutscene and Input.is_action_just_pressed('ui_accept'): skipVideo()

#region Icon Methods
func updateIconPos(icon: Icon) -> void:
	var icon_pos: Vector2 
	if icon.flipX: icon_pos = healthBar.get_process_position(healthBar.progress - 0.03)
	else: icon_pos = healthBar.get_process_position(healthBar.progress)
	icon._position = icon_pos + healthBar.position - icon.pivot_offset

func updateIconsPivot() -> void:
	var angle = healthBar.rotation
	if angle:
		for i in icons:
			if i.flipX: 
				i.pivot_offset = Vector2(
					lerpf(i.image.pivot_offset.x,0,cos(angle)),
					lerpf(i.image.pivot_offset.y,0,sin(angle))
				)
			else: 
				i.pivot_offset = Vector2(
					lerpf(i.image.pivot_offset.x,0,cos(angle)),
					lerpf(0,i.image.pivot_offset.y*2.0,sin(angle))
				)
	else:
		for i in icons:
			if i.flipX: i.pivot_offset = Vector2(0,i.image.pivot_offset.y)
			else: i.pivot_offset = Vector2(i.image.pivot_offset.x*2.0,i.image.pivot_offset.y)
#endregion

#region Beat Methods

func iconBeat() -> void:
	if !can_process(): return #Do not beat if the game is not being processed.
	for i in icons: i.scale += i.beat_value

func updateIconsImage(state: IconState):
	match state:
		IconState.NORMAL:
			iconP1.animation.play('normal')
			iconP2.animation.play('normal')
		IconState.LOSING:
			if iconP2.hasWinningIcon: iconP2.animation.play('winning')
			else: iconP2.animation.play('normal')
			iconP1.animation.play('losing')
		IconState.WINNING:
			if iconP1.hasWinningIcon: iconP1.animation.play('winning')
			else: iconP1.animation.play('normal')
			iconP2.animation.play('losing')
			
##Do screen beat effect.
func screenBeat() -> void: #Used also in "states/PlayState"
	camHUD.zoom += 0.03

func onBeatHit(beat: int = Conductor.beat) -> void:
	if !can_process(): return
	if camZooming and !fmod(beat,bumpStrumBeat): screenBeat()
	if beat < 0: countDownTick(beat)
	iconBeat()
#endregion

#region Note Methods
func createStrum(i: int, opponent_strum: bool = true, pos: Vector2 = Vector2.ZERO) -> StrumNote:
	var strum = super.createStrum(i,opponent_strum,pos)
	FunkinGD.callOnScripts('onLoadStrum',[strum,opponent_strum])
	return strum

func createSplash(note) -> NoteSplash:
	var splash = super.createSplash(note)
	FunkinGD.callOnScripts('onSplashCreate',[splash])
	return splash
	
func spawnNote(note):
	super.spawnNote(note)
	FunkinGD.callOnScripts('onSpawnNote',[note])

func reloadNotes():
	var types = SONG.get('noteTypes')
	if types: for i in types: FunkinGD.addScript('custom_notetypes/'+i)
	super.reloadNotes()

func loadNotes():
	super.loadNotes()
	if _events_preload: 
		eventNotes = _events_preload.duplicate()
		_is_first_event_load = false
		return
	var events_to_load = SONG.get('events',[])
	var events_json = Paths.loadJson(Song.folder+'/events.json')
	
	if events_json:
		if events_json.get('song') is Dictionary: events_json = events_json.song
		events_to_load.append_array(events_json.get('events',[]))
	_events_preload = EventNote.loadEvents(events_to_load)
	eventNotes = _events_preload.duplicate()
	
func reloadNote(note: Note):
	super.reloadNote(note)
	FunkinGD.callOnScripts('onLoadNote',[note])
	if note.noteType: 
		FunkinGD.callScript(
			'custom_notetypes/'+note.noteType+'.gd',
			'onLoadThisNote',
			[note]
		)

func updateNote(note):
	var _return = super.updateNote(note)
	FunkinGD.callOnScripts('onUpdateNote',[note])
	return _return

func updateNotes() -> void: #Function from StrumState
	super.updateNotes()
	if !generateEvents: return
	while eventNotes and eventNotes[0].strumTime <= songPos:
		var event = eventNotes.pop_front()
		triggerEvent(event.event,event.variables)

func hitNote(note: Note, character: Variant = null) -> void:
	if not note: return
	super.hitNote(note)
	
	#Add Health if the note is from the player
	if !note.mustPress: camZooming = true
	if note.mustPress != playAsOpponent: health += note.hitHealth * note.ratingMod 
	
	var audio: AudioStreamPlayer = Conductor.get_node_or_null("PlayerVoice" if note.mustPress else "OpponentVoice")
	if !audio: audio = Conductor.get_node_or_null("Voice")
	if audio: audio.volume_db = 0
	
	FunkinGD.callOnScripts('goodNoteHit' if note.mustPress else 'opponentNoteHit',[note])
	FunkinGD.callOnScripts('hitNote',[note,character])

func noteMiss(note, character: Variant = null) -> void:
	health -= note.missHealth
	FunkinGD.callOnScripts('onNoteMiss',[note, character])
	
	var audio: AudioStreamPlayer = Conductor.get_node_or_null("Voice" if note.mustPress else "OpponentVoice")
	if audio: audio.volume_db = -80
	super.noteMiss(note)
#endregion

#region Script Methods
func _load_song_scripts():
	#Load Stage Script
	print('Loading Scripts from Scripts Folder')
	for i in Paths.getFilesAt('scripts',true,'.gd'): FunkinGD.addScript(i)
	
	print('Loading Stage Script')
	FunkinGD.addScript('stages/'+curStage+'.gd')
	
	
	print('Loading Song Folder Script')
	if Song.folder: for i in Paths.getFilesAt(Song.folder,true,'.gd'): FunkinGD.addScript(i)
	
	

func triggerEvent(event: StringName,variables: Variant) -> void:
	if !variables is Dictionary: return
	FunkinGD.callOnScripts('onEvent',[event,variables])
	FunkinGD.callScript('custom_events/'+event,'onLocalEvent',[variables])
#endregion

#region Song Methods
func startCountdown():
	if _countdown_started: return
	_countdown_started = true
	
	Conductor.songPosition = -stepCrochet*24.0
	var results = FunkinGD.callOnScripts("onStartCountdown",[],true)
	if FunkinGD.Function_Stop in results: return
	
	if skipCountdown: startSong()

func loadSong(data: String = song_json_file, songDifficulty: String = difficulty):
	super.loadSong(data,songDifficulty)
	loadStage(SONG.get('stage',''),false)
	
func loadSongObjects() -> void:
	camHUD.removeFilters()
	camOther.removeFilters()
	
	print('Loading Stage')
	Stage.loadSprites()
	#Load Scripts
	print('Loading Scripts')
	_load_song_scripts()
	
	print('Loading Song Objects')
	super.loadSongObjects()
	
	print('Loading Events')
	loadEventsScripts()
	
	print('Loading Characters')
	loadCharactersFromData()
	
	if !inModchartEditor:
		DiscordRPC.state = 'Now Playing: '+Song.songName
		DiscordRPC.refresh()
	
func loadEventsScripts():
	for i in EventNote.eventsFounded: FunkinGD.addScript('custom_events/'+i+'.gd')
	for i in Paths.getFilesAt(Paths.exePath+'/assets/custom_events',false,'.gd',true):
		FunkinGD.addScript('custom_events/'+i)
		
func startSong():
	super.startSong()
	if Conductor.songs: Conductor.songs[0].finished.connect(endSound)
	isSongStarted = true
	FunkinGD.callOnScripts('onSongStart')

func resumeSong() -> void:
	if isSongStarted: Conductor.resumeSongs()
	generateMusic = true
	process_mode = PROCESS_MODE_INHERIT
	onPause = false

func pauseSong(menu: bool = true) -> void:
	if !canPause: return
	generateMusic = false
	Conductor.pauseSongs()
	process_mode = Node.PROCESS_MODE_DISABLED
	
	if !menu or onPause: return
	
	onPause = true
	pauseState = PauseSubstate.new()
	pauseState.resume_song.connect(resumeSong.call_deferred)
	pauseState.restart_song.connect(restartSong.call_deferred)
	pauseState.exit_song.connect(endSound.call_deferred)
	
	Global.show_label_error('Adding to Scene')
	call_deferred('add_sibling',pauseState)

func restartSong(absolute: bool = true):
	Conductor.pauseSongs()
	if absolute: reloadPlayState(); return
	
	generateMusic = false
	var tween = create_tween().tween_property(Conductor,'songPosition',-stepCrochet*24.0,1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(
		func():
			for note in notes.members: note.kill()
			notes.members.clear()
			generateMusic = true
			unspawnNotes = _notes_preload.duplicate()
			eventNotes = _events_preload.duplicate()
			_resetScore()
			onPause = false
	)

func endSound() -> void:
	Conductor.pauseSongs()
	var results = FunkinGD.callOnScripts('onEndSong',[],true)
	if FunkinGD.Function_Stop in results or !canExitSong: return
	exitingSong = true
	canPause = false
	if isStoryMode and story_song_notes:
		loadNextSong()
	elif back_state: Global.swapTree(back_state.new(),true)

func loadNextSong():
	var newSong = story_songs[0]
	story_songs.remove_at(0)
	if !story_song_notes.has(newSong):
		newSong = loadSong()
func countDownTick(beat: int) -> void:
	if beat > 0: return
	elif beat == 0: startSong(); return
	
	var tick: int = countSounds.size() - absi(beat)
	if tick < 0 or tick >= countSounds.size(): return
	
	var folder: String = 'gameplay/countdown/'+('pixel/' if isPixelStage else 'funkin/')
	FunkinGD.playSound(folder+countSounds[tick]+introSoundsSuffix)
	FunkinGD.callOnScripts('onCountdownTick',[tick])
	
	if !countDownEnabled or !countDownImages[tick]: return
	
	var sprite = Sprite2D.new()
	if isPixelStage:
		sprite.texture = Paths.imageTexture('ui/countdown/pixel/'+countDownImages[tick])
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(6,6)
	else:
		sprite.texture = Paths.imageTexture('ui/countdown/funkin/'+countDownImages[tick])
		sprite.scale = Vector2(0.7,0.7)
	
	if !sprite.texture: return
	sprite.position = ScreenUtils.screenSize/2.0
	
	var tween = create_tween()
	tween.tween_property(sprite,'modulate:a',0.0,stepCrochet*0.004)
	tween.tween_callback(sprite.queue_free)
	camHUD.add(sprite)
	
	

##Called when the game gonna restart the song
func reloadPlayState():
	for n in notes.members: n.kill()
	var state = get_script().duplicate().new(song_json_file,difficulty)
	Global.swapTree(state,true)
	
	Global.onSwapTree.disconnect(destroy)
	Global.onSwapTree.connect(func():
		for vars in ['seenCutscene','playAsOpponent']: 
			state[vars] = get(vars)
		destroy(false)
	)
#endregion

#region Modding Methods
func chartEditor():
	var chart = ChartEditorScene.instantiate()
	Global.swapTree(chart,true)
	pauseSong(false)

func characterEditor():
	var editor = CharacterEditor.instantiate()
	editor.back_to = get_script()
	Global.swapTree(editor,true)
	pauseSong(false)
#endregion

#region Cutscene Methods
func startVideo(path: Variant, isCutscene: bool = true) -> VideoStreamPlayer:
	var video = path if path is VideoStreamTheora else Paths.video(path)
	if not video: return VideoStreamPlayer.new()
	if videoPlayer: videoPlayer.queue_free()
	
	videoPlayer = VideoStreamPlayer.new()
	
	camOther.add(videoPlayer)
	videoPlayer.stream = video
	videoPlayer.play()
	
	if not isCutscene:
		videoPlayer.finished.connect(func(): videoPlayer.queue_free())
		return videoPlayer
	
	canPause = false
	inCutscene = true
	videoPlayer.finished.connect(func():
		startCountdown()
		inCutscene = false
		videoPlayer.queue_free()
		canPause = true
		seenCutscene = true
		FunkinGD.callOnScripts('onEndCutscene',[path])
	)
	videoPlayer.resized.connect(func():
		var video_div = ScreenUtils.screenSize/videoPlayer.size
		var video_scale = minf(video_div.x,video_div.y)
		videoPlayer.scale = Vector2(video_scale,video_scale)
	)
	
	return videoPlayer

func skipVideo() -> void:
	if !videoPlayer: return
	FunkinGD.callOnScripts('onSkipCutscene')
	videoPlayer.finished.emit()
	
#endregion

func _unhandled_input(event: InputEvent):
	if event is InputEventKey:
		if event.pressed and not event.echo:
			match event.keycode:
				KEY_ENTER: if canPause and not onPause: pauseSong.call_deferred()
				KEY_7: if isModding: chartEditor()
				KEY_8: if isModding: characterEditor()
		FunkinGD.callOnScripts('onKeyEvent',[event])
		
func destroy(absolute: bool = true):
	FunkinGD.callOnScripts('onDestroy',[absolute])
	FunkinGD._clear_scripts()
	FunkinGD.game = null
	stageJson.clear()
	
	if absolute: _events_preload.clear()
	
	if exitingSong: ChartEditor.reset_values()
	Paths.extraDirectory = ''
	
	camHUD.removeFilters()
	camOther.removeFilters()
	Paths.clearLocalFiles()
	Paths.clearDirsCache()
	super.destroy(absolute)
	

#region Score Methods
func _resetScore():
	songScore = 0
	songMisses = 0
	sicks = 0
	goods = 0
	bads = 0
	shits = 0
	ratingPercent = 0
	updateScore()

func updateScore():
	super.updateScore()
	scoreTxt.text = 'Score: '+str(songScore)+' | Misses: '+str(songMisses)+ ' | Accurancy: '+str(int(ratingPercent*10)/10.0)+'%'+ratingFC
	FunkinGD.callOnScripts('onUpdateScore')
#endregion

#region Section Methods
func onSectionHit(sec: int = Conductor.section) -> void:
	if sec < 0: return
	
	var sectionData = ArrayHelper.get_array_index(SONG.get('notes',[]),sec)
	if !sectionData: return
	
	mustHitSection = !!sectionData.get('mustHitSection')
	gfSection = !!sectionData.get('gfSection')
	altSection = !!sectionData.get('altAnim')
	FunkinGD.mustHitSection = mustHitSection
	FunkinGD.gfSection = gfSection
	FunkinGD.altAnim = altSection
	
func detectSection() -> StringName:
	if gfSection: return 'gf'
	return 'boyfriend' if mustHitSection else 'dad'
#endregion

#region Character Methods
#Replaced in PlayState and PlayState3D
func changeCharacter(type: int = 0, character: StringName = 'bf') -> Object:
	updateIconsImage(healthBar_State)
	return

func onSectionHitOnce():
	if !isCameraOnForcedPos: moveCamera(detectSection())
	
static func get_character_type_name(type: int) -> StringName:
	match type:
		1: return 'dad'
		2: return 'gf'
		_: return 'boyfriend'

 #Replaced in PlayState and PlayState3D
func addCharacterToList(type,character) -> Node:return null


#Replaced in PlayState
func moveCamera(target: StringName = 'boyfriend') -> void:
	FunkinGD.callOnScripts('onMoveCamera',[target])
#endregion


#region Stage Methods
func loadStage(stage: StringName, loadScript: bool = true):
	if curStage == stage: return
	#Remove old stage script
	FunkinGD.removeScript('stages/'+curStage)
	FunkinGD.curStage = stage
	curStage = stage
	
	stageJson = Stage.loadStage(stage)
	isPixelStage = stageJson.isPixelStage
	
	if loadScript: 
		FunkinGD.addScript('stages/'+stage)
		Stage.loadSprites()
	
#endregion



#region Combo Methods
func createCombo(rating: String) -> Combo:
	var combo = super.createCombo(rating)
	if combo: FunkinGD.callOnScripts('onComboCreated',[combo,rating])
	return combo

#region General Methods
func get_hud_elements() -> Array[Node]:
	if hideHud: return []
	elif timeBarType == 'Disabled': return [scoreTxt,iconP1,iconP2,healthBar]
	return [timeTxt,scoreTxt,timeBar,iconP1,iconP2,healthBar]

func seek_to(time: float, kill_notes: bool = true):
	skipCountdown = true
	super.seek_to(time,kill_notes)


#region Game Over Methods
func gameOver():
	FunkinGD.inGameOver = true
	inGameOver = true
	pauseSong(false)

func isGameOverEnabled() -> bool:
	return canGameOver and health < 0.0 \
			and not inGameOver\
			and not FunkinGD.Function_Stop in FunkinGD.callOnScripts('onGameOver',[],true)

func clear():
	super.clear()
	camHUD.removeFilters()
	camOther.removeFilters()
	
static func _reset_values():
	super._reset_values()
	_events_preload.clear()
	EventNote.eventsFounded.clear()
	EventNote.event_variables.clear()
#endregion

#region Health Methods
func set_health(value: float):
	value = clamp(value,-1.0,2.0)
	#if health == value: return
	health = value
	
	if isGameOverEnabled(): gameOver(); return
	
	var progress_h = value/2.0
	healthBar.progress = progress_h if playAsOpponent else 1.0 - progress_h
	
	var bar_state = 0.0
	if progress_h >= 0.7: bar_state = IconState.WINNING
	elif progress_h <= 0.3: bar_state = IconState.LOSING
	else: bar_state = IconState.NORMAL
	
	if bar_state != healthBar_State:
		healthBar_State = bar_state
		updateIconsImage(healthBar_State)

##Set HealthBar angle(in degrees). See also [method @GlobalScope.rad_to_deg]
func setHealthBarAngle(angle: float):
	healthBar.rotation_degrees = angle
	updateIconsPivot()
#endregion

#region Setters
func _set_hide_hud(hide: bool):
	hideHud = false
	for i in get_hud_elements(): if i: i.visible = !hide
	hideHud = hide
	
func _set_play_opponent(isOpponent: bool = playAsOpponent) -> void:
	healthBar.flip = !isOpponent
	super._set_play_opponent(isOpponent)
#endregion
