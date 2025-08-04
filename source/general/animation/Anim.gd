extends Resource
##A Animation custom class[br][br]
##[b]OBS:[/b] 
##The animation will just works when the parent's as a [NinePatchRect] or a
##[Sprite2D] with [member Sprite2D.region_rect] = [code]true[/code].

const AnimationService = preload("res://source/general/animation/AnimationService.gd")
const _AnimationController = preload("res://source/general/animation/AnimationController.gd")
const _sprite_sheet = preload("res://source/general/animation/spriteSheet.gd")


##Stores the dates of created animations. See also [method insertAnim].
var animationsArray: Dictionary[StringName,Variant] = {}

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
		
		if graphic: graphic.texture_changed.connect(_verify_anim_file)
		
		_verify_anim_file()
		if curAnim: curAnim.node_to_animate = image
		if !image: return

var _midpoint_set: bool = false
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
@export_range(0,20,0.1) var speed_scale:
	set(value): curAnim.speed_scale = value
	get(): return curAnim.speed_scale

var animation_finished: Signal:
	get(): return curAnim.animation_finished

signal animation_started(anim_name) ##Emitted when a animation starts.
signal animation_changed(old_anim,new_anim) ##Emitted when the animation changes.
signal animation_renamed(old_name,new_name) ##Emitted when a animation is renamed.
#endregion
func _set_auto_loop(loop: bool):
	if auto_loop == loop: return
	if loop: curAnim.animation_finished.connect(_verify_loop)
	else: curAnim.animation_finished.disconnect(_verify_loop)
	auto_loop = loop

func _verify_loop(anim):
	if animationsArray.has(anim+'-loop'): play(anim+'-loop'); return
	if animationsArray.has(anim+'-hold'): play(anim+'-hold'); return
	
##Play animation.[br][br]
##If [param force] is [code]true[/code], the animation will be forced to restart if already playing.[br]
##See also [method play_reverse].
func play(anim: StringName, force: bool = false) -> void:
	if !can_play(anim,force): return
	_update_anim(anim)

	curAnim.play()
	animation_started.emit(anim)

func _update_anim(anim: StringName = curAnim.name):
	var animData = animationsArray[anim]
	curAnim.name = anim
	curAnim.frames = animData.frames
	curAnim.frameRate = animData.fps
	curAnim.looped = animData.looped
	curAnim.loop_frame = animData.loop_frame
	curAnim.speed_scale = animData.speed_scale
	prefix = animData.prefix
	animation_changed.emit(current_animation,anim)

func play_reverse(anim: StringName, force: bool = false) -> void: ##Plays the animation from end to beggining. See also [method play]
	if !can_play(anim,force): return
	_update_anim(anim)
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

#region Add Animation Methods
##Add Animation from [u]Sparrow[/u]. Returns [code]true[/code] if the animation as added, [code]false[/code] otherwise.[br][br]
##To make the animation play specific frames, you can use [param indices], can be set as a [String] or a [Array]:[codeblock]
##var animation = Anim.new()
##animation.image = self
##animation.addAnimByPrefix('indices_array','prefix',24.0,false,[0,1,2,5,6]) #Using Array
##animation.addAnimByPrefix('indices_string','prefix',24,false,"0,1,2,3,4,5") #Using String
##[/codeblock]
func addAnimByPrefix(animName: StringName, prefix: StringName, fps: float = 24.0, loop: bool = false, indices: Variant = []) -> Dictionary:
	var anim_data = addAnimation(animName,getFramesFromPrefix(prefix,indices),fps,loop)
	if !anim_data: return {}
	anim_data.prefix = prefix
	return anim_data

func getFramesFromPrefix(prefix: String, indices: Variant = PackedStringArray(), animation_file: String = _animFile) -> Array:
	if indices is String: indices = get_indices_by_str(indices)
	return AnimationService.getAnim(prefix,animation_file,indices)
	
func addAnimation(animName: StringName, frames: Array, fps: float = 24.0, loop: bool = false) -> Dictionary:
	if !frames: return {}
	var animData = getAnimBaseData()
	animData.looped = loop
	animData.fps = fps
	animData.frames = frames
	return insertAnim(animName,animData)
	


