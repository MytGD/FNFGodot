@tool
class_name ClientPrefs
##Client Preferences. 

#Options will be saved when the client is closing the game, see it in Global.gd.
static var data: Dictionary = {
	'modsEnabled': {},
	'modsOrder': [],
	#Note Options
	'note_keys': {
		1: [
			[KEY_D,KEY_LEFT]
		],
		2:[
			[KEY_F,KEY_DOWN],
			[KEY_J,KEY_UP]
		],
		3:[ 
			[KEY_D,KEY_LEFT],
			[KEY_SPACE,KEY_DOWN],
			[KEY_K,KEY_RIGHT]
		],
		4:[ 
			[KEY_D,KEY_LEFT],
			[KEY_F,KEY_DOWN],
			[KEY_J,KEY_UP],
			[KEY_K,KEY_RIGHT]
		],
		5:[ 
			[KEY_D,KEY_LEFT],
			[KEY_F,KEY_DOWN],
			[KEY_SPACE],
			[KEY_J,KEY_UP],
			[KEY_K,KEY_RIGHT]
		],
		6:[ 
			[KEY_S],
			[KEY_D],
			[KEY_F],
			[KEY_J],
			[KEY_K],
			[KEY_L]
		],
		7:[ 
			[KEY_S],
			[KEY_D],
			[KEY_F],
			[KEY_SPACE],
			[KEY_J],
			[KEY_K],
			[KEY_L]
		]
	},
	#region Gameplay Options
	#Skins
	'splashSkin': 'noteSplashes/noteSplashes',
	'arrowSkin': 'noteSkins/NOTE_assets',
	'noteSkin': 'Default',
	
	#Scrolls
	'middlescroll': false,
	'downscroll': false,
	
	'comboStacking': true,
	'playAsOpponent': false,
	'notHitSustainWhenMiss': false,
	#endregion
	
	#region Screen Options
	'window_mode': DisplayServer.WINDOW_MODE_WINDOWED,
	'vsync_mode': DisplayServer.VSYNC_ENABLED,
	'fps': 120,
	#endregion
	
	#region Audio Options
	'songOffset': 0,
	#endregion
	
	
	#region Gameplay Options
	'timeBarType': 'Disabled',
	'hideHud': false,
	'botPlay': false,

	'comboOffset': PackedInt64Array([700,-250,-500,-200]),
	'miraculousRating': false,
	'miraculousOffset': 25.0,
	'sickOffset': 45.0,
	'goodOffset': 130.0,
	'badOffset': 150.0,
	
	'splashesEnabled': true,
	'opponentSplashes': false,
	'splashAlpha': 0.8,
	#endregion
	
	#region Visual  Options
	'lowQuality': false,
	
	'flashingLights': true,
	'antialiasing': true,
	'fixImageBorders': false,
	#region Effect Options
	'camZooms': true,
	'shadersEnabled': true,
	#endregion
	
	#endregion

}

static func _init() -> void:
	var options = Paths.loadJson("res://data/options.json")
	if options: 
		DictionaryHelper.merge_existing(data,options)
		setOptionValues()
	
static func setOptionValues():
	Engine.max_fps = data.fps
	DisplayServer.window_set_mode(data.window_mode)
	DisplayServer.window_set_vsync_mode(data.vsync_mode)
static func disableMod(mod_name: String):
	data.modsEnabled[mod_name] = false
	
