extends Node

@export_category('Notes')
const Song = preload("res://source/backend/Song.gd")
const NoteSplash: GDScript = preload("res://source/objects/Notes/NoteSplash.gd")
const Note: GDScript = preload("res://source/objects/Notes/Note.gd")
const EventNote: GDScript = preload("res://source/objects/Notes/EventNote.gd")
const NoteSustain: GDScript = preload("res://source/objects/Notes/NoteSustain.gd")

const NoteHit: GDScript = preload("res://source/objects/Notes/NoteHit.gd")
const StrumNote: GDScript = preload('res://source/objects/Notes/StrumNote.gd')

const Combo: GDScript = preload('res://source/objects/UI/Combo.gd')
const ComboStrings: PackedStringArray = ['sick','good','bad','shit']
const ComboNumbers: PackedStringArray = ['0','1','2','3','4','5','6','7','8','9']
const StrumOffset: float = 112.0

static var COMBO_PIXEL_SCALE: Vector2 = Vector2(6,6)
static var COMBO_SCALE: Vector2 = Vector2(0.8,0.8)

static var isModding: bool = true
static var inModchartEditor: bool = false
static var week_data: Dictionary = {}

const ChartEditor = preload("res://source/states/ChartEditor/ChartEditor.gd")

@export_group("Song Data")

@export var song_folder: String = ''
@export var song_json_file: String = ''
@export var difficulty: String = ''

var autoStartSong: bool = false ##Start the Song when the Song json is loaded. Used in PlayState

##If this is [code]false[/code], will disable the notes, 
##making them stretched and not being created
var generateMusic: bool = true
var exitingSong: bool = false
var clear_song_after_exiting: bool = true

var songSpeed: float: set = set_song_speed 

var songLength: float = 0.0

static var SONG: Dictionary:
	set(dir): Conductor.songJson = dir
	get(): return Conductor.songJson ##The data of the Song.

var keyCount: int = 4: ##The amount of notes that will be used, default is [b]4[/b].
	set(value): 
		keyCount = value
		var length = keyCount*2
		hitNotes.resize(value)
		defaultStrumPos.resize(length)
		defaultStrumAlpha.resize(length)
		grpNoteHoldSplashes.resize(length)
		
var mustHitSection: bool = false ##When the focus is on the opponent.
var gfSection: bool = false ##When the focus is on the girlfriend.


var stepCrochet: float: ##The offset which every step.
	get():
		return Conductor.stepCrochet
	
var songPos: float: 
	get(): return Conductor.songPositionDelayed

@export_group("Notes")
var strumLineNotes := SpriteGroup.new()#Strum's Group.
var opponentStrums: SpriteGroup = SpriteGroup.new() ##Strum's Oponnent Group.
var playerStrums: SpriteGroup = SpriteGroup.new() ##Strum's Player Group.
var extraStrums: Array[StrumNote] = []

 ##Returns the player strum. 
##If [member playAsOpponent] = true, returns [member opponentStrums], else, returns [member playerStrums]
var current_player_strum: Array = playerStrums.members

var uiGroup: SpriteGroup = SpriteGroup.new() ##Hud Group.

var unspawnNotes: Array[Note] = [] ##Unspawn notes, the array is reversed for more performace.
var unspawnNotesLength: int = 0
var unspawnIndex: int = 0
var respawnIndex: int = 0
var respawnTime: float = -200
var respawnNotes: bool = false
var notes: SpriteGroup = SpriteGroup.new()


const NOTE_SPAWN_TIME: float = 1000

var noteSpawnTime = NOTE_SPAWN_TIME

var hitNotes: Array[Note] = []
var canHitNotes: bool = true

static var _notes_preload: Array[Note]
static var _events_preload: Array[Dictionary]

var _splashes_loaded: Dictionary = {}

var splashesEnabled: bool = ClientPrefs.data.splashesEnabled and ClientPrefs.data.splashAlpha > 0
var opponentSplashes: bool = splashesEnabled and ClientPrefs.data.opponentSplashes
var splashHoldSpeed: float = 0.0
var grpNoteSplashes: SpriteGroup = SpriteGroup.new() ##Note Splashes Group.
var grpNoteHoldSplashes: Array[NoteSplash] = [] ##Note Hold Splashes Group.



