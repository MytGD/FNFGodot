#@icon("res://icons/splash.png")
extends FunkinSprite

const NoteSplash = preload("res://source/objects/Notes/NoteSplash.gd")

static var splash_datas: Dictionary[StringName,Dictionary] = {}
static var mosaicShader: Material

enum SplashType{
	NORMAL = 0,
	HOLD_COVER = 1,
	HOLD_COVER_END = 2
}
var texture: StringName ## Splash Texture

var direction: int = 0 ##Splash Direction
var isPixelSplash: bool = false: set = _set_pixel ##If is a [u]pixel[/u] splash.
var preffix: StringName ##The splash animation from his sparrow animation(.xml file).
@warning_ignore("unused_private_class_variable")
var _is_custom_parent: bool = false #Used in StrumState.


var strum: Node ##The Splash strum.

var splash_scale: Vector2 = Vector2.ZERO ##Splash scale.

var style: String = 'NoteSplash'
var type: String = 'noteSplash'
var splashType: SplashType = SplashType.NORMAL
var splashData: Dictionary

func _init():
	super._init(true)
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	set_process(visible)
	if visible: _update_position()

func _set_pixel(isPixel: bool):
	if isPixel == isPixelSplash: return
	isPixelSplash = isPixel
	
	if isPixel:
		if !mosaicShader: mosaicShader = Paths.loadShader('MosaicShader')
		material = mosaicShader
		if material: material.set_shader_parameter(&'strength',6.0)
	else: material = null
	
##Add animation to splash. Returns [code]true[/code] if the animation as added successfully.
func loadSplash(type: StringName, prefix: StringName) -> bool:
	splashData = getSplashData(style,type)
	if !splashData: return false
	
	addSplashAnimation(self,prefix)
	
	var data_scale = splashData.get(&'scale')
	if data_scale: scale = Vector2(data_scale,data_scale)
	return true

func _process(_d) -> void:
	super._process(_d)
	if !visible: return
	if splashType == SplashType.HOLD_COVER and strum: 
		followStrum()
		if strum.mustPress: visible = Input.is_action_pressed(strum.hit_action)

func followStrum() -> void:
	modulate.a = strum.modulate.a
	if splashType == SplashType.HOLD_COVER: rotation = strum.rotation
	_position = strum._position

static func addSplashOffsetFromData(splash: NoteSplash, anim_name: String, data: Dictionary) -> void:
	var _offset = data.get(&'offsets',splash.splashData.get(&'offsets'))
	splash.addAnimOffset(
		anim_name,
		VectorUtils.as_vector2(_offset) if _offset else Vector2(100,100)
	)


static func addSplashAnimation(splash: NoteSplash, prefix: StringName):
	var anim_data = splash.splashData.data
	var prefixs = anim_data.get(prefix)
	if !prefixs: prefixs = anim_data.get(&'default'); if !prefixs: return false
	
	if prefixs is Array: prefixs = prefixs.pick_random()
	
	var asset = prefixs.get(&'assetPath')
	if !asset: asset = splash.splashData.get(&'assetPath'); if !asset: return false
	
	
	splash.image.texture = Paths.texture(asset)
	
	if !splash.image.texture: return false
	splash.splashData.get('alpha',1.0)
	
	#Set Offset
	match splash.splashType:
		SplashType.NORMAL:
			var prefix_anim = prefixs.get(&'prefix','')
			if !prefix_anim: return false
			splash.animation.addAnimByPrefix(&'splash',prefix_anim,24.0,false)
			addSplashOffsetFromData(splash,&'splash',prefixs)
		
		SplashType.HOLD_COVER:
			var start_data = prefixs.get(&'start')
			if start_data:
				var sprefix = start_data.get(&'prefix')
				if sprefix:
					splash.animation.addAnimByPrefix(&'splash',sprefix,24.0,false)
					splash.animation.auto_loop = true
					addSplashOffsetFromData(splash,&'splash',start_data)
			
			var hold_data = prefixs.get(&'hold')
			if hold_data:
				var hprefix = hold_data.get(&'prefix')
				if hprefix:
					splash.animation.addAnimByPrefix(
						'splash-hold',
						hprefix,
						24.0,
						true
					)
				addSplashOffsetFromData(splash,&'splash-hold',hold_data)
		SplashType.HOLD_COVER_END:
			var end_data = prefixs.get(&'end')
			if !end_data: return false
			splash.animation.addAnimByPrefix(
				&'splash',
				end_data.get(&'prefix',&''),
				24.0,
				false
			)
			addSplashOffsetFromData(splash,&'splash',end_data)
	return true

static func getSplashData(file: StringName, type: StringName) -> Dictionary: ##Returns the splash data from the [param preffix] in the [param file].
	var data: Dictionary
	
	if splash_datas.has(file): data = splash_datas[file]
	else:
		data = Paths.loadJson('data/splashstyles/'+file)
		if !data: return {}
		splash_datas[file] = data
	
	var val = data.get(type)
	if !val: return {}
	
	return val
