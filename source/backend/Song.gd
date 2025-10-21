extends Object
##A Chart Song Class.

##Contains the location of the json files.[br]
##[code]{"song name": 
##{"difficulty": {"folder": "folder_name","json": "json name", "audio_suffix": "suffix tag"}}
##}[/code][br][br]
##Example:[codeblock]
##songs_dir["Dad Battle"] = {
##    "Erect": {
##      "folder": "dad-battle",
##      "json": "dad-battle-erect-chart",
##      "audio_suffix": "-erect"
##    }, 
##    "Nightmare": {
##      "folder": "dad-battle",
##      "json": "dad-battle-erect-chart",
##      "audio_suffix": "-erect"
##    },
##}
##[/codeblock]
static var songs_dir: Dictionary[String,Dictionary] = {}

static var songName: String = ''
static var songJsonName: String = ''
static var audioSuffix: String = ''
static var audioFolder: String = ''
static var folder: String = ''
static var difficulty: String = ''


static func loadJson(json_name: String, _difficulty: String = '') -> Dictionary:
	var json: Dictionary
	var json_path: String
	
	var song_dir = songs_dir.get(json_name)
	if song_dir: song_dir = song_dir.get(_difficulty)
	
	if song_dir:
		folder = song_dir.get('folder',folder)
		json_name = song_dir.get('json',json_name)
		audioSuffix = song_dir.get('audioSuffix','')
		audioFolder = folder
		json_path = Paths.data(json_name,'',folder)
	else:
		audioSuffix = ''
		if !folder: folder = json_name.get_base_dir()
		
		json_path = Paths.data(json_name,_difficulty)
		folder = Paths.getPath(json_path,false).get_base_dir()
		audioFolder = folder.get_slice('/',folder.get_slice_count('/')-1)
	
	json = _loadData(json_path,_difficulty)
	
	difficulty = _difficulty
	songJsonName = json_name
	
	if !json: return json
	
	if !json.get('audioSuffix'): json.audioSuffix = audioSuffix
	if !json.get('audioFolder'): json.audioFolder = audioFolder
	
	songName = json.get('song','')
	if !songName: songName = songJsonName.get_basename()
	
	return json

static func _loadData(json_path: String, difficulty: String = '') -> Dictionary:
	var data = Paths.loadJson(json_path)
	if !data: return data
	if data.get('song') is Dictionary: data = data.song
	
	#Check if the chart is from the original fnf
	if data.get('notes') is Dictionary:
		var meta_data_path = json_path.replace('-chart','-metadata')
		var meta_data = Paths.loadJson(meta_data_path)
		data = _convert_new_to_old(data,meta_data,difficulty)
	else:
		fixChart(data)
		sort_song_notes(data.notes)
		_insertSectionTimes(data)
	return data
static func _insertSectionTimes(json: Dictionary):
	var section_time: float = 0.0
	var cur_bpm: float = json.bpm
	var beat_crochet: float = Conductor.get_crochet(cur_bpm)
	for i in json.notes:
		if !i: break
		if i.changeBPM:
			cur_bpm = i.get('bpm',json.bpm)
			beat_crochet = Conductor.get_crochet(cur_bpm)
		i.sectionTime = section_time
		i.bpm = cur_bpm
		section_time += beat_crochet * i.sectionBeats

static func fixChart(json: Dictionary):
	json.merge(getChartBase(),false)
	for section: Dictionary in json.notes: section.merge(getSectionBase(),false)
	return json

