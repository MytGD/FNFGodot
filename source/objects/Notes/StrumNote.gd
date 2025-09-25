@icon("res://icons/strum.png")

##Strum Note
extends Sprite

const Note = preload("res://source/objects/Notes/Note.gd")
##Strum Direction
##[br][param 0: left, 1: down, 2: up, 3: right]
@export var data: int = 0;

##Direction of the note in radius. [br]
##Example: [code]deg_to_rad(90)[/code] makes the notes come from the left,
##while [code]deg_to_rag(180)[/code] makes come from the top.[br]
##[b]Obs:[/b] If [param downscroll] is [code]true[/code], the direction is inverted.
var direction: float = 0.0

var mustPress: bool = false ##Player Strum
var hit_action: String = '' ##Hit Key

var return_to_static_on_finish: bool = true
##Pixel Note
@export var isPixelNote: bool = false: 
	set(is_pixel):
		if is_pixel == isPixelNote:
			return
		isPixelNote = is_pixel
		antialiasing = !is_pixel
		if !texture:
			return
		
		if is_pixel and not texture.begins_with('pixelUI/'):
			texture = 'pixelUI/'+texture
		elif !is_pixel and texture.begins_with("pixelUI/"):
			texture = texture.right(-8)
		
##The [Input].action_key of the note, see [method Input.is_action_just_pressed]



##Strum Texture
var texture: String: 
	set(tex):
		if !tex: tex = 'noteSkins/NOTE_assets'
		else: tex = Paths.getPath(tex)
		
		
		if isPixelNote and !tex.begins_with('pixelUI/'): tex = 'pixelUI/'+tex
		
		if tex == 'images/'+imageFile: return
		var old_tex = texture
		
		texture = tex
		reloadStrumNote()
		texture_changed.emit(old_tex,tex)
	
##If [code]true[/code], make the strum don't make to Static anim when finish's animation
var specialAnim: bool = false

##Invert the note direction.
var downscroll: bool = false:
	set(value):
		multSpeed = -1.0 if value else 1.0
		downscroll = value

var multSpeed: float = 1.0 ##The note speed multiplier.

## Time used to determine when the strum should return to the 'static' animation after being hit.
## When this reaches 0, the 'static' animation is played.
var hitTime: float = 0.0

var is_static: bool = false #Used in PlayState to disable hold splashes
#var rgbShader: ShaderMaterial = RGBPalette.new()
#var useRGBShader: bool = true
signal texture_changed(old_tex, new_tex)
func _init(dir: int = 0):
	"""
	shader = rgbShader
	rgbShader.r = ClientPrefs.arrowRGB[dir][0]
	rgbShader.g = ClientPrefs.arrowRGB[dir][1]
	rgbShader.b = ClientPrefs.arrowRGB[dir][2]
	rgbShader.next_pass = testShader
	"""
	data = dir
	hit_action = Note.getNoteAction()[dir]
	
	offset_follow_scale = true
	super._init(null,true)
	
	animation.animation_finished.connect(func(anim):
		if anim != 'static' and return_to_static_on_finish and not mustPress:
			animation.play('static')
	)
	animation.animation_started.connect(func(anim):
		is_static = anim == 'static'
	)
const _anim_direction: Array = ['left','down','up','right']

func reloadStrumNote(): ##Reload Strum Texture Data
	animation.clearLibrary()
	_animOffsets.clear()
	offset = Vector2.ZERO
	image.texture = Paths.imageTexture(texture)
	antialiasing = !isPixelNote
	
	if not isPixelNote:
		var type = _anim_direction[data]
		
		animation.addAnimByPrefix('static','arrow'+type.to_upper(),24,true)
		animation.addAnimByPrefix('press',type+' press',24,false)
		animation.addAnimByPrefix('confirm',type+' confirm',24,false)
		
		addAnimOffset('confirm',40,40)
		#addAnimOffset('confirm',27,27) #without offset_follow_scale enabled.
		addAnimOffset('static')
		addAnimOffset('press',-2,-2)
		
		setGraphicScale(Vector2(0.7,0.7))
	else:
		var keyCount: int = Conductor.keyCount
		image.region_rect.size = imageSize/Vector2(keyCount,5)
		animation.addFrameAnim('static',[data])
		animation.addFrameAnim('confirm',[data + (keyCount*3),data + (keyCount*4),data + keyCount])
		animation.addFrameAnim('press',[data + (keyCount*3),data + (keyCount*2)])
		setGraphicScale(Vector2(6,6))
	
func strumConfirm(anim: String = 'confirm'):
	animation.play(anim,true)
	hitTime = Conductor.stepCrochet/1000.0
		
func _process(delta: float) -> void:
	super._process(delta)
	if mustPress:
		if animation.curAnim.name == 'static' and Input.is_action_just_pressed(hit_action): animation.play('press',true)
		elif Input.is_action_just_released(hit_action): animation.play('static')
	else:
		if hitTime > 0.0:
			hitTime -= delta
			if hitTime <= 0.0:
				hitTime = 0.0
				animation.play('static')