##Add frame animation.
##To works, the [param region_rect.size] of the [member image] have to be defined, 
##that will be used as offset to which frame.
func addFrameAnim(animName: StringName, indices: Array = [], fps: float = 24.0, loop: bool = false) -> Dictionary:
	if !image or !image.texture: return {}
	var animData = getAnimBaseData()
	var frames = animData.frames
	animData.fps = fps
	animData.looped = loop
	
	var tex_size = image.texture.get_size() if image.texture else Vector2.ZERO
	
	var offset: Vector2 = image.region_rect.size
	
	for i in indices:
		var frameX = offset.x*i
		var frameY = int(frameX/tex_size.x)
		frameX -= (tex_size.x*frameY)
		frames.append({"region_rect": Rect2(frameX,offset.y*frameY,offset.x,offset.y)})
	
	if !frames: return {}

	frames[0]["size"] = offset
	if !_midpoint_set: _set_midpoint(offset/2.0)
	return insertAnim(animName,animData)
#endregion


##Sets the frame of the [param animName] that will return when the animation ends.[br][br]
##[b]OBS:[/b] The animation [u]must be looping[/u] to works.
func setLoopFrame(animName: String, frame: int) -> void:
	if !animationsArray.has(animName): return
	animationsArray[animName].loop_frame = frame
	
func removeAnimation(anim_name: String) -> void:
	animationsArray.erase(anim_name)

func renameAnimation(anim_name: StringName, new_name: StringName):
	if !animationsArray.has(anim_name): return
	#var data = animationsArray[anim_name]
	#animationsArray.erase(anim_name)
	#animationsArray[new_name] = anim_name
	DictionaryHelper.rename_key(animationsArray,anim_name,new_name)
	animation_renamed.emit(anim_name,new_name)
	
func _set_midpoint(size: Vector2):
	var parent = get_image_parent(image)
	if _midpoint_set or !parent or size == Vector2.ZERO: return
	image.pivot_offset = size
	parent.pivot_offset = size
	_midpoint_set = true
	pivot_offset_setted.emit()

##Returns [code]true[/code] if the [param anim] exists, else, returns false.
func has_animation(anim: StringName) -> bool: return animationsArray.has(anim)

##Returns [code]true[/code] if the animator have any animations from [param anims].
func has_any_animations(anims: PackedStringArray) -> bool:
	for i in anims:
		if animationsArray.has(i): return true
	return false

##Returns [code]true[/code] if the current animation is playing.
func is_playing() -> bool: return curAnim.playing

##Clear Library, removing all the Animations from the Node.
func clearLibrary() -> void:
	stop()
	animationsArray.clear()
	_midpoint_set = false
	
##Insert [Animation] to [member animations_array]. 
##If was no animation playing, the animation inserted will be played automatically.[br][br]
##See also [method addAnimation] and [method addFrameAnim].
func insertAnim(animName: String, animData: Dictionary = {}) -> Dictionary:
	if !animData: animData = getAnimBaseData()
	if !animData.frames: return animData
	
	animData.frames = adjustAnimationToNode(animData.frames,image)
	animationsArray[animName] = animData
	
	if !current_animation or animName == curAnim.name: play(animName,true)
	
	if !_midpoint_set:
		var frame = animData.frames[0]
		if frame.has('frameSize'): _set_midpoint(frame.frameSize/2.0)
		elif frame.has('size'): _set_midpoint(frame.size/2.0)
	
	animation_added.emit(animName)
	return animData

func can_play(anim: String, force: bool = false) -> bool:
	return animationsArray.has(anim) and (force or !curAnim.playing or curAnim.name != anim)

func _verify_anim_file() -> void:
	if !image or !image.texture: _animFile = ''; return
	_animFile = AnimationService.findAnimFile(image.texture.resource_name)
#region Static Methods
static func get_image_parent(image: CanvasItem): return image.get_parent() if image.get_parent() else image


static func getAnimBaseData() -> Dictionary[StringName,Variant]:
	return {
		'prefix': '',
		'fps': 24.0,
		'looped': false,
		'loop_frame': 0,
		'speed_scale': 1.0,
		'type': 'sparrow',
		'frames': Array([],TYPE_DICTIONARY,"",null)
	}

static func get_indices_by_str(indices: String) -> PackedInt32Array:
	if !indices: return PackedInt32Array()
	return Array(indices.split(','))
	
static func adjustAnimationToNode(anim_data: Array, node: Object) -> Array:
	var has_offset = node.get('_frame_offset') != null
	var has_angle = node.get('_frame_angle') != null
	
	if not has_offset and not has_angle: return anim_data
	
	for frame in anim_data:
		if has_offset and frame.has('position'):
			frame["_frame_offset"] = frame.position
			frame.erase('position')
		
		if has_angle and frame.has('rotation'):
			frame["_frame_angle"] = frame.rotation
			frame.erase('rotation')
	
	return anim_data
#endregion
