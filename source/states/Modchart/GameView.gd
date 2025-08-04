extends SubViewport
const PlayState = preload("res://source/states/PlayState.gd")
var view: PlayState

func _ready():
	view = PlayState.new()
	view.canExitSong = false
	view.canPause = false
	view.hideHud = true
	view.autoStartSong = true
	view.botplay = true
	add_child(view)
