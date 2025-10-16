##A Animation custom class[br][br]
##[b]OBS:[/b] 
##The animation will just works when the parent's as a [NinePatchRect] or a
##[Sprite2D] with [member Sprite2D.region_rect] = [code]true[/code].
extends Resource

const AnimationService = preload("res://source/general/animation/AnimationService.gd")
const _AnimationController = preload("res://source/general/animation/AnimationController.gd")
const _sprite_sheet = preload("res://source/general/animation/spriteSheet.gd")

const region_pos_path = NodePath("region_rect:position")
##Stores the dates of created animations. See also [method insertAnim].
var animationsArray: Dictionary[StringName,Dictionary] = {}

##Contains the data of the animation [code]name, curFrame, prefix...[/code]
@export var curAnim: _AnimationController = _AnimationController.new()

var _animFile: StringName = ''

##Set the image that will be animated. Can be a [Sprite2D] or a [Sprite3D]
##with [param region_enabled] equals a [code]true[/code].[br][br]
##[b]OBS:[/b] the image have to be already added to a [Node] to works. 
##Call [Node.add_child] before set.
var image: CanvasItem:
	set(graphic):
		if image and image.texture_changed.is_connected(_verify_anim_file):
			image.texture_changed.disconnect(_verify_anim_file)
		image = graphic
		
		if graphic and graphic is Sprite2D: graphic.texture_changed.connect(_verify_anim_file)
		
		_verify_anim_file()
		if curAnim: curAnim.node_to_animate = image
		if !image: return

var _midpoint_set: bool = false
var _midpoint_is_rotated: bool = false

var image_parent: Node = null

var animations_use_textures: bool = false

var prefix: StringName = '' ##The current animation name in the sparrow

##Returns the xml frame being played.
var frameName: StringName:
	get():
		if !prefix: return ''
		var frame_str = str(curAnim.curFrame)
		return prefix+('0000').left(-frame_str.length())+frame_str

## if [code]true[/code], when the animation ends and the animator have the same animation name 
##with "-loop" at the end, that animation will be played.[br][br]
##Example:[codeblock]
##var animation = Anim.new()
##animation.addAnimByPrefix('idle','prefix1',24,false)
###When the "idle" animation ends, "idle-loop" will be played automatically
##animation.addAnimByPrefix('idle-loop','prefix2',24,true,[5,6,7])
##[/codeblock]
@export var auto_loop: bool = false: set = _set_auto_loop
signal animation_added(anim_name) ##Emiited when a animation is added to [member animations_array] using [method insertAnim]
signal pivot_offset_setted
#region Animation Player Vars

##Returns the current animation name.
var current_animation: String = '': 
	set(anim): play(anim)
	get(): return curAnim.name
	
##A multiplier for the frame rate.
@export_range(0,20,0.1) var speed_scale: float = 1:
	set(value): 
		speed_scale = value
		update_anim()

var animation_finished: Signal:
	get(): return curAnim.animation_finished

signal animation_started(anim_name) ##Emitted when a animation starts.
signal animation_changed(old_anim,new_anim) ##Emitted when the animation changes.
signal animation_renamed(old_name,new_name) ##Emitted when a animation is renamed.
signal image_animation_enabled(enabled: bool) ##Emitted when image animation is enabled.
#endregion
func _set_auto_loop(loop: bool):
	if auto_loop == loop: return
	if loop: curAnim.animation_finished.connect(_verify_loop)
	else: curAnim.animation_finished.disconnect(_verify_loop)
	auto_loop = loop

func _verify_loop(anim):
	if !play(anim+'-loop',true): play(anim+'-hold',true);
	
##Play animation.[br][br]
##Returns [code]true[/code] if the animation starts.[br][br]
##If [param force] is [code]true[/code], the animation will be forced to restart if already playing.[br]
##See also [method play_reverse].
func play(anim: StringName, force: bool = false) -> bool:
	if !can_play(anim,force): return false
	if anim != current_animation: update_anim(anim)
	curAnim.play()
	animation_started.emit(anim)
	return true

func play_random(force: bool = false):
	if !animationsArray: return
	var keys = animationsArray.keys()
	play(keys[randi_range(0, keys.size() - 1)], force)
	

