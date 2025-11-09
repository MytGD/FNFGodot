extends Label
enum Styles{
	DISABLED = 0,
	TIME_LEFT = 1,
	POSITION = 2,
	SONG_NAME = 3,
}
var style: Styles = ClientPrefs.data.timeBarType
func _init() -> void: 
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name = 'TimeTxt'
	set("theme_override_constants/outline_size",7)

func update() -> void:
	var songSeconds
	match style:
		Styles.TIME_LEFT: songSeconds = int((Conductor.songLength-Conductor.songPosition)/1000)
		Styles.POSITION: songSeconds = int(Conductor.songPositionSeconds)
		Styles.SONG_NAME: text = Conductor.songJson.song; return
		Styles.DISABLED: return
	var songMinutes = songSeconds/60
	songSeconds %= 60
	
	songMinutes = String.num_int64(songMinutes)
	songSeconds = String.num_int64(songSeconds)
	if songMinutes.length() <= 1: songMinutes = '0'+songMinutes
	if songSeconds.length() <= 1: songSeconds = '0'+songSeconds
	
	text = songMinutes+':'+songSeconds
