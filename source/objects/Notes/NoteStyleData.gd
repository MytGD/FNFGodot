static var styles_loaded: Dictionary[StringName,Dictionary]

const default_style_structure: Dictionary[StringName,Dictionary] = {
	&'notes': {},
	&'holdNotes': {},
	&'strums': {}
}
const default_style_type_structure: Dictionary[StringName,Variant] = {
	&'assetPath': '',
	&'fps': 24.0,
	&'scale': 1.0,
	&'offsets': [0,0],
	&'data': {},
	&'isPixel': false
}
enum StyleType{
	NOTES,
	HOLD_NOTES,
	STRUM,
	HOLD_SPLASH,
	SPLASH
}

static func getStyleData(style: StringName, type: StyleType = StyleType.NOTES) -> Dictionary: 
	var json = _load_style(style)
	match type:
		StyleType.HOLD_NOTES: return json.holdNote
		StyleType.STRUM: return json.strums
		StyleType.SPLASH: return json.noteSplash
		StyleType.HOLD_SPLASH: return json.holdNoteCover
		_: return json.notes

static func _load_style(style: StringName) -> Dictionary:
	var json = styles_loaded.get(style)
	if json: return json
	json = Paths.loadJson('data/notestyles/'+style)
	if !json: return {}
	DictionaryUtils.convertKeysToStringNames(json,true)
	
	if json.has(&'holdNoteCover'): _fix_sustain_animation_data(json.holdNoteCover)
	if json.has(&'notes'): _fix_animation_data(json.notes)
	if json.has(&'strums'): _fix_animation_data(json.strums)
	
	styles_loaded[style] = json
	return json

	
static func _fix_sustain_animation_data(style_data: Dictionary) -> void:
	style_data.merge(default_style_type_structure,false)
	for i in style_data.data.values():
		if i.has(&'start'): _check_animation_data(i.start,style_data)
		if i.has(&'hold'): _check_animation_data(i.hold,style_data)
		if i.has(&'end'): _check_animation_data(i.end,style_data)

static func _fix_animation_data(style_data: Dictionary) -> void:
	style_data.merge(default_style_type_structure,false)
	for i in style_data.data.values():
		if i is Array: for d in i: _check_animation_data(d,style_data)
		elif i is Dictionary: _check_animation_data(i,style_data)

static func _check_animation_data(data: Dictionary, style_data: Dictionary) -> void:
	if !data.has(&'scale'): data.scale = style_data.scale
	if !data.has(&'offsets'): data.offsets = style_data.offsets
	if !data.has(&'fps'): data.fps = style_data.fps
	data.prefix = &'' if !data.has(&'prefix') else StringName(data.prefix)
