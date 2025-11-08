@icon("res://icons/StrumNote.png")
extends FunkinSprite ##Strum Note
const Song = preload("uid://cerxbopol4l1g")
const NoteHit = preload("uid://dx85xmyb5icvh")
const default_offset: PackedFloat32Array = [0,0]
##Strum Direction
##[br][param 0: left, 1: down, 2: up, 3: right]
@export var data: int = 0;

var prefixs: Dictionary
##Direction of the note in radius. [br]
##Example: [code]deg_to_rad(90)[/code] makes the notes come from the left,
##while [code]deg_to_rag(180)[/code] makes come from the top.[br]
##[b]Obs:[/b] If [param downscroll] is [code]true[/code], the direction is inverted.
var direction: float = 0.0:
	set(value): direction = value; _direction_radius = deg_to_rad(value)
var _direction_radius: float = 0.0:
	set(value): _direction_radius = value; _direction_lerp = Vector2(cos(value),sin(value))
var _direction_lerp: Vector2 = Vector2(0,1)
var mustPress: bool = false ##Player Strum
var hit_action: String = '' ##Hit Key

var return_to_static_on_finish: bool = true

var default_scale: float = 0.7
##Pixel Note
@export var isPixelNote: bool = false
##The [Input].action_key of the note, see [method Input.is_action_just_pressed]


var styleName: String: set = setStrumStyleName
var styleData: Dictionary
##Strum Texture
var texture: String: set = setTexture
	
##If [code]true[/code], make the strum don't make to Static anim when finish's animation
var specialAnim: bool

var downscroll: bool ##Invert the note direction.

var multSpeed: float = 1.0 ##The note speed multiplier.

## Time used to determine when the strum should return to the 'static' animation after being hit.
## When this reaches 0, the 'static' animation is played.
var hitTime: float = 0.0

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
	super._init(true)
	data = dir
	hit_action = NoteHit.getInputActions()[dir]
	
	offset_follow_scale = true
	animation.animation_finished.connect(func(anim):
		if anim != &'static' and return_to_static_on_finish and not mustPress: 
			animation.play(&'static')
	)
const _anim_direction: PackedStringArray = ['left','down','up','right']

func reloadStrumNote() -> void: ##Reload Strum Texture Data
	_animOffsets.clear()
	offset = Vector2.ZERO
	image.texture = Paths.texture(texture)
	antialiasing = !isPixelNote
	
	if prefixs: _load_anims_from_prefix()
	else: _load_graphic_anims()
	setGraphicScale(Vector2(default_scale,default_scale))

func _load_anims_from_prefix() -> void:
	var type = _anim_direction[data]
	
	var static_anim = prefixs[type+'Static']
	var press_anim = prefixs[type+'Press']
	var confirm_anim = prefixs[type+'Confirm']
	animation.addAnimByPrefix('static',static_anim.prefix,24,true)
	animation.addAnimByPrefix('press',press_anim.prefix,24,false)
	animation.addAnimByPrefix('confirm',confirm_anim.prefix,24,false)
	
	var confirm_offset = confirm_anim.get('offsets',default_offset)
	addAnimOffset('confirm',confirm_offset[0],confirm_offset[1])
	
	var press_offset = press_anim.get('offsets',default_offset)
	addAnimOffset('press',press_offset[0],press_offset[1])
	
	var static_offset = static_anim.get('offsets',default_offset)
	addAnimOffset('static',static_offset[0],static_offset[1])

func _load_graphic_anims() -> void:
	var keyCount: int = Song.keyCount
	image.region_rect.size = imageSize/Vector2(keyCount,5)
	animation.addFrameAnim('static',[data])
	animation.addFrameAnim('confirm',[data + (keyCount*3),data + (keyCount*4),data + keyCount])
	animation.addFrameAnim('press',[data + (keyCount*3),data + (keyCount*2)])

func loadFromStyle(noteStyle: String):
	styleName = noteStyle
	if !styleData: return
	
	isPixelNote = styleData.get('isPixel',false)
	prefixs = styleData.data
	default_scale = styleData.get('scale',0.7)
	texture = styleData.assetPath

func _on_texture_changed() -> void: super._on_texture_changed(); animation.clearLibrary()

#region Setters
func setTexture(_texture: String) -> void: texture = _texture;reloadStrumNote()

func setStrumStyleName(_name: String):
	styleName = _name
	styleData = getStrumStyleData(_name)
#endregion

func strumConfirm(anim: String = 'confirm'):
	animation.play(anim,true)
	hitTime = Conductor.stepCrochet/1000.0
		
func _process(delta: float) -> void:
	super._process(delta)
	if mustPress:
		if animation.current_animation == 'static' and Input.is_action_just_pressed(hit_action): 
			animation.play(&'press',true)
		elif Input.is_action_just_released(hit_action): animation.play(&'static')
	else:
		if hitTime > 0.0:
			hitTime -= delta
			if hitTime <= 0.0:
				hitTime = 0.0
				animation.play(&'static')

func _property_can_revert(property: StringName) -> bool:
	match property:
		&'data',&'styleData': return false
	return true
func _property_get_revert(property: StringName) -> Variant:
	match property:
		&'direction': return 0.0
		&'multSpeed': return 1.0
		&'mustPress': return false
		&'scale': return Vector2(default_scale,default_scale)
	return null

static func getStrumStyleData(style: String) -> Dictionary:
	var style_data = Paths.loadJson('data/notestyles/'+style)
	if !style_data: 
		style_data = Paths.loadJson('data/notestyles/funkin.json')
		return {}
	style_data = style_data.get('strums')
	return style_data if style_data else {}
