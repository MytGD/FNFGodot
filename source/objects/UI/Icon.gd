@icon("res://icons/icon.svg")
extends FunkinSprite

var animated: bool = false
var hasWinningIcon: bool = false

var default_scale: Vector2 = Vector2.ONE
var scale_lerp: bool = false
	
var beat_value: Vector2 = Vector2(0.2,0.2)
var scale_lerp_time: float = 10

var health_offset: float = 0

var icon_pivot_rotation: float = 0.0
var isPixel: bool = false

func _init(texture: String = ''):
	super._init(true)
	if texture: changeIcon(texture)
	name = 'icon'
	
func changeIcon(icon: String = "icon-face"):
	icon = Paths.icon(icon)
	if !icon: icon = Paths.icon('icon-face')
	if imageFile == icon: return
	animation.clearLibrary()
	
	var texture = Paths.imageTexture(icon)
	image.texture = texture
	hasWinningIcon = Paths.getPath(icon,false).begins_with("images/winning_icons/")
	
	icon = icon.substr(0,icon.length()-4)
	
	animated = FileAccess.file_exists(icon+'.xml')
	
	if animated:
		animation.addAnimByPrefix('normal','Default',24,true)
		animation.addAnimByPrefix('losing','Losing',24,true)
		animation.addAnimByPrefix("winning",'Winning',24,true)
	elif hasWinningIcon:
		setGraphicSize(imageSize.x/3.0,imageSize.y)
		animation.addFrameAnim('normal',[0])
		animation.addFrameAnim('losing',[1])
		animation.addFrameAnim('winning',[2])
	else:
		setGraphicSize(imageSize.x/2.0,imageSize.y)
		animation.addFrameAnim('normal',[0])
		animation.addFrameAnim('losing',[1])
	#animation.play('normal')

func reloadIconFromCharacterJson(json: Dictionary):
	var data = json.get('healthIcon',{})
	changeIcon(data.get('id','icon-face'))
	set_pixel(data.get('isPixel',false),data.get('canScale',false))
	
func _process(delta: float) -> void:
	if scale_lerp: scale = scale.lerp(default_scale,delta*scale_lerp_time)
	super._process(delta)
	

func set_pixel(is_pixel: bool = false, scale_if_pixel: bool = false):
	if is_pixel == isPixel: return
	texture_filter = TEXTURE_FILTER_NEAREST if is_pixel else TEXTURE_FILTER_PARENT_NODE
	if scale_if_pixel and is_pixel:
		scale = Vector2(4.5,4.5)
		beat_value = Vector2(0.6,0.6)
	else:
		scale = Vector2.ONE
		beat_value = Vector2(0.2,0.2)
	isPixel = is_pixel
	default_scale = scale
	
func set_pivot_offset(pivot: Vector2) -> void:
	super.set_pivot_offset(pivot) 
	health_offset = pivot_offset.x/1000.0
