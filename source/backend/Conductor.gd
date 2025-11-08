@tool
extends Node

const StreamNames = ["Inst","OpponentVoice","Voice"]
const Song = preload("res://source/backend/Song.gd")

var songPosition: float = 0.0: set = _set_song_position

var songPositionDelayed: float = 0.0 #songPosition - ClientPrefs.data.songOffset
var songPositionSeconds: float = 0.0 ##[param songPosition] in seconds.

var crochet: float = 0.0
var stepCrochet: float = 0.0
var sectionCrochet: float = 0.0

var songLength: float = 0.0
var step: int = 0: set = set_step

var step_float: float = 0.0: 
	set(value): step_float = value; step = int(value)

var beat: int = 0: set = set_beat

var beat_float: float = 0:
	set(value): beat_float = value; beat = int(value)

var section: int = 0: set = set_section

var section_float: float = 0.0:
	set(value): section_float = value; section = int(value)
		
var bpmChanges: Array[Dictionary] = []

var bpm: float = 0.0: set = set_bpm

var bpm_index: int = -1: set = setBpmChangeIndex
var step_offset: float = 0
var beat_offset: float = 0
var section_offset: float = 0
var section_beats_offset: float = 0.0

var songs: Array[AudioStreamPlayer] = [] #[Inst,Opponent,Player]

var jsonDir: String = ''
var songJson: Dictionary = {}
var songDefaultBpm: float = 0.0
var fixVoicesSync: bool = false

var music_pitch: float = 1.0

var is_playing: bool = false

signal step_hit ##When a step is hitt.

## Emitted every time the section is passed during a change.
## If the section changes from 3 to 6, this signal will be emitted for sections 4, 5, and 6
signal section_hit

## Emitted once after the full section change is completed.
## Use this if you only need a single notification per section change.
signal section_hit_once 


signal beat_hit ##Emitted when the beat changes.
signal bpm_changes ##Emitted when the bpms changes.

signal song_loaded


#region Song methods
func loadSong(json_name: String, suffix: String = '') -> Dictionary:
	songJson = Song.loadJson(json_name, suffix)
	if !songJson: return Song.getChartBase()
	
	songDefaultBpm = songJson.get('bpm',120)
	bpm = songDefaultBpm
	detectBpmChanges()
	
	return songJson

##Load [AudioPlayer]'s from the current song.
func loadSongsStreams(folder: String = Song.audioFolder, suffix: String = Song.audioSuffix) -> void: #Used in StrumState.
	if songs: return

	var player_name = songJson.get('opponentVocals',songJson.get('player1',''))
	var opponent_name = songJson.get('playerVocals',songJson.get('player2',''))
	
	var paths: Array[PackedStringArray] = [
		#Inst Path
		['Inst'+suffix,'Inst'] if suffix else ['Inst'], 
		#Opponent Song Paths
		[
			'Voices-'+opponent_name+suffix,
			'Voices-'+opponent_name.replace(' ','-').get_slice('-',0)+suffix,
			'Voices-Opponent'+suffix
		], 
		#Player Song Paths
		[
			'Voices-'+player_name+suffix,
			'Voices-'+player_name.replace(' ','-').get_slice('-',0)+suffix,
			'Voices-Player',
			'Voices'+suffix
		]
	]
	
	#Look for Inst
	var paths_absolute: PackedStringArray = []
	for path in paths:
		var song
		for i in path:
			song = Paths.songPath(folder+'/'+i)
			if !song: continue
			paths_absolute.append(song)
			break
		if !song: paths_absolute.append('')
			
	loadSongsStreamsFromArray(paths_absolute)


##Load Song Streams from Array.
##[param paths_absolute] must be in this order: 
##[code][Inst Path, Opponnet Voice Path, Player Voice Path][/code]
func loadSongsStreamsFromArray(paths_absolute: PackedStringArray):
	if !paths_absolute: return

	var stream_id: int = -1
	for i in paths_absolute:
		stream_id += 1
		if !i: continue
		var stream = Paths.audio(i)
		if !stream: continue
		var audio = AudioStreamPlayer.new()
		audio.stream = stream
		audio.name = StreamNames[stream_id]
		songs.append(audio)
		add_child(audio)
	
	if songs and songs[0].stream: 
		songs[0].bus = 'Visualizer'
		songLength = songs[0].stream.get_length()*1000.0
	song_loaded.emit()
	
##Set the current position of the song in milliseconds.
func setSongPosition(pos: float) -> void:
	songPosition = pos
	songPositionSeconds = pos/1000.0
	if !songs: return
	if songPosition < 0.0:
		for i in songs: if i: i.stop()
		return
	for i in songs:
		if i: i.seek(clampf(songPositionSeconds,0.0,i.stream.get_length()))
	
##Play songs.[br][b]Note:[/b] [param at] have to be in milliseconds, if set.
func playSongs(at: float = 0) -> void: for song in songs: song.play(at/1000.0)