static var isPixelStage: bool = false
@export var arrowStyle: String = 'funkin'
@export var splashStyle: String = 'NoteSplashes'
@export var splashHoldStyle: String = 'HoldNoteSplashes'

#region Rating Data
var songScore: int = 0 ##Score
var combo: int = 0 ##Combo
var sicks: int = 0 ##Sick's count
var goods: int = 0 ##Good's count
var bads: int = 0 ##Bad's count
var shits: int = 0 ##Shit's count
var songMisses: int = 0 ##Misses count

var defaultStrumPos: PackedVector2Array = []
var defaultStrumAlpha: PackedFloat32Array = []

##Rating String, 
##can be "SFC" (just [b]SICK[/b] hits), "GFC"(Just hitting "Sick" and Good "combos") and "FC"(Sick,Good and Bad)
var ratingFC: String = '' 

var ratingPercent: float = 0.0##Percent of the Rating.

var noteHits: int = 0 ##Total Note hits.
var totalNotes: int = 0 ##Total Notes.
var noteScore: int = 350 ##Hit's Score.
#endregion

@export_group("Play Options")


##Play as Opponent, reversing the sides.
@export var playAsOpponent: bool = ClientPrefs.data.playAsOpponent: set = _set_play_opponent

##When activate, the notes will be hitted automatically.
@export var botplay: bool = ClientPrefs.data.botPlay: set = _set_botplay

@export var downScroll: bool = ClientPrefs.data.downscroll: set = _set_downscroll
@export var middleScroll: bool = ClientPrefs.data.middlescroll: set = _set_middlescroll

@export_category("Combo Options")
@export var showCombo: bool = true ##If false, the Combo count will not be showed when the player hits the note.
@export var showRating: bool = true ##If false, the Combo Sprites(Sick,Good,Bad,Shit) will not be showed when the player hits the note.
@export var showComboNum: bool = true##If false, the combo will not be showed.

var _comboPreloads: Dictionary = {}

##Android System
var touch_state

var Inst: AudioStreamPlayer:
	get():
		return ArrayHelper.get_array_index(Conductor.songs,0)

var vocals: AudioStreamPlayer:
	get():
		return ArrayHelper.get_array_index(Conductor.songs,1)

signal hit_note
func _init(json_file: StringName = '', song_difficulty: StringName = ''):
	add_child(uiGroup)
	uiGroup.name = 'uiGroup'
	
	
	song_json_file = json_file.get_file()
	difficulty = song_difficulty
	
	uiGroup.add(strumLineNotes)
	uiGroup.add(playerStrums)
	uiGroup.add(opponentStrums)
	uiGroup.add(notes)
	uiGroup.add(grpNoteSplashes)
	
	grpNoteSplashes.name = 'grpNoteSplashes'
	
	opponentStrums.name = 'opponentStrums'
	playerStrums.name = 'playerStrums'
	strumLineNotes.name = 'strumLineNotes'
	
	notes.name = 'notes'
	

func _ready():
	loadSong()
	loadSongObjects()
	if Paths.is_on_mobile: createMobileGUI()
	_precache_combo()
	if autoStartSong: startSong()

func createMobileGUI():
	##HitBox
	touch_state = load("res://source/objects/Mobile/Hitbox.gd").new()
	add_child(touch_state)
	touch_state.z_index = 1
	
func precache_images():
	if ClientPrefs.data.comboStacking: _precache_combo()

