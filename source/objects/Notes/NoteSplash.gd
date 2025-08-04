#@icon("res://icons/splash.png")
extends "res://source/objects/Sprite/SpriteAnimated.gd"

const NoteSplash = preload("res://source/objects/Notes/NoteSplash.gd")

var offset: Vector2 = Vector2.ZERO

var texture: StringName = ''## Splash Texture

var sustainSplash: bool = false ##If the splash is from a [u]Sustain[/u] note.
var direction: int = 0 ##Splash Direction
var isPixelSplash: bool = false: set = _set_pixel ##If is a [u]pixel[/u] splash.
var preffix: StringName = '' ##The splash animation from his sparrow animation(.xml file).
var angle: float: ##Similar to [member Node2D.rotation_degrees].
	set(value):
		if value == rotation_degrees:
			return
		rotation_degrees = value
		_updatePos()
	get():
		return rotation_degrees
	
var strum: Node: ##The Splash strum.
	set(value):
		strum = value
		position = value.position - offset

var splash_scale: Vector2 = Vector2.ZERO ##Splash scale.

var _position: Vector2 = Vector2.ZERO

static var _splash_datas: Dictionary = {}
static var mosaicShader: Material
func _init():
	is_animated = true
	super._init()
	animation.animation_finished.connect(
		func(_anim):
			visible = false
	)

	image.texture_changed.connect(func():
		if !image.texture or _splash_datas.has(image.texture.resource_name):
			return
		_splash_datas[image.texture.resource_name] = {}
	)
	visibility_changed.connect(func():
		_updatePos()
	)
	
func _set_pixel(isPixel: bool):
	if isPixel == isPixelSplash: return
	isPixelSplash = isPixel
	
	if isPixel:
		if !mosaicShader: mosaicShader = Paths.loadShader('MosaicShader')
		material = mosaicShader
		if material: material.set_shader_parameter('strength',8.0)
	else: material = null
	
##Add animation to splash. Returns [code]true[/code] if the animation as added successfully.
func addSplashAnim(prefix: StringName, fps: float = 24.0, looped: bool = false) -> bool:
	if !image.texture: return false
	var data = getSplashData(image.texture.resource_name,prefix)
	var anim = animation.addAnimByPrefix('splash',prefix+' '+str(randi_range(1,2)),24,looped)
	if sustainSplash or !anim:
		anim = animation.addAnimByPrefix('splash',prefix+' 1',24.0,looped)
	if !anim:
		anim = animation.addAnimByPrefix('splash',prefix,24.0,looped)
	
	if !anim: return false
	
	offset = data.get('offset',Vector2.ZERO)
	scale = data.get('scale',Vector2.ONE)
	_updatePos()
	return true

func _process(delta: float) -> void:
	if visible and sustainSplash and strum:
		_updatePos()
		if strum.mustPress and Input.is_action_just_released(strum.hit_action): visible = false
		modulate.a = strum.modulate.a

func _draw():
	if material:
		material.set_shader_parameter('modulate',modulate)
		
func _updatePos():
	if strum:
		if sustainSplash:
			rotation = strum.rotation
		_position = strum._position
		#scale = strum.scale + Vector2(0.3,0.3)
		
	var pivot = pivot_offset
	if rotation:
		pivot = pivot.rotated(rotation)
	pivot *= scale
	position = _position - (pivot - pivot_offset) - offset


static func create(texture: StringName, prefix: StringName, fps: float = 24.0, looped: bool = false) -> NoteSplash:
	var splash = NoteSplash.new()
	splash.image.texture = Paths.imageTexture(texture)
	if !splash.addSplashAnim(prefix,fps,looped):
		return null
	return splash
	
##Returns the splash data from the [param preffix] in the [param file].
static func getSplashData(file: String, preffix: String = '') -> Dictionary:
	if _splash_datas.has(file) and _splash_datas[file].has(preffix):
		return _splash_datas[file][preffix]
	
	var data = {
		'scale': Vector2.ONE,
		'offset': Vector2(85,85)
	}
	var texPath = Paths.text(file)
	if !texPath:
		return data
	
	var lines: Array = texPath.split('\n',false)
	
	for anim in range(lines.size()):
		var curLine: String = lines.get(anim)
		var findPoint = curLine.find(':')
		if findPoint != -1 and preffix.begins_with(curLine.substr(0,findPoint-1)):
			var lineOffset: Array = curLine.substr(findPoint+1).split(' ',false)
			if curLine.begins_with('scale'):
				data.scale = Vector2(float(lineOffset[0]),float(lineOffset[1]))
				break
			data.offset = Vector2(float(lineOffset[0]),float(lineOffset[1]))
			break
	_splash_datas[file] = {
		preffix = data
	}
	return data
