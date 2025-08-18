static func loadJson(json_path: String, difficulty: String = '') -> Dictionary:
	var json = Paths.loadJson(json_path)
	if !json:
		return json
	if json.get('song') is Dictionary:
		json = json.song
	
	#Check if the chart is from the fnf
	var meta_data_path = json_path.replace('-chart','-metadata')
	if json.get('notes') is Dictionary:
		var meta_data = Paths.loadJson(meta_data_path)
		meta_data.songDifficulty = difficulty.to_lower()
		json = _convert_new_to_old(json,meta_data,difficulty)
		return json
	
	fixChart(json)
	sort_song_notes(json.notes)
	_insertSectionTimes(json)
	return json

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

static func _convert_new_to_old(chart: Dictionary, songData: Dictionary = {}, difficulty: String = '', folder_song: StringName = '') -> Dictionary:
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
	
	oldJson.speed = chart.get('scrollSpeed',{}).get(difficulty.to_lower(),2.0)
	
	oldJson.song = songData.get('songName','')
	oldJson.bpm = json_bpm
	
	for notes in chart.notes.get(difficulty.to_lower(),[]):
		var strumTime = notes.get('t',0)
		var section = int(strumTime/sectionStep) - subSections
		
		#Detect Bpm Changes
		if ArrayHelper.array_has_index(bpms,bpmIndex) and bpms[bpmIndex][0] <= strumTime:
			json_bpm = bpms[bpmIndex][1]
			sectionStep = Conductor.get_section_crochet(json_bpm)
			var newSection = int(strumTime/sectionStep) - subSections
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
		i.sectionNotes.sort_custom(ArrayHelper.sort_array_from_first_index)

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
