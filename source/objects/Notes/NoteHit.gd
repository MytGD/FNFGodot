extends "res://source/objects/Notes/Note.gd"
const NoteSustain = preload("res://source/objects/Notes/NoteSustain.gd")
var sustainParents: Array[NoteSustain] = []

var hit_action: String = '' ##The Key that have to be press to hit the note, this auto changes when [member noteData] is setted.
var copyAngle: bool = true## Follow strum angle

##If [code]true[/code], the note will follow the scale from his [member strum].
var copyScale: bool = false

func updateNote():
	super.updateNote()
	var timeAbs = absf(distance)
	ratingMod = 0
	while ratingMod < _ratings_length:
		if timeAbs < _rating_offset[ratingMod]: break
		ratingMod += 1
	rating = _rating_string[ratingMod]
	
	if !canBeHit: return
	if sustainParents and ClientPrefs.data.splashesEnabled:
		var firstSus = sustainParents[0]
		var endSus = sustainParents.back()
		firstSus.ratingMod = ratingMod
		firstSus.rating = rating
		
		endSus.ratingMod = ratingMod
		endSus.rating = rating

func _load_data() -> void: super._load_data(); hit_action = getNoteAction()[noteData]

func followStrum(strum: StrumNote = strumNote):
	super.followStrum(strum)
	if copyAngle: angle = strumNote.angle
	if copyScale: setGraphicScale(strumNote.scale * multScale)