func play_reverse(anim: StringName, force: bool = false) -> void: ##Plays the animation from end to beggining. See also [method play]
	if !can_play(anim,force): return
	update_anim(anim)
	curAnim.play_reverse()
	animation_started.emit(anim)
	
func stop() -> void: ##Stops the current animation.
	curAnim.name = ''
	curAnim.stop()
	
func seek(time: float) -> void: ##Jump the animation to [param time], in seconds.
	curAnim.curFrame = 1.0/curAnim.frameRate * time

##Returns a [Dictionary] with the data of the animation created. If don't exists, return a empty [Dictionary].
func getAnimData(animName: String) -> Dictionary:
	return animationsArray.get(animName,{})


##Set a property from the anim data set in [param animationsArray].[br]
##[b]OBS:[/b] If the [param animName] as the same from the current animation,
##use [method update_anim] to update the property changed.
func setAnimDataValue(animName: String, property: StringName, value: Variant):
	var data = animationsArray.get(animName)
	if !data: return
	data[property] = value
		
func update_anim(anim: String = current_animation):
	var animData = animationsArray[anim]
	if animations_use_textures and animData.asset: image.texture = animData.asset
	curAnim.name = anim
	curAnim.frames = animData.frames
	curAnim.frameRate = animData.fps
	curAnim.looped = animData.looped
	curAnim.loop_frame = animData.loop_frame
	curAnim.speed_scale = animData.speed_scale * speed_scale
	prefix = animData.prefix
	animation_changed.emit(current_animation,anim)

#region Add Animation Methods
##Add Animation from [u]Sparrow[/u]. Returns [code]true[/code] if the animation as added, [code]false[/code] otherwise.[br][br]
##To make the animation play specific frames, you can use [param indices], can be set as a [String] or a [Array]:[codeblock]
##var animation = Anim.new()
##animation.image = self
##animation.addAnimByPrefix('indices_array','prefix',24.0,false,[0,1,2,5,6]) #Using Array
##animation.addAnimByPrefix('indices_string','prefix',24,false,"0,1,2,3,4,5") #Using String
##[/codeblock]
func addAnimByPrefix(animName: String, prefix: String, fps: float = 24.0, loop: bool = false, indices: Variant = []) -> Dictionary:
	var anim_frames = getFramesFromPrefix(prefix,indices)
	if !anim_frames: return {}
	var anim_data: Dictionary = {
		'looped': loop,
		'fps': fps,
		'prefix': prefix,
		'frames': anim_frames
	}
	insertAnim(animName,anim_data)
	return anim_data

func getFramesFromPrefix(prefix: String, indices: Variant = PackedInt32Array(), animation_file: String = _animFile) -> Array:
	if indices is String: indices = get_indices_by_str(indices)
	if !indices: return AnimationService.getAnimFrames(prefix,animation_file)
	return AnimationService.getAnimFramesIndices(prefix,animation_file,indices)
	
func addAnimation(animName: String, frames: Array, fps: float = 24.0, loop: bool = false) -> Dictionary:
	if !frames: return {}
	return insertAnim(
		animName,
		{
			'looped': loop,
			'fps': fps,
			'frames': frames
		}
	)
	


##Add frame animation.
##To works, the [param region_rect.size] of the [member image] have to be defined, 
##that will be used as offset to which frame.
func addFrameAnim(animName: String, indices: PackedInt32Array = [], fps: float = 24.0, loop: bool = false) -> Dictionary:
	if !indices or !image or !image.texture: return {}
	var animData = {
		'frames': Array([],TYPE_DICTIONARY,'',null),
		'fps': fps,
		'looped': loop
	}
	var tex_size = image.texture.get_size() if image.texture else Vector2.ZERO
	var offset: Vector2 = image.region_rect.size
	
	for i in indices:
		var frameX = offset.x*i
		var frameY = int(frameX/tex_size.x)
		if frameY: frameX -= (tex_size.x*frameY)
		animData.frames.append({'region_rect': Rect2(Vector2(frameX,frameY*offset.y),offset)})
	animData.frames[0].size = offset
	if !_midpoint_set: _set_midpoint(offset)
	return insertAnim(animName,animData)
#endregion