func _precache_combo():
	for i in ComboStrings:
		var comboTex: Texture2D = Paths.imageTexture(i)
		if !comboTex: continue
		var combo = Combo.new()
		combo.texture = comboTex
		#combo.size = comboTex.get_size()
		combo.scale = COMBO_SCALE
		_comboPreloads[i] = combo

	for i in ComboNumbers:
		var number_tex = Paths.imageTexture('num'+i)
		if !number_tex: continue
		var number = Combo.new()
		number.scale = COMBO_SCALE
		number.texture = number_tex
		_comboPreloads[i] = number
	
	#Pixel Combos
	for i in ComboStrings:
		var pixel_tex = Paths.imageTexture('pixelUI/'+i+'-pixel')
		if !pixel_tex: continue
		var combo_pixel = Combo.new()
		combo_pixel.texture = pixel_tex
		#combo_pixel.size = pixel_tex.get_size()
		combo_pixel.scale = COMBO_PIXEL_SCALE
		combo_pixel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_comboPreloads[i+'_pixel'] = combo_pixel
		
	#Pixel Numbers
	for i in ComboNumbers:
		var pixel_tex = Paths.imageTexture('pixelUI/num'+i+'-pixel')
		if !pixel_tex: continue
		
		var number_pixel = Combo.new()
		number_pixel.texture = pixel_tex
		#number_pixel.size = pixel_tex.get_size()
		number_pixel.scale = COMBO_PIXEL_SCALE
		number_pixel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_comboPreloads[i+'_pixel'] = number_pixel
	
#region Song Methods
func loadSong(data: String = song_json_file, songDifficulty: String = difficulty):
	if !SONG: Conductor.loadSong(data,songDifficulty)
	keyCount = SONG.get('keyCount',4)
	FunkinGD.keyCount = keyCount
	
	if !SONG: return
	Conductor.loadSongsStreams()
	
	set_song_speed(SONG.speed)
	
	if !SONG.notes: return
	mustHitSection = SONG.notes[0].mustHitSection
	gfSection = SONG.notes[0].get('gfSection',false)

##Load song data. Used in PlayState
func loadSongObjects():
	var arrow_s = SONG.get('arrowStyle')
	var splash_s = SONG.get('splashType')
	var hold_s = SONG.get('holdSplashType')
	
	if arrow_s: arrowStyle = arrow_s
	else: arrowStyle = 'pixel' if isPixelStage else 'funkin'
	
	print(arrow_s)
	if splash_s: splashStyle = splash_s
	if hold_s: splashHoldStyle = hold_s
	_create_strums()
	respawnIndex = 0
	unspawnIndex = 0
	if !SONG: return
	loadNotes()

func loadNotes():
	if !_notes_preload:  _notes_preload = getNotesFromData(SONG)
	unspawnNotes = _notes_preload.duplicate()
	unspawnNotesLength = unspawnNotes.size()
	reloadNotes()
	
func clearSongNotes():
	for i in notes.members: i.queue_free()
	notes.members.clear()
	respawnIndex = 0
	unspawnIndex = 0
	unspawnNotes.clear()

func set_song_speed(value):
	songSpeed = value
	noteSpawnTime = NOTE_SPAWN_TIME/(value/2.0)

##Begins the song. See also [method loadSong].
func startSong() -> void: 
	if Conductor.songs:
		var length = Conductor.songs.size()
		length -= 1
		var songsArray: Array[AudioStreamPlayer] = Conductor.songs
		var songs = ['Inst','voices','voices_opponent']
		var songId: int = 0
		
		for i in songs:
			if songId > length: break
			var audio = songsArray[songId]
			set(i,audio)
			audio.seek(0.0)
			audio.play(0.0)
			songId += 1
			pass
		songLength = songsArray[0].stream.get_length()*1000.0

##Seek the Song Position to [param time] in miliseconds.[br]
##If [param kill_notes] is [code]true[/code], the notes above the [param time] will be removed.
func seek_to(time: float, kill_notes: bool = true):
	Conductor.setSongPosition(time)
	if !kill_notes: return
	
	var time_offset: float = time + 1000
	for i in notes.members: if i.strumTime < time_offset: i.kill()
	
	while unspawnIndex < unspawnNotes.size():
		if unspawnNotes[unspawnIndex].strumTime > time_offset: break
		unspawnIndex += 1
	
#endregion

