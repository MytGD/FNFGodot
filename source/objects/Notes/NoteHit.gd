extends "res://source/objects/Notes/Note.gd"
const NoteSustain = preload("res://source/objects/Notes/NoteSustain.gd")
const key_actions: Array = [
	[&""],
	[&"note_left"],
	[&"note_left",&"note_right"],
	[&"note_left",&"note_center",&"note_right"],
	[&"note_left",&"note_down",&"note_up",&"note_right"],
	[&"note_left",&"note_down",&"note_center",&"note_up",&"note_right"],
]
var sustainParents: Array[NoteSustain]

var hit_action: StringName ##The Key that have to be press to hit the note, this auto changes when [member noteData] is setted.
var copyAngle: bool = true ## Follow strum angle
var copyScale: bool ##If [code]true[/code], the note will follow the scale from his [member strum].

func updateNote():
	super.updateNote()
	updateRating()

func updateRating() -> void:
	var timeAbs = absf(distance)
	ratingMod = 0
	while ratingMod < _ratings_length: 
		if timeAbs < _rating_offset[ratingMod]: break
		ratingMod += 1
	rating = _rating_string[ratingMod]

func setNoteData(_data: int) -> void: super.setNoteData(_data); hit_action = getInputActions()[_data]

func followStrum(strum: StrumNote = strumNote) -> void:
	super.followStrum(strum)
	if copyAngle: rotation_degrees = strumNote.rotation_degrees
	if copyScale: setGraphicScale(strumNote.scale * multScale)

static func getInputActions(key_count: int = Song.keyCount) -> Array: return key_actions[key_count]
