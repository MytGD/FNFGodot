extends Node
@onready var game := $/root/ModchartEditor/GameView
@onready var addShader := $/root/ModchartEditor/AddProperty

@onready var load_chart_characters := $LoadCharacters
@onready var load_chart_stage := $LoadStage
@onready var load_chart_notes := $LoadNotes
func openSongsDialog():
	var file_dialog = Paths.get_dialog()
	file_dialog.title = 'Select Songs'
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	file_dialog.add_filter('*ogg')
	file_dialog.add_filter('*mp3')
	file_dialog.add_filter('*wav')
	file_dialog.visible = true
	file_dialog.files_selected.connect(func(array):
		Conductor.clearSong(false)
		Conductor.loadSongsStreamsFromArray(array)
	)
	add_child(file_dialog)

func selectChart():
	var file_dialog = Paths.get_dialog()
	file_dialog.title = 'Select Chart'
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter('*json')
	file_dialog.visible = true
	file_dialog.file_selected.connect(func(file):
		var playstate = game.view
		playstate.clearSongNotes()
		Conductor.clearSong(true)
		Paths.curMod = Paths.getModFolder(file)
		playstate.loadSong(file)
		
		FunkinGD._clear_scripts(true)
		if load_chart_characters.button_pressed: playstate.loadCharactersFromData()
			
		if load_chart_stage.button_pressed:
			playstate.curStage = ''
			playstate.loadStage(Conductor.songJson.get('stage',''))
		
		playstate.respawnNotes = load_chart_notes.button_pressed
		if load_chart_notes.button_pressed:
			playstate.loadNotes()
		addShader.reloadShaders()
	)
	add_child(file_dialog)