func updateStrumsPosition():
	var screen_center = ScreenUtils.screenCenter
	#var screen_offset = ScreenUtils.screenOffset
	
	var key_div = keyCount/2.0
	
	var strum_off = StrumOffset
	
	var strumsSpace = (StrumOffset*keyCount)
	var margin_scale: float = minf(
		ScreenUtils.screenWidth/strumsSpace - 2.0,
		1.0
	)
	var margin_offset: float = strum_off*margin_scale
	defaultStrumAlpha.fill(1.0)
	
	var first_op_pos = screen_center.x
	var strum_first_pos = screen_center.x
	
	
	if middleScroll:  strum_first_pos -= strum_off*(key_div)
	else: 
		strum_first_pos += margin_offset
		first_op_pos -= margin_offset + strum_off*(keyCount)
	
	#Opponent Position
	var op_middle_offset = strum_off*(key_div-1)*margin_scale
	for i in keyCount:
		var strumPos: float = first_op_pos
		var strumIndex: int = i
		
		if middleScroll:
			if i < key_div: strumPos += strum_off*(i-keyCount) - op_middle_offset
			else: strumPos += strum_off*i + op_middle_offset
			if playAsOpponent: strumIndex += keyCount
			defaultStrumAlpha[strumIndex] = 0.35
		else: strumPos += strum_off*i
		defaultStrumPos[strumIndex].x = strumPos
		
	
	#Player Position
	for i in keyCount:
		var strumIndex: int = (i+keyCount) if not (middleScroll and playAsOpponent) else i 
		var strumPos: float = strum_first_pos
		strumPos += strum_off*i
		defaultStrumPos[strumIndex].x = strumPos
	updateStrumsY()
func updateStrumsY():
	var strumY = ScreenUtils.screenHeight - 150.0 if downScroll else 50.0
	var index = 0
	while index < defaultStrumPos.size():
		defaultStrumPos[index].y = strumY
		index += 1
func reset_strums_state():
	for i in (keyCount*2):
		var strum = strumLineNotes.members[i]
		strum._position = defaultStrumPos[i]
		strum.modulate.a = defaultStrumAlpha[i]

func _create_strums() -> void:
	for i in strumLineNotes.members: i.queue_free()
	
	strumLineNotes.members.clear()
	playerStrums.members.clear()
	opponentStrums.members.clear()
	
	updateStrumsPosition()
	for i in (keyCount*2):
		var opponent_strum = i < keyCount
		var strum = createStrum(i,opponent_strum,defaultStrumPos[i])
		strum.mustPress = (playAsOpponent == opponent_strum and not botplay)
		strum.modulate.a = defaultStrumAlpha[i]
	
func createStrum(i: int, opponent_strum: bool = true, pos: Vector2 = Vector2.ZERO) -> StrumNote:
	i %= keyCount
	var strum = StrumNote.new(i)
	strum.loadFromStyle(arrowStyle)
	strum.name = "StrumNote"+str(i)
	
	strum.mustPress = !opponent_strum and !botplay
	if opponent_strum: opponentStrums.add(strum)
	else: playerStrums.add(strum)
	
	strum.downscroll = downScroll
	strum._position = pos
	
	strumLineNotes.add(strum)
	return strum

func _process(delta: float) -> void:
	if generateMusic: updateNotes()

#region Note Functions
func updateRespawnNotes():
	while respawnIndex:
		var note = unspawnNotes[respawnIndex-1]
		if !note: respawnIndex -= 1; continue
		var time = note.strumTime - songPos
		
		if time > 0 and time < noteSpawnTime: 
			note.resetNote()
			spawnNote(note)
			updateNote(note)
			respawnIndex -= 1
			continue
		break
		
	

func updateNotes():
	if unspawnNotes:
		while unspawnIndex < unspawnNotesLength:
			var unspawn: Note = unspawnNotes[unspawnIndex]
			if unspawn and unspawn.strumTime - songPos > noteSpawnTime: break
			unspawnIndex += 1
			spawnNote(unspawn)
	
	if respawnNotes:
		while respawnIndex < unspawnIndex:
			var note = unspawnNotes[respawnIndex]
			#var time = note.strumTime - songPos
			if !note.wasHit and !note.missed: break
			respawnIndex += 1
	
	#Detect notes that can hit
	hitNotes.fill(null)
	if !notes.members: return
	
	var members = notes.members
	var note_index: int = members.size()
	if respawnNotes:
		while note_index:
			note_index -= 1
			var note = members[note_index]
			if note.strumTime - songPos > noteSpawnTime:
				note.kill()
				unspawnIndex -= 1
			elif updateNote(note): continue
			members.remove_at(note_index)
	
	else:
		while note_index:
			note_index -= 1
			if !updateNote(members[note_index]): members.remove_at(note_index)
	
	if not botplay and canHitNotes:
		for i: Note in hitNotes:
			if !i: continue
			if Input.is_action_just_pressed(i.hit_action): hitNote(i)
			hitNotes[i.noteData] = null
	