func resumeSongs() -> void:
	if songPositionSeconds < 0: return
	for song in songs: if songPositionSeconds < song.stream.get_length(): song.play(songPositionSeconds)

func pauseSongs() -> void: for song in songs: song.stop() ##Pause the streams.

func stopSongs(delete: bool = false) -> void: ##Stop the streams.
	if delete:
		for song in songs:
			remove_child(song)
			song.queue_free()
		songs.clear()
	else:
		for song in songs: song.stop()
		songPosition = 0
		
func clearSong(absolute: bool = true) -> void: ##Clear all the songs created
	stopSongs(true)
	setSongPosition(0.0)
	setBpmChangeIndex(-1)
	if !absolute: return
	
	bpmChanges.clear()
	bpm = 0
	songJson.clear()
	Song._clear()
#endregion

#region Get methods
func get_step_count() -> int:
	if !bpmChanges: return int(songLength/get_step_crochet(bpm))
	var last_change = bpmChanges.back()
	return int(songLength/get_step_crochet(last_change.bpm) - last_change.step_offset)
	
static func get_step_crochet(bpm: float) -> float: return 15000.0/bpm #15000.0 = 60000.0/4.0
	
static func get_section_crochet(bpm: float, section_beats: float = 4) -> float: 
	return get_crochet(bpm) * section_beats

func get_section_data(section: int) -> Dictionary:
	return ArrayUtils.get_array_index(
		songJson.get('notes',[]),
		section,
		{}
	)

static func get_crochet(bpm: float) -> float:
	if !bpm: return 0.0
	return 60000/bpm

func get_section_time(_section: int = section, _bpm: float = songDefaultBpm) -> float:
	if _section <= 0: return 0
	var section_data = get_section_data(_section)
	if section_data: return section_data.sectionTime
	
	var section_changes = get_bpm_changes(_section)
	if !section_changes: return _section * get_section_crochet(_bpm)
	return _section * get_section_crochet(section_changes.bpm) - section_changes.section_offset

func get_section(_position: float, _bpm: float = songDefaultBpm) -> float:
	var changes = get_bpm_changes_from_pos(_position)
	if !changes: return _position / get_section_crochet(_bpm)
	return (_position / get_section_crochet(changes.bpm)) - changes.section_offset

func get_beat(pos: float, _bpm: float = songDefaultBpm) -> float:
	var changes = get_bpm_changes_from_pos(pos)
	if !changes: return pos/get_crochet(_bpm)
	return pos/get_crochet(changes.bpm) - changes.beat_offset

func get_beat_section(_section: float) -> float:
	var changes = get_bpm_changes(_section)
	if !changes: return _section * 4.0
	return (_section+changes.section_beats_offset) * 4.0 - changes.beat_offset

func get_step(pos: float, _bpm: float = songDefaultBpm) -> float:
	var changes = get_bpm_changes_from_pos(pos)
	if !changes: return pos/get_step_crochet(_bpm)
	return pos/get_step_crochet(changes.bpm) - changes.step_offset

func get_step_time(step: float, _bpm: float = songDefaultBpm):
	var changes = get_bpm_changes(step/16.0) #step / 16.0 = one section
	if !changes: return step * get_step_crochet(_bpm)
	return step * get_step_crochet(changes.bpm) - changes.step_offset

func get_step_section(_section: float):
	var changes = get_bpm_changes(_section)
	if !changes: return _section * 16.0
	return (_section+changes.section_beats_reduced) * 16.0 - changes.step_offset
#endregion

#region Setters
func set_step(_step: int):
	if step == _step: return
	step = _step
	step_hit.emit()

func set_section(_section: int):
	if section == _section: return
	bpm_index = _find_current_change_index(section,bpm_index)
	var step = signi(_section - section)
	while section != _section: section += step; section_hit.emit()
	section_hit_once.emit()

func set_beat(_beat: int):
	if beat == _beat: return
	beat = _beat
	beat_hit.emit()

func _set_song_position(position: float):
	songPosition = position
	songPositionDelayed = position - ClientPrefs.data.songOffset
	if !position:
		songPositionSeconds = 0.0
		step_float = 0.0
		beat_float = 0.0
		section_float = 0.0
	else:
		step_float = songPosition / stepCrochet - step_offset
		beat_float = songPosition / crochet - beat_offset
		section_float = (songPosition - section_beats_offset) / sectionCrochet - section_offset
		
		if is_playing and fixVoicesSync:
			for song in songs:
				if song.name == 'Inst': continue
				if absf(song.get_playback_position() - songPositionSeconds) > 0.01: song.seek(songPositionSeconds)

func set_bpm(value: float): bpm = value; update_bpm()
#endregion

#region Bpm Methods
func detectBpmChanges():
	var sectionBpm: float = songJson.get('bpm',0)
	var bpm_section: int = 0
	for i in songJson.notes:
		var sectionBeats: int = int(i.sectionBeats)
		if i.changeBPM and i.bpm != sectionBpm:
			addNewBpm(bpm_section,i.bpm,sectionBpm)
			sectionBpm = i.bpm
		if sectionBeats < 4: _reduce_section_beats(bpm_section,sectionBeats,sectionBpm)
		bpm_section += 1