static func _convert_new_to_old(chart: Dictionary, songData: Dictionary = {}, difficulty: String = '') -> Dictionary:
	var oldJson = getChartBase()
	var json_bpm = 0.0
	var bpms = []
	
	if songData.has('timeChanges'):
		for changes in songData.timeChanges:
			bpms.append([changes.get('t',0),changes.get('bpm',0)])
		json_bpm = bpms[0][1]
	
	var bpmIndex: int = 0
	var subSections: int = 0
	var sectionStep: float = Conductor.get_section_crochet(json_bpm)
	
	var curSectionTime: float = 0
	
	var characters: Dictionary = {
		'player': 'bf',
		'girlfriend': 'bf',
		'opponent': 'bf'
	}
	
	var playData = songData.get('playData',{})
	if playData.has('characters'): characters.merge(playData.get('characters',{}),true)
	oldJson.stage = playData.get('stage','mainStage')
	
	oldJson.player1 = characters.player
	oldJson.gfVersion = characters.girlfriend
	oldJson.player2 = characters.opponent
	oldJson.songSuffix = characters.get('instrumental','')
	
	var vocal = characters.get('playerVocals')
	if vocal: oldJson.playerVocals = vocal[0]
	
	vocal = characters.get('opponentVocals')
	if vocal: oldJson.opponentVocals = vocal[0]
	
	oldJson.opponentVoice = characters.get('opponentVocals',oldJson.player1)
	oldJson.speed = chart.get('scrollSpeed',{}).get(difficulty.to_lower(),2.0)
	
	oldJson.song = songData.get('songName','')
	oldJson.bpm = json_bpm
	
	for notes in chart.notes.get(difficulty.to_lower(),[]):
		var strumTime = notes.get('t',0)
		var section = int(strumTime/sectionStep) - subSections
		
		#Detect Bpm Changes
		if ArrayUtils.array_has_index(bpms,bpmIndex) and bpms[bpmIndex][0] <= strumTime:
			json_bpm = bpms[bpmIndex][1]
			sectionStep = Conductor.get_section_crochet(json_bpm)
			var newSection = strumTime/sectionStep - subSections
			subSections -= newSection - section
			section = newSection - subSections
			bpmIndex += 1
		
		#Create Sections
		while section >= oldJson.notes.size():
			var new_section = getSectionBase()
			new_section.mustHitSection = true
			new_section.sectionTime = curSectionTime
			
			curSectionTime += sectionStep
			oldJson.notes.append(new_section)
		
		var last_section = oldJson.notes[section]
		var note_data = [strumTime,notes.get('d',0),notes.get('l',0.0)]
		if notes.has('k'):
			note_data.append(notes.k)
		last_section.sectionNotes.append(note_data)
		
	if chart.get('events'):
		for events in chart.events:
			var length = oldJson.events.size()-2
			
			#Detect if the event time is the same
			if length >= oldJson.events.size() and oldJson.events[length][0] == events.get('t',0):
				oldJson.events[length][1].append([events.get('e'),events.get('v')])
				continue
			
			oldJson.events.append([
				events.t,
				[
					[
						events.get('e',''),
						events.get('v',{})
					]
				]
			])

	return oldJson
	
static func sort_song_notes(song_notes: Array) -> void:
	for i in song_notes:
		if !i.sectionNotes: continue
		i.sectionNotes.sort_custom(ArrayUtils.sort_array_from_first_index)

static func getSectionBase() -> Dictionary:
	return {
		'sectionNotes': [],
		'mustHitSection': false,
		'gfSection': false,
		'sectionBeats': 4,
		'sectionTime': 0,
		'changeBPM': false,
		'bpm': 0
	}

static func getChartBase(bpm: float = 0) -> Dictionary: ##Returns a base [Dictionary] of the Song.
	return {
		'notes': [],
		'events': [],
		'bpm': bpm,
		'song': '',
		'songSuffix': '',
		'player1': 'bf',
		'player2': 'dad',
		'gfVersion': 'gf',
		'speed': 1,
		'stage': 'stage',
		'arrowSkin': '',
		'splashSkin': '',
		'disableNoteRGB': false,
		'needsVoices': true,
		'keyCount': 4,
	}


static func _clear():
	songs_dir.clear()
	audioSuffix = ''
	folder = ''