func spawnNote(note: Note) -> void: ##Spawns the note
	if !note: return
	if !note.noteGroup: addNoteToGroup(note,notes); return
	notes.members.append(note)
	addNoteToGroup(note,note.noteGroup)
	
func addNoteToGroup(note: Note, group: Node) -> void:
	var isGroup = group is SpriteGroup
	if isGroup:
		if note.isSustainNote: group.insert(0,note)
		else: group.add(note)
		return
	group.add_child(note)
	if note.isSustainNote and note.noteGroup == note.noteParent.noteGroup: 
		group.move_child(note,note.noteParent.get_index())

func updateNote(note: Note):
	if !note or !note._is_processing: return false
	
	var strum = note.strumNote
	var playerNote: bool
	playerNote = note.autoHit or !botplay and (strum.mustPress if strum else false)
	note.noteSpeed = songSpeed
	note.updateNote()
	
	if not (note.isSustainNote and note.isBeingDestroyed) and note.strumTime - songPos <= note.missOffset:
		if not note.missed and playerNote and not note.ignoreNote: noteMiss(note) 
		return true
	if !note.canBeHit: return true
	if !canHitNotes: return true
	
	if !playerNote:
		if not note.ignoreNote and (note.isSustainNote or note.distance <= 0.0): hitNote(note)
		return true
	
	if note.isSustainNote:
		if Input.is_action_pressed(note.hit_action): hitNote(note)
		return true
	
	var lastN = hitNotes[note.noteData]
	if !lastN or absf(note.distance) < absf(lastN.distance): hitNotes[note.noteData] = note
	elif note.distance == lastN.distance and Input.is_action_just_pressed(note.hit_action): hitNote(note)
	return true
	

##Called when the hits a [NoteBase] 
func hitNote(note: Note) -> void:
	if !note: return
	var mustPress: bool = note.mustPress
	var playerNote: bool = mustPress != playAsOpponent
	var strumAnim = 'confirm'
	
	note.wasHit = true
	note.judgementTime = songPos
	
	var strum: StrumNote = note.strumNote
	
	if playerNote:
		if not note.isSustainNote: addScoreFromNote(note)
		else: 
			sicks += 1; 
			songScore += 10
			if note.isEndSustain: strumAnim = 'press'
			
	else:  
		if note.isEndSustain: 
			_disableHoldSplash(getStrumDirection(strum.data,mustPress))
	
	if strum and note.strumConfirm:
		if strum.mustPress or note.sustainLength:
			strum.return_to_static_on_finish = false
			strum.animation.play(strumAnim,true)
		else:
			strum.strumConfirm(strumAnim)
			strum.return_to_static_on_finish = true
		
	if splashAllowed(note): createSplash(note)
	note.killNote()

func reloadNotes(): 
	for i in unspawnNotes: 
		reloadNote(i)
	
func reloadNote(note: Note):
	#note.texture = arrowSkin
	note.loadFromStyle(arrowStyle)
	var noteStrum: StrumNote = strumLineNotes.members.get((note.noteData + keyCount) if note.mustPress else note.noteData)
	note.strumNote = noteStrum
	note.isPixelNote = isPixelStage
	note.resetNote()
	
	
	if note.isSustainNote: 
		note.flipY = noteStrum.downscroll
		if splashHoldStyle: note.noteSplashData.style = splashHoldStyle
	else:
		if splashStyle: note.noteSplashData.style = splashStyle


##Called when the player miss a [Note]
func noteMiss(note) -> void:
	if !note:return
	
	note.missed = true
	note.judgementTime = songPos
	
	combo = 0
	songMisses += 1
	if !note.ratingDisabled: songScore -= 10.0
	totalNotes += 1
	updateScore()
	
	if !ClientPrefs.data.notHitSustainWhenMiss: return
	for sus in note.sustainParents:
		if !sus: continue
		sus.blockHit = true
		sus.ignoreNote = true
		sus.modulate.a = 0.3
