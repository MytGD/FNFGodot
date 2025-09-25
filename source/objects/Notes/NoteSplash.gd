#@icon("res://icons/splash.png")
extends "res://source/objects/Sprite/SpriteAnimated.gd"

const NoteSplash = preload("res://source/objects/Notes/NoteSplash.gd")

static var splash_datas: Dictionary = {}
static var mosaicShader: Material

enum SplashType{
	NORMAL = 0,
	HOLD_COVER = 1,
	HOLD_COVER_END = 2
}
var offset: Vector2 = Vector2.ZERO
var texture: StringName = ''## Splash Texture

var direction: int = 0 ##Splash Direction
var isPixelSplash: bool = false: set = _set_pixel ##If is a [u]pixel[/u] splash.
var preffix: StringName = '' ##The splash animation from his sparrow animation(.xml file).
var angle: float: ##Similar to [member Node2D.rotation_degrees].
	set(value):
		if value == rotation_degrees: return
		rotation_degrees = value
		_updatePos()
	get():
		return rotation_degrees

var _is_custom_parent: bool = false #Used in StrumState.
var strum: Node: ##The Splash strum.
	set(value):
		strum = value
		position = value.position - offset

var splash_scale: Vector2 = Vector2.ZERO ##Splash scale.

var _position: Vector2 = Vector2.ZERO

var style: String = 'NoteSplash'
var type: String = 'noteSplash'
var splashType: SplashType = SplashType.NORMAL

var _animsOffset: Dictionary = {}
func _init():
	super._init()
	visibility_changed.connect(func():
		_updatePos()
		set_process(visible)
	)
	
func _set_pixel(isPixel: bool):
	if isPixel == isPixelSplash: return
	isPixelSplash = isPixel
	
	if isPixel:
		if !mosaicShader: mosaicShader = Paths.loadShader('MosaicShader')
		material = mosaicShader
		if material: material.set_shader_parameter('strength',6.0)
	else: material = null
	
##Add animation to splash. Returns [code]true[/code] if the animation as added successfully.
func loadSplash(type: StringName, prefix: StringName) -> bool:
	var data = getSplashData(style,type)
	if !data: prints(type,prefix); return false
	
	var anim_data = data.get('data')
	if !anim_data: return false
	
	#Prefix
	var prefixs = anim_data.get(prefix)
	if !prefixs: 
		prefixs = anim_data.get('default')
		if !prefixs: return false
	
	var asset
	if prefixs is Dictionary: asset = prefixs.get('assetPath')
	if !asset: 
		asset = data.get('assetPath')
		if !asset: return false
	
	var alpha: float = data.get('alpha',1.0)
	if alpha: modulate.a = alpha
	
	image.texture = Paths.imageTexture(asset)
	
	if !image.texture: return false
	
	var prefixs_is_dict = prefixs is Dictionary
	
	var data_offset
	
	if prefixs_is_dict: data_offset = prefixs.get('offsets')
	if !data_offset: data_offset = data.get('offsets')
	
	if data_offset: offset = VectorHelper.array_to_vec(data_offset)
	else: offset = Vector2(100,100)
	
	match splashType:
		SplashType.NORMAL:
			if prefixs_is_dict:
				animation.addAnimByPrefix('splash',prefixs.get('prefix',''),24.0,false)
				_checkOffset('splash',prefixs)
			else:
				var index: int = 1
				for i in prefixs:
					var iprefix = i.get('prefix')
					var anim_name = 'splash'+str(index)
					
					
					if iprefix:
						animation.addAnimByPrefix(anim_name,iprefix,24.0,false)
						_checkOffset(anim_name,i)
						index += 1
		SplashType.HOLD_COVER:
			var start_data = prefixs.get('start')
			if start_data:
				var sprefix = start_data.get('prefix')
				if sprefix:
					animation.addAnimByPrefix(
						'splash',
						sprefix,
						24.0,
						false)
					animation.auto_loop = true
				_checkOffset('splash',start_data)
			
			var hold_data = prefixs.get('hold')
			if hold_data:
				var hprefix = hold_data.get('prefix')
				if hprefix:
					animation.addAnimByPrefix(
						'splash-hold',
						hprefix,
						24.0,
						true
					)
				_checkOffset('splash-hold',hold_data)
		SplashType.HOLD_COVER_END:
			var end_data = prefixs.get('end')
			if !end_data: return false
			animation.addAnimByPrefix(
				'splash',
				end_data.get('prefix',''),
				24.0,
				false
			)
			_checkOffset('splash',end_data)
	
	
	var data_scale = data.get('scale')
	if data_scale: scale = Vector2(data_scale,data_scale)
	_updatePos()
	return true

func _checkOffset(anim_name: StringName, anim_data: Dictionary):
	var offsets = anim_data.get('offsets')
	if !offsets: 
		if !_animsOffset: return
		offsets = Vector2(95,95)
	else: offsets = VectorHelper.array_to_vec(offsets) + Vector2(100,100)
	
	if !_animsOffset:
		animation.animation_started.connect(
			func(_anim_name):
				var data = _animsOffset.get(_anim_name)
				if data:
					offset = data
					_updatePos()
		)
		for i in animation.animationsArray:
			if _animsOffset.has(i): continue
			_animsOffset[i] = Vector2(100,100)
	_animsOffset[anim_name] = offsets 
	
	
func _process(delta: float) -> void:
	if visible and splashType == SplashType.HOLD_COVER and strum:
		
		_updatePos()
		if strum.mustPress: 
			visible = Input.is_action_pressed(strum.hit_action)

func _draw():
	if material: material.set_shader_parameter('modulate',modulate)


func followStrum():
	modulate.a = strum.modulate.a
	if splashType == SplashType.HOLD_COVER: rotation = strum.rotation
	_position = strum._position
	
func _updatePos():
	if strum: followStrum()
	var pivot = pivot_offset
	if rotation: pivot = pivot.rotated(rotation)
	pivot *= scale
	position = _position - (pivot - pivot_offset) - offset
	
##Returns the splash data from the [param preffix] in the [param file].
static func getSplashData(file: String, type: StringName) -> Variant:
	var data: Dictionary
	
	if splash_datas.has(file): data = splash_datas[file]
	else:
		data = Paths.loadJson('data/splashstyles/'+file)
		if !data: return {}
		splash_datas[file] = data
	
	var type_data = data.get(type)
	
	if !type_data: return {}
	return type_data
	
static func getSplashBase() -> Dictionary:
	return {}
