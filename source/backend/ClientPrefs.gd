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
	
	'splashSkin': 'noteSplashes/noteSplashes',
	'arrowSkin': 'noteSkins/NOTE_assets',
	'noteSkin': 'Default',
	
	
	#Gameplay Options
	'middlescroll': false,
	'downscroll': false,
	
	'fps': 120,
	'songOffset': 0,
	'comboStacking': true,
	
	'playAsOpponent': false,
	
	
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

	
	#Visual  Options
	'lowQuality': false,
	'shadersEnabled': true,
	'flashingLights': true,
	
	'antialiasing': true,

	'camZooms': true,
	'fixImageBorders': false,
	'notHitSustainWhenMiss': false

}
"""
'arrowRGB': [
		[Vector3(0.76,0.294,0.6), Vector3.ONE, Vector3(0.23,0.12,0.33)],
		[Vector3(0,1,1), Vector3.ONE, Vector3(0.08,0.25,0.71)],
		[Vector3(0.07,0.98,0.02), Vector3.ONE, Vector3(0.03,0.26,0.27)],
		[Vector3(0.97,0.22,0.24), Vector3.ONE, Vector3(0.4,0.06,0.22)]
	],
'arrowRGBPixel': [
	[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
	[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
	[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
	[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
]
"""

static func _static_init() -> void:
	var options = JSON.parse_string(FileAccess.get_file_as_string("res://data/options.json"))
	if options: DictionaryHelper.merge_existing(data,options)

static func disableMod(mod_name: String):
	data.modsEnabled[mod_name] = false
	