#endregion

#region Splash Methods
func createSplash(note) -> NoteSplash: ##Create Splash
	var splashData = note.noteSplashData
	var style = splashData.style
	var type = splashData.type
	var strum: StrumNote = note.strumNote
	var splashGroup: Node = splashData.parent
	
	if !strum or !strum.visible: return
	if !style: style = splashStyle
	
	var prefix = splashData.prefix
	
	var splash_type = NoteSplash.SplashType.NORMAL
	if note.isSustainNote:
		if note.isEndSustain: splash_type = NoteSplash.SplashType.HOLD_COVER_END
		else: splash_type = NoteSplash.SplashType.HOLD_COVER
	
	var splash: NoteSplash = _getSplashAvaliable(style,type,prefix,splash_type)
	if !splash:
		splash = _createNewSplash(style,type,prefix,splash_type)
		if !splash: return
		
		if splashGroup:
			grpNoteSplashes.members.append(splash)
			splashGroup.add_child(splash)
		else: grpNoteSplashes.add(splash)
	else: 
		splash.visible = true
		if splashGroup: splash.reparent(splashGroup,false)
		elif splash._is_custom_parent: splash.reparent(grpNoteSplashes,false)
	splash._is_custom_parent = !!splashGroup
	splash.strum = strum
	splash.isPixelSplash = isPixelStage
	 
	match splash_type:
		NoteSplash.SplashType.HOLD_COVER:
			var direction = getStrumDirection(strum.data,note.mustPress)
			_disableHoldSplash(direction)
			grpNoteHoldSplashes[direction] = splash
			
			splash.animation.setAnimDataValue(
				'splash-hold',
				'speed_scale',
				minf(100.0/stepCrochet,1.5)
			)
			
			splash.animation.play('splash',true)
			splash._updatePos()
			return splash
		NoteSplash.SplashType.HOLD_COVER_END:
			_disableHoldSplash(getStrumDirection(strum.data,note.mustPress))
	
	splash._updatePos()
	splash.animation.play_random(true)
	splash.position = strum._position - splash.offset
	return splash
	
	
	
func getStrumDirection(direction: int, mustPress: bool = false) -> int:
	return (direction + keyCount) if mustPress else direction
	
func _disableHoldSplash(id: int = 0) -> void:
	var splash = grpNoteHoldSplashes[id]
	if !splash: return
	splash.visible = false
	grpNoteHoldSplashes[id] = null

func _createNewSplash(style: String, type: String, prefix: StringName, splash_type: NoteSplash.SplashType) -> NoteSplash:
	var splash = NoteSplash.new()
	splash.style = style
	splash.splashType = splash_type
	
	if !splash.loadSplash(type,prefix): return
	
	_saveSplashType(style,type,prefix)
	_splashes_loaded[style][type][prefix].append(splash)
	
	if splash_type != NoteSplash.SplashType.HOLD_COVER:
		splash.animation.animation_finished.connect(
			func(_anim): splash.visible = false
		)
	return splash

func _saveSplashType(style: StringName, type: String, prefix: String = '') -> bool:
	var added: bool = false 
	if !_splashes_loaded.has(style):
		_splashes_loaded[style] = {}
		added = true
	if type and !_splashes_loaded[style].has(type):
		_splashes_loaded[style][type] = {}
		added = true
	if prefix and !_splashes_loaded[style][type].has(prefix):
		_splashes_loaded[style][type][prefix] = Array([],TYPE_OBJECT,'Node2D',NoteSplash)
		added = true
	return added
	
func _getSplashAvaliable(style: StringName, type: String, prefix: String, splash_type: NoteSplash.SplashType) -> NoteSplash:
	if _saveSplashType(style,type,prefix): return
	for s in _splashes_loaded[style][type][prefix]:
		if !s.visible and s.splashType == splash_type: return s
	return
	
func splashAllowed(note: Note) -> bool:
	return splashesEnabled and !note.noteSplashData.disabled and note.ratingMod <= 1 and \
			(note.strumNote and note.mustPress != playAsOpponent or opponentSplashes or \
			note.isSustainNote and not note.isEndSustain)

#endregion