func addNewBpm(section: int,newBpm: float, oldBpm: float = bpm) -> void:
	if newBpm == oldBpm: return
	
	var song_position = get_section_time(section,oldBpm)
	var oldBeat: float = get_beat(song_position)
	var oldStep: float = get_step(song_position)
	
	var newCrochet = get_crochet(newBpm)
	
	var newSec: float = song_position/(newCrochet*4.0)
	var newBeat: float = song_position/newCrochet
	var newStep: float = song_position/(newCrochet/4.0)
	
	
	var data: Dictionary[StringName,float] = {
		'section': section,
		'bpm': newBpm,
		'section_offset': newSec - section,
		'beat_offset': newBeat - oldBeat,
		'step_offset': newStep - oldStep
	}
	_insert_bpm_changes(data)

func setSongBpm(_bpm: float):
	bpm = _bpm
	Conductor.songJson.bpm = _bpm

func setBpmChangeIndex(index: int):
	bpm_index = clampi(index,-1,bpmChanges.size()-1)
	if index == -1:
		bpm = songJson.get('bpm',0)
		section_offset = 0
		beat_offset = 0
		step_offset = 0
		section_beats_offset = 0
		return
	
	var i = bpmChanges[index]
	bpm = i.bpm
	section_offset = i.section_offset
	beat_offset = i.beat_offset
	step_offset = i.step_offset
	section_beats_offset = i.section_beats_offset
	
func removeBpmChange(section: int):
	for i in bpmChanges: if i.section == section: bpmChanges.erase(i); break
		
func _reduce_section_beats(section: int, beats: int, sectionBpm: float = bpm) -> void:
	if beats == 4: return
	var beat_subs: float = get_crochet(sectionBpm)*(4.0-beats)
	if bpmChanges: 
		var last = bpmChanges.back()
		beat_subs -= last.section_beats_offset
	_insert_bpm_changes({
		'section': section,
		'bpm': sectionBpm,
		'section_beats_offset': -beat_subs
		}
	)
	
func _insert_bpm_changes(data: Dictionary):
	if bpmChanges: data.merge(bpmChanges.back(),false)
	else: data.merge(getChangesBase(),false)
	
	var is_same: bool = false
	var index: int = 0
	for i in bpmChanges:
		if data.section > i.section: index += 1; continue
		elif data.section == i.section: bpmChanges[index] = data; is_same = true
		break
	if index == bpm_index: setBpmChangeIndex(index)
	if !is_same: bpmChanges.insert(index,data)
	
func update_bpm() -> void:
	crochet = get_crochet(bpm)
	stepCrochet = crochet/4.0
	sectionCrochet = crochet*4.0
	bpm_changes.emit()
	
func get_bpm_changes_from_pos(position: float, at: int = bpm_index) -> Dictionary:
	if !bpmChanges: return {}
	
	if position == songPosition: 
		if bpm_index == -1: return {} 
		return bpmChanges[bpm_index]
	
	var index = _find_current_change_index_from_pos(position, at)
	if index == -1: return {}
	return bpmChanges[index]
	
func get_bpm_changes(_section: int = section, at: int = bpm_index) -> Dictionary:
	if !bpmChanges: return {}
	var index = _find_current_change_index(_section,at)
	if index == -1: return {} 
	return bpmChanges[index]


func _find_current_change_index(_section: int,at: int = 0) -> int:
	if !bpmChanges or _section < 0: return -1
	while at >= 0 and _section < bpmChanges[at-1].section: at -= 1
	while at < bpmChanges.size()-1 and _section > bpmChanges[at+1].section: at += 1
	return at

func _find_current_change_index_from_pos(pos: float, at: int = 0) -> int:
	if pos <= 0: return -1
	#Checks if the index is before the "at"
	
	var is_before: bool = false
	while at > 0:
		var sec_data = get_section_data(bpmChanges[at].section)
		if pos > sec_data.sectionTime: 
			if is_before: return at
			break
		at -= 1
		is_before = true
	
	while at < bpmChanges.size()-1:
		var sec_data = get_section_data(bpmChanges[at+1].section)
		if pos <= sec_data.sectionTime: return at
		at += 1
	return at

static func getChangesBase() -> Dictionary:
	return {
		'section': 0,
		'bpm': 0,
		'section_offset': 0,
		'section_beats_offset': 0,
		'beat_offset': 0,
		'step_offset': 0
	}
#endregion


func _process(_d) -> void:
	if !songs:
		if songPosition > 0: songPosition = 0.0; 
		return
	if songs[0].playing:
		is_playing = true
		songPositionSeconds = songs[0].get_playback_position()
		songPosition = songPositionSeconds*1000.0
	else:
		is_playing = false