func setImageAnimation(anim_name: String, _image: Texture2D):
	var anim_data = animationsArray.get(anim_name)
	if !anim_data: return
	if _image and image and image.texture and image.texture.resource_name == _image.resource_name: return
	setup_animation_textures()
	animationsArray[anim_name].asset = _image

##Sets the frame of the [param animName] that will return when the animation ends.[br][br]
##[b]OBS:[/b] The animation [u]must be looping[/u] to works.
func setLoopFrame(animName: String, frame: int) -> void:
	var anim_data = animationsArray.get(animName)
	if !anim_data: return
	anim_data.loop_frame = frame
	
func removeAnimation(anim_name: String) -> void:
	animationsArray.erase(anim_name)

func _set_midpoint(size: Vector2):
	if _midpoint_set or size == Vector2.ZERO: return
	size /= 2.0
	image.set('pivot_offset',size)
	if image_parent: image_parent.set('pivot_offset',size)
	_midpoint_set = true
	pivot_offset_setted.emit()

##Returns [code]true[/code] if the [param anim] exists, else, returns false.
func has_animation(anim: String) -> bool: return animationsArray.has(anim)

##Returns [code]true[/code] if the animator have any animations from [param anims].
func has_any_animations(anims: PackedStringArray) -> bool:
	for i in anims:
		if animationsArray.has(i): return true
	return false

##Clear Library, removing all the Animations from the Node.
func clearLibrary() -> void:
	stop()
	animationsArray.clear()
	_midpoint_set = false
	_midpoint_is_rotated = false

##Insert [Animation] to [member animations_array]. 
##If was no animation playing, the animation inserted will be played automatically.[br][br]
##See also [method addAnimation] and [method addFrameAnim].
func insertAnim(animName: String, animData: Dictionary = {}) -> Dictionary:
	if !animData: return {}
	if !animData.get('frames'): return animData
	animData.merge(getAnimBaseData(),false)
	
	if !_midpoint_set: update_midpoint_from_frame(animData.frames[0])
	
	animData.frames = adjustAnimationFramesToNode(animData.frames,image)
	animationsArray[animName] = animData
	
	if !current_animation: play(animName)
	elif animName == curAnim.name: update_anim(animName); play(animName,true); 
	
	if animations_use_textures and !animData.get('asset'): animData.asset = image.texture
	animation_added.emit(animName)
	return animData

func update_midpoint_from_frame(frame: Dictionary):
	var size = frame.get('frameSize')
	if !size: size = frame.get('size')
	if size: _set_midpoint(size)
	else: return
	if _midpoint_set: _midpoint_is_rotated = !!frame.get('rotation')
	
func setup_animation_textures():
	if animations_use_textures: return
	animations_use_textures = true
	for i in animationsArray.values():
		if !i.get('asset'): i.asset = image.texture
	image_animation_enabled.emit(true)

func can_play(anim: String, force: bool = false) -> bool:
	return animationsArray.has(anim) and (force or !curAnim.playing or curAnim.name != anim)

func _verify_anim_file() -> void:
	if !image or !image.texture: _animFile = ''; return
	_animFile = image.texture.resource_name
	if _animFile.ends_with('.png'): _animFile = _animFile.left(-4)
	_animFile = AnimationService.findAnimFile(_animFile)
#region Static Methods
static func getAnimBaseData() -> Dictionary[String,Variant]:
	return {
		'prefix': '',
		'fps': 24.0,
		'looped': false,
		'loop_frame': 0,
		'speed_scale': 1.0,
		'frames': Array([],TYPE_DICTIONARY,"",null)
	}

static func get_indices_by_str(indices: String) -> PackedInt32Array:
	if !indices: return PackedInt32Array()
	return PackedInt32Array(Array(indices.split(',')))


static func adjustAnimationFramesToNode(anim_data: Array, node: Object) -> Array:
	var has_offset = node.get('_frame_offset') != null
	var has_angle = node.get('_frame_angle') != null
	
	if not has_offset and not has_angle: return anim_data
	
	anim_data = anim_data.duplicate()
	for frame in anim_data:
		if has_offset:
			var _position = frame.get('position')
			if _position != null:
				frame._frame_offset = _position
				frame.erase('position')
		
		if has_angle:
			var _rotation = frame.get('rotation')
			if _rotation != null:
				frame._frame_angle = _rotation
				frame.erase('rotation')
	
	return anim_data
#endregion