#region Score Methods
func addScoreFromNote(note: Note):
	noteHits += 1
	totalNotes += 1
	if note.ratingDisabled: return
	match note.ratingMod:
		1: sicks += 1
		2: goods += 1
		3: bads += 1
		_: shits += 1
	songScore += noteScore * note.ratingMod
	combo += 1
	
	if showRating: createCombo(note.rating)
	if showCombo and combo >= 10: createNumbers()
	updateScore()
##Update the score data.
func updateScore() -> void:
	if noteHits:
		if !totalNotes: ratingPercent = 0.0
		else:
			var realNoteHits = noteHits
			realNoteHits -= 0.25 * goods
			realNoteHits -= 0.5 * bads
			realNoteHits -= 0.75 * shits
			ratingPercent = (realNoteHits/totalNotes)*100.0
	
	else: ratingPercent = 0.0
	
	if songMisses: ratingFC = ''
	elif bads:ratingFC = '(FC)'
	elif goods: ratingFC = '(GFC)'
	elif sicks: ratingFC = '(SFC)'
	else: ratingFC = '(N/A)'
	
##Create the Combo Image
func createCombo(rating: String) -> Combo:
	if isPixelStage and not rating.ends_with('_pixel'):
		rating += '_pixel'
	if !_comboPreloads.has(rating): return
	
	var comboSprite = _comboPreloads[rating].duplicate()
	uiGroup.add(comboSprite)
	comboSprite.name = 'Combo'
	comboSprite.position = ScreenUtils.screenSize/2.0 - Vector2(ClientPrefs.data.comboOffset[0],ClientPrefs.data.comboOffset[1])
	return comboSprite

##Create the Numbers combo
func createNumbers(number: int = combo):
	var stringCombo = str(number)
	var stringLength = maxi(3,stringCombo.length())
	while stringCombo.length() < stringLength: stringCombo = '0'+stringCombo
	
	var index: int = 0
	for i in stringCombo:
		i = i+'_pixel' if isPixelStage else i
		if not i in _comboPreloads: continue
		
		var comboNumber = _comboPreloads[i].duplicate()
		comboNumber.position = ScreenUtils.screenSize/2.0 - Vector2(
			ClientPrefs.data.comboOffset[2] + 5.0 - 50.0*index,
			ClientPrefs.data.comboOffset[3]
		)
		comboNumber.name = i
		uiGroup.add(comboNumber)
		
		index += 1
#endregion

##Remove the state
func destroy(absolute: bool = true):
	Conductor.clearSong(exitingSong)
	
	Paths.clearLocalFiles()
	if absolute: _reset_values()
	else: for note in notes.members: note.kill()
	
	if isModding: NoteSplash.splash_datas.clear()
	queue_free()

func _set_botplay(is_botplay: bool) -> void:
	botplay = is_botplay
	if is_botplay:
		for i in strumLineNotes.members: i.mustPress = false
		return
	updateStrumsMustPress()

func updateStrumsMustPress():
	var strums = strumLineNotes.members
	if !strums: return
	
	for key in strums.size():
		var mustPress = key < keyCount
		strums[key].mustPress = false if botplay else mustPress and playAsOpponent or !mustPress and !playAsOpponent
	
func _set_play_opponent(isOpponent: bool = playAsOpponent) -> void:
	if playAsOpponent == isOpponent: return
	playAsOpponent = isOpponent
	
	updateStrumsMustPress()
	
	current_player_strum = (opponentStrums if isOpponent else playerStrums).members
	
	if middleScroll: updateStrumsPosition()
	
func _set_downscroll(value):
	if downScroll == value: return
	downScroll = value
	FunkinGD.downscroll = value
	updateStrumsY()

func _set_middlescroll(value):
	if middleScroll == value: return
	middleScroll = value
	FunkinGD.middlescroll = value
	updateStrumsPosition()
	
const noteSusVars: PackedStringArray = [
	'noteData',
	'noteType',
	'gfNote',
	'mustPress',
	'animSuffix',
	'noAnimation',
	'isPixelNote',
]

##Load Notes from the Song.[br][br]
##[b]Note:[/b] This function have to be call [u]when [member SONG] and [member keyCount] is already setted.[/u]
static func getNotesFromData(songData: Dictionary = {}) -> Array[Note]:
	var _notes: Array[Note] = []
	var notesData: Array = songData.get('notes',[])
	if !notesData: return []
	
	var bpmSection: int = songData.get('bpm',0.0)
	var keyCount: int = songData.get('keyCount',4)
	
	var sectionCrochet: float = 60000.0/bpmSection # 60 seconds * 1000
	var sectionStep: float = sectionCrochet/4.0
	
	
	var types_founded: PackedStringArray = PackedStringArray()
	for section: Dictionary in notesData:
		if section.changeBPM:
			bpmSection = section.bpm
			sectionCrochet = Conductor.get_crochet(bpmSection)
			sectionStep = sectionCrochet/4.0
			
		var altAnim = section.get("altAnim")
		
		for noteSection in section.sectionNotes:
			var note: NoteHit = createNoteFromData(noteSection,section,keyCount)
			var susLength = ArrayHelper.get_array_index(noteSection,2,0)
			if susLength is float and susLength >= sectionStep: 
				note.sustainLength = susLength
			if !_insert_note_to_array(note,_notes): continue
			
			if altAnim: note.animSuffix = '-alt'
			if note.noteType: types_founded.append(note.noteType)
			
			if !note.sustainLength: continue
			
			#Create Sustain
			var susNotes: Array[NoteSustain] = note.sustainParents
			var noteStrum = noteSection[0]
			for i in (susLength/sectionStep):
				var step = sectionStep*i
				var length = minf(sectionStep, susLength - step)
				var sus = createSustainFromNote(note,length)
				sus.strumTime = noteStrum + step
				_insert_note_to_array(sus,_notes)
				susNotes.append(sus)
			
			var firstSus = susNotes[0]
			firstSus.noteSplashData.disabled = false
			firstSus.noteSplashData.sustain = true
			var lastSus: NoteSustain = susNotes.back()
			var susEnd: NoteSustain = createSustainFromNote(note,0,true)
			susEnd.strumTime = lastSus.strumTime + lastSus.sustainLength
			susEnd.noteSplashData.disabled = false
			_insert_note_to_array(susEnd,_notes)
			susNotes.append(susEnd)
	
	
	var type_unique: PackedStringArray = songData.get_or_add('noteTypes',PackedStringArray())
	for i in types_founded: if not i in type_unique: type_unique.append(i)
	return _notes

static func _insert_note_to_array(note: Note, array: Array) -> bool:
	if !note: return false
	if !array:  array.append(note); return true
	var index = array.size()
	while index > 0:
		var prev_note = array[index-1]
		if note.strumTime <= prev_note.strumTime:
			index -= 1
			continue
		array.insert(index,note)
		return true
	array.push_front(note)
	return true
	
static func createNoteFromData(data: Array, sectionData: Dictionary, keyCount: int = 4) -> NoteHit:
	var noteData = int(data[1])
	if noteData < 0: return
	
	var note = NoteHit.new(noteData%keyCount)
	var mustHitSection = sectionData.mustHitSection
	var gfSection = sectionData.gfSection
	var type = ArrayHelper.get_array_index(data,3)
	
	note.strumTime = data[0]
	note.mustPress = mustHitSection and noteData < keyCount or not mustHitSection and noteData >= keyCount
	if type and type is String: 
		note.noteType = type
		note.gfNote = gfSection and note.mustPress == mustHitSection or note.noteType == 'GF Sing'
	else: note.gfNote = gfSection and note.mustPress == mustHitSection
	return note

static func createSustainFromNote(note: Note,length: float, isEnd: bool = false) -> NoteSustain:
	var sus: NoteSustain = NoteSustain.new(note.noteData,length)
	sus.noteSplashData.disabled = true
	sus.noteParent = note
	sus.isEndSustain = isEnd
	for noteVars in noteSusVars: sus[noteVars] = note[noteVars]
	sus.hitHealth /= 2.0
	#sus.multAlpha = 0.7
	return sus

func clear(): clearSongNotes() #Replaced in PlayStateBase
	
static func _reset_values():
	inModchartEditor = false
	isPixelStage = false
	_notes_preload.clear()
