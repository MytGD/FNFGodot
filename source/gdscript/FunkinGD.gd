class_name FunkinGD

const SpriteAnimated = preload("res://source/objects/Sprite/SpriteAnimated.gd")
const GDText = preload("res://source/objects/Display/GDText.gd")

const Bar = preload("res://source/objects/UI/Bar.gd")
const EventNote = preload("res://source/objects/Notes/EventNote.gd")
const Note = preload("res://source/objects/Notes/Note.gd")
const NoteSustain = preload("res://source/objects/Notes/NoteSustain.gd")
const NoteHit = preload("res://source/objects/Notes/NoteHit.gd")
const StrumNote = preload("res://source/objects/Notes/StrumNote.gd")

const Stage = preload("res://source/gdscript/FunkinStage.gd")

const PlayStateBase = preload("res://source/states/PlayStateBase.gd")
const Character = preload("res://source/objects/Sprite/Character.gd")
const Icon = preload("res://source/objects/UI/Icon.gd")

const source_dirs: PackedStringArray = [
	'res://source/',
	'res://source/backend',
	'res://source/states',
	'res://source/substates'
]

const methods_parameters: Dictionary = {
	'onEvent': [TYPE_STRING,TYPE_DICTIONARY],
	'onUpdate': [TYPE_FLOAT],
	'onUpdatePost': [TYPE_FLOAT],
	'onTweenCompleted': [TYPE_STRING_NAME],
	'onTimerCompleted': [TYPE_STRING_NAME],
	'onLoadCharacter': [TYPE_OBJECT,TYPE_STRING],
	'onMoveCamera': [TYPE_STRING]
}

@export_category('Class Vars')
static var started: bool = false

static var Function_Continue: int = 0
static var Function_Stop: int = 1


static var isStoryMode: bool = false
static var game: Object
static var camGame: CameraCanvas:
	get():
		return game.camGame
		
static var camHUD: CameraCanvas:
	get():
		return game.camHUD
		
static var camOther: CameraCanvas:
	get():
		return game.camOther

static var botPlay: bool:
	get():
		return game.botplay

##The path of the script.
var scriptPath: StringName = ''

##The Mod Folder of the script.
var scriptMod: String = ''


@export_category("Files Saved")

##[b]Variables[/b] created using [method setVar] and [method createCamera] methods.
static var modVars: Dictionary[String,Variant] = {}

##Sprites created using [method makeSprite] or [method makeAnimatedSprite] methods.
static var spritesCreated: Dictionary[String,Node] = {}

##Sprite groups created using [method createSpriteGroup] method.
static var groupsCreated: Dictionary[String,SpriteGroup] = {}

static var dictionariesToCheck = [modVars,spritesCreated,textsCreated,groupsCreated]

##[b][Tween][/b] created using [method startTween] function.
static var tweensCreated: Dictionary[String,Tween] = {}

##[b]Shaders[/b] created using [method initShader] function.
static var shadersCreated: Dictionary[String,ShaderMaterial] = {}


##A Dictionary that stores the cameras used the shader.
static var shadersCameras: Dictionary[String,Array] = {}

##[b]Sounds[/b] created using [method playSound] function.
static var soundsPlaying: Dictionary[String,AudioStreamPlayer] = {}

##[b]Timers[/b] created using [method runTimer] function.
static var timersPlaying: Dictionary[String,Array] = {}

##Scripts created using [method addScript] function.
static var scriptsCreated: Dictionary = {}

##[b]Texts[/b] created using [method makeText] function.
static var textsCreated: Dictionary[String,GDText] = {}

##Used to precache the Methods in the script, being more optimized for calling functions in [method callOnScripts]
static var method_list: Dictionary[String,Array] = {}

@export_group('Game Data')
static var playAsOpponent:
	set(play):
		game.playAsOpponent = play
	get():
		return game.playAsOpponent
		
static var lowQuality: bool: ##low quality.
	get():
		return ClientPrefs.data.lowQuality

static var screenWidth: float: ##The Width of the Screen.
	get(): return ScreenUtils.screenWidth
		
static var screenHeight: float: ##The Height of the Screen.
	get(): return ScreenUtils.screenHeight

static var screenSize: Vector2i: ##The Size of the Screen.
	get(): return ScreenUtils.screenSize


static var inCutscene: bool:
	get(): return game.inCutscene

static var seenCutscene: bool: ##See [member PlayStateBase.seenCustscene].
	get(): return game.seenCutscene

static var inGameOver: bool = false

@export_category("Song Data")
static var curStage: String:
	get(): return game.curStage

static var songName: String: ##song name.
	get(): return Conductor.songName

static var songStarted: bool:
	get(): return !!Conductor.songs

static var songLength: float:
	get(): return game.songLength
	
static var difficulty: String:
	get(): return Conductor.songDifficulty

static var mustHitSection: bool = false ##If the section is bf focus

static var gfSection: bool = false ##GF Section Focus

static var altAnim: bool = false ##Alt Section Animation

#region Conductor Properties
static var bpm: float
static var crochet: float
static var stepCrochet: float

static var curBeat: int
static var curStep: int

static var curSection: int
static var keyCount: int
#endregion
@export_category("Client Prefs")
static var middlescroll: bool
static var downscroll: bool
static var hideHud: bool

static var hideTimeBar: bool
	
static var timeBarType: String

static var shadersEnabled: bool:
	get(): return ClientPrefs.data.shadersEnabled

static var version: String = '0.7.3' ##Engine Version

static var cameraZoomOnBeat: bool = true

static var flashingLights: bool:
	get(): return ClientPrefs.data.flashingLights

static var framerate: float = 60.0



static var arguments: Dictionary[int,Dictionary] = {}

func _init() -> void:
	if scriptMod in Paths.commomFolders: scriptMod = ''
	
static var Conductor_Signals: Dictionary[StringName,Callable] = {
	'section_hit': _section_hit,
	'section_hit_once': callOnScripts.bind('onSectionHitOnce'),
	'beat_hit': _beat_hit,
	'step_hit': _step_hit,
	'bpm_changes': _bpm_changes
}

static func init_gd():
	if started or !Conductor: return
	started = true
	for i in Conductor_Signals:
		Conductor[i].connect(Conductor_Signals[i])
	_bpm_changes()
static func _bpm_changes():
	bpm = Conductor.bpm
	stepCrochet = Conductor.stepCrochet
	crochet = Conductor.crochet
static func _beat_hit():
	curBeat = Conductor.beat
	callOnScripts('onBeatHit')
	

static func _step_hit():
	curStep = Conductor.step
	callOnScripts('onStepHit')
	

static func _section_hit():
	curSection = Conductor.section
	callOnScripts('onSectionHit')
	
static func get_arguments(script: Object) -> Dictionary[String,Array]:
	var functions: Dictionary[String,Array] = {}
	for function in script.get_script().get_script_method_list():
		#Verify if the function is static
		if function.flags == 33: continue
		
		var index: int = 0
		var func_name = function.name
		var funcArgs = function.args
		
		if func_name in methods_parameters:
			var default_args = methods_parameters[func_name]
			for i in funcArgs:
				i.type = ArrayHelper.get_array_index(default_args,index,TYPE_NIL)
				i.default = type_convert(null,i.type)
				index += 1
		else:
			funcArgs.reverse()
			function.default_args.reverse()
			
			var default_args = function.default_args
			for i in funcArgs:
				i.default = ArrayHelper.get_array_index(
					default_args,
					index,
					MathHelper.get_new_value(i.type)
				)
			funcArgs.reverse()
		
		functions[func_name] = funcArgs
	return functions
	
#region File Methods
static func checkFileExists(path: String) -> bool: ##Similar to [method Paths.file_exists].
	return Paths.file_exists(path)

static func characterExists(char_name: String) -> bool:
	return Paths.file_exists('characters/'+char_name+'.json')
	
static func precacheImage(path: String) -> Image: ##Precache a image, similar to [method Paths.image]
	return Paths.image(path)
	
static func precacheMusic(path: String) -> AudioStreamOggVorbis: ##Precache a music, similar to [method Paths.music]
	return Paths.music(path)
	
static func precacheSound(path: String) -> AudioStreamOggVorbis: ##Precache a sound, similiar to [method Paths.sound]
	return Paths.sound(path)

static func precacheVideo(path: String) -> VideoStreamTheora:
	return Paths.video(path)
	
static func addCharacterToList(character: String, type = 'bf') -> void: ##Precache character.
	if  not (Paths.character(character) and game):
		return
	if type is int:
		if type == 1:
			type = 'dad'
		elif type == 2:
			type = 'gf'
		else:
			type = 'bf'
	
	if type == 'bf':
		game.addCharacterToList(0,character)
	elif type == 'dad':
		game.addCharacterToList(1,character)
	elif type == 'gf':
		game.addCharacterToList(2,character)

static func _clear_scripts(absolute: bool = false):
	if absolute:
		for i in spritesCreated.values(): i.queue_free()
		for i in timersPlaying.values(): i[0].stop()
		for i in tweensCreated.values(): i.stop()
		for i in groupsCreated.values(): i.queue_free()
		
	soundsPlaying.clear()
	method_list.clear()
	shadersCreated.clear()
	scriptsCreated.clear()
	shadersCreated.clear()
	modVars.clear()
	spritesCreated.clear()
	groupsCreated.clear()
	timersPlaying.clear()
	tweensCreated.clear()
	
	if !started: return
	started = false
	for i in Conductor_Signals:
		Conductor[i].disconnect(Conductor_Signals[i])
	
#endregion


#region Property methods
const alternative_variables: Dictionary = {
	'alpha': 'modulate:a',
	'angle': 'rotation_degrees',
	'shader': 'material',
	'color': 'modulate',
	'origin': 'pivot_offset'
}

##Set a property. 
##If [param target] is defined, the function will try to set its [param variable].
const property_replaces: Dictionary = {
	'[': '.',
	']': '',
	':': '.'
}
##Set a Property. If [param target] set, the function will try to set the property from this object.
static func setProperty(property: Variant, value: Variant, target: Variant = null) -> void:
	var split: PackedStringArray
	if !target:
		target = _find_object(property,true)
		if !target[0]: 
			push_error('Error on setting property: '+str(property.split('.')[0])+" not founded")
			return
		split = target[1]
		target = target[0]
	else:
		#split = StringHelper.replace_chars_from_dict(property,property_replaces).split('.')
		split = property.split('.')
	
	
	var value_to_set: String = split[split.size()-1]
	
	var _property: String
	var prev_obj
	
	var index: int = 0
	
	while index < split.size()-1:
		_property = split[index]
		if MathHelper.value_exists(target,_property):
			prev_obj = target
			target = target[_property]
			index += 1
			continue
		if alternative_variables.has(_property):
			setProperty(alternative_variables[_property],value,target)
			return
		push_error('Error on setting property: '+str(_property)+" not founded in "+str(target))
		return
	
	#Set Value
	match typeof(target):
		TYPE_OBJECT,TYPE_DICTIONARY: target.set(value_to_set,value)
		
		TYPE_VECTOR2,TYPE_VECTOR2I,TYPE_VECTOR3,TYPE_VECTOR3I,TYPE_VECTOR4,TYPE_VECTOR4I:
			match value_to_set:
				'x','r': target.x = value
				'y','g': target.y = value
				'z','b': target.z = value
				'w','a': target.w = value
			
			prev_obj[_property] = target
		TYPE_COLOR:
			match value_to_set:
				'r','x': target.r = value
				'g','y': target.g = value
				'b','z': target.b = value
				'a','w': target.a = value
			prev_obj[_property] = target
		
		_: target[value_to_set] = value

static func setVar(variable: String, value: Variant = null) -> void: modVars[variable] = value

##Get a variable from the [member modVars].
static func getVar(variable: String) -> Variant: return modVars.get(variable)

static func getProperty(property: String, from: Variant = null) -> Variant: ##Get a Property from the game.
	var split: PackedStringArray
	if from == null:
		from = _find_object(property,true)
		if !from[0]: return null
		split = from[1]
		from = from[0]
	else:
		#varSplit = get_as_property(property).split('.')
		split = property.split('.')
	
	for i in split:
		from = _get_variable(from,i)
		if from == null: return null
	return from

static func _find_property_owner(property: String) -> Variant:
	if game and game.get(property) != null: return game
	for i in dictionariesToCheck:
		if i.has(property): return i
	return null
	
static func _find_object(property: Variant, return_rest: bool = false) -> Variant:
	if property is Object: return property
	#var split = get_as_property(property).split('.')
	
	var split = get_as_property(property).split('.')
	var key = split[0]
	var object = _find_property_owner(key)
	if !object:
		if return_rest: return [null, split]
		return null
	
	var index: int = 0
	while index < split.size():
		var variable = _get_variable(object,split[index])
		
		if variable == null: 
			if return_rest: return [null, split]
			return null
		elif !is_indexable(variable): break
		object = variable
		index += 1
	
	if return_rest: return [object,split.slice(index)]
	return object
	
static func get_as_property(property: String) -> String:
	return StringHelper.replace_chars_from_dict(property,property_replaces)


static func _get_variable(obj: Variant, variable: String) -> Variant:
	var type = typeof(obj)
	if ArrayHelper.is_array_type(type): return obj.get(int(variable))
	
	if VectorHelper.is_vector_type(type):
		if variable.is_valid_int(): return obj[int(variable)]
		return obj[variable]
	
	match type:
		TYPE_DICTIONARY: return obj.get(variable)
		TYPE_OBJECT: 
			var value = obj.get(variable)
			if value == null and variable.find(':'):
				value = obj.get_indexed(variable)
			if value == null and variable in alternative_variables:
				return _get_variable(obj,alternative_variables[variable])
			return value
		TYPE_COLOR: return obj[variable]
		_: return null

static func is_indexable(variable: Variant) -> bool:
	if !variable: return false
	var type = typeof(variable)
	
	if ArrayHelper.is_array_type(type):return true
	match type:
		TYPE_OBJECT,TYPE_DICTIONARY: return true
		_: return false
#endregion


#region Class Methods
static func _find_class(object: String) -> Object:
	if Engine.has_singleton(object): return Engine.get_singleton(object)
	
	var tree = Global.get_tree().root
	if tree.has_node(object): return tree.get_node(object)
	

	object = object.replace('.','/')
	if not object.ends_with('.gd'): object += '.gd'
	
	for i in source_dirs:
		var path = i+object
		if FileAccess.file_exists(path): return load(path)
		
	return null
	
static func getPropertyFromClass(_class: String, variable: String):
	var class_obj = _find_class(_class)
	if !class_obj:
		return
	return getProperty(variable,class_obj)
	
static func setPropertyFromClass(_class: String,variable: String,value: Variant) -> void:##Set the variable of the [code]_class[/code]
	var class_obj = _find_class(_class)
	if !class_obj:
		return
	setProperty(variable,value,class_obj)
#endregion


#region Group Methods
static func _find_group_members(_group_name: String, member_index: int) -> Object:
	var group = getProperty(_group_name)
	if !group:
		return null
	
	if group is SpriteGroup:
		group = group.members
	
	if !group is Array:
		return null
	
	return ArrayHelper.get_array_index(group,member_index)
	
##Add [Sprite] to a [code]group[/code] [SpriteGroup] or [Array].[br][br]
##If [code]at = -1[/code], the sprite will be inserted at the last position.
static func addSpriteToGroup(object: Variant, group: Variant, at: int = -1) -> void:
	object = _find_object(object)
	if !object:
		return
	
	if group is String:
		group = _find_object(group)
		
	if !group:
		return
	
	if group is SpriteGroup:
		if at != -1:
			group.insert(at,object)
		else:
			group.add(object)
		return
	
	if group is Array:
		if at != -1:
			group.insert(at,object)
		else:
			group.append(object)
	
static func removeFromGroup(group: Variant, index: int):
	if group is String:
		group = getProperty(group)
	
	if !group:
		return
	
	if group is SpriteGroup or group is Array:
		group.remove_at(index)

##Get a Property from a [SpriteGroup] or [Array]
static func getPropertyFromGroup(group: String, index: Variant = 0, variable: String = "") -> Variant: 
	if !variable: return _find_group_members(group,int(index))
	return getProperty(variable,_find_group_members(group,int(index)))

##Set the [code]variable[/code] of the object at the [code]index[/code] from a [SpriteGroup] or [Array]
static func setPropertyFromGroup(group: String, index: Variant, variable: String, value: Variant) -> void:
	var obj = _find_group_members(group,int(index))
	if !obj:
		return
	setProperty(variable,value,obj)
#endregion


#region Timer Methods
##Runs a timer, return the [Timer] created.
static func runTimer(tag: String, time: float, loops: int = 1) -> Timer:
	if !time: callOnScripts('onTimerCompleted',[tag,loops])
	var timer: Timer
	if timersPlaying.get(tag):
		timer = timersPlaying[tag][0]
	else:
		timer = Timer.new()
		
		(game if game else Global).add_child(timer)
		
		timer.timeout.connect(func():
			if loops > 1:
				timer.start(time)
				loops -= 1
			else:
				timersPlaying.erase(tag)
				timer.queue_free()
			callOnScripts('onTimerCompleted',[tag,loops])
		)
	
	timer.start(time)
	timersPlaying[tag] = [timer,loops]
	return timer

static func getTimerLoops(tag: String) -> int:
	return timersPlaying[tag][1] if timersPlaying.has(tag) else 0
	
static func cancelTimer(tag: String): ##Cancel Timer. See also [method runTimer].
	if not tag in timersPlaying:
		return
	var timer: Timer = timersPlaying[tag][0]
	timer.stop()
	timersPlaying.erase(tag)
	timer.free()

#endregion


#region Random Methods
##Return a random [int], replaced by [method @GlobalScope.randi_range].
static func getRandomInt(minimum: int = 0, maximum: int = 1) -> int:
	return randi_range(minimum,maximum)

##Return a random [bool].
static func getRandomBool(chance: int = 50) -> bool:
	return randi_range(0,100) <= chance

##Return a random [float], replaced by [method @GlobalScope.randf_range].
static func getRandomFloat(minimum: float = 0.0,maximum: float = 1.0) -> float:
	return randf_range(minimum,maximum)
#endregion

#region Stage Methods
static func getSpritesFromStageJson() -> PackedStringArray:
	var stages = PackedStringArray()
	for i in Stage.json.get('props',[]): if i.get('name'): stages.append(i.name)
	return stages
#endregion

#region Sprite Methods
##Creates a [Sprite].
static func makeSprite(tag: String, path: Variant = null, x: float = 0, y: float = 0) -> Sprite: 
	var sprite = Sprite.new(path)
	sprite._position = Vector2(x,y)
	if tag:
		sprite.name = tag
	if spritesCreated.get(tag) and spritesCreated[tag] is Node:
		spritesCreated[tag].queue_free()
	spritesCreated[tag] = sprite
	return sprite

##Creates a animated [Sprite].
static func makeAnimatedSprite(tag: String, path: Variant = null, x: float = 0, y: float = 0) -> Sprite: 
	var sprite = makeSprite(tag,path,x,y)
	sprite.is_animated = true
	return sprite

static func makeSpriteFromSheet(tag: String,path: Variant, sheet_preffix: String,x: float = 0, y: float = 0):
	var sprite = makeSprite(tag,path,x,y)
	return sprite


static func addSprite(object: Variant, front: bool = false) -> void: ##Add [Sprite] to game.
	object = _find_object(object)
	
	if !object: return
	
	var cam: Node = object.get('camera')
	
	if !cam:
		cam = getProperty('camGame')
	if !cam:
		push_error("Failed in addSprite: Camera of ",object,"don't found.")
		return
	
	if cam is CameraCanvas:
		cam.add(object,front)
		return
	
	if cam is Node:
		cam.add_child(object)

##Add a [Sprite] in a determined order.
static func addSpriteAt(object: Variant, order: int = -1) -> void:
	if order == -1: addSprite(object,false); return;
	
	var cam: Node = object.get('camera')
	if !cam: cam = getProperty('camGame')
	if !cam:
		push_error("Failed in addSpriteAt: Camera of ",object,"don't found.")
		return
	
	if cam is CameraCanvas:
		cam.insert(order,object)
		return
	
	if cam is Node:
		cam.add_child(object)
		cam.move_child(object,order)

##Add a [Sprite] to a [param camera].
static func addSpriteToCamera(object: Variant, camera: Variant, front: bool = false) -> void:
	object = _find_object(object)
	if !object: return
	
	camera = getCamera(camera)
	
	if !camera: return
	
	if camera is CameraCanvas:
		camera.add(object,front)
		return
	
	if camera is Node:
		camera.add_child(object)

##Remove [Sprite] of the game. When [code]delete[/code] is true, the sprite will be remove completely.
static func removeSprite(object: Variant, delete: bool = false) -> void:
	var tag
	if object is Node:
		tag = object.name
	else:
		tag = object
		object = _find_object(object)

	if !object: return
		
	if object.is_inside_tree():
		object.get_parent().remove_child(object)
	if delete:
		modVars.erase(tag)

##Creates a [SpriteGroup].
static func createSpriteGroup(tag: String, index: int = game.dadGroup.get_index()) -> SpriteGroup:
	var group = SpriteGroup.new()
	var group_found = groupsCreated.get(tag)
	if group_found is Node: group_found.queue_free()
	groupsCreated[tag] = group
	return group

static func makeGraphic(object: Variant,width: float = 0.0,height: float = 0.0,color: String = 'FFFFFF') -> void:
	if object is String:
		var _sprite_name = object
		object = _find_object(object)
		if !object: object = makeSprite(_sprite_name)
	if !object: return
	if object is Sprite: object.makeGraphic(width,height,Color.from_string(color,Color.BLACK))


##Load image in the sprite.
static func loadGraphic(object: Variant, image: String, width: float = -1, height: float = -1) -> void:
	object = _find_object(object)
	if !object: return
	if object is Sprite: object = object.image
	object.texture = Paths.imageTexture(image)
	#object.image.size = Vector2(width,height)


##Changes the image size of the sprite.[br]
##[b]Note:[/br] Just works if the sprite is not animated.
static func setGraphicSize(object: Variant, sizeX: float = -1, sizeY: float = -1) -> void:
	object = _find_object(object)
	if !object: return
	object.graphic.size = Vector2(
		object.graphic.size.x if sizeX == -1 else sizeX,
		object.graphic.size.y if sizeY == -1 else sizeY
	)
		
##Move the [param object] to the center of his camera.[br]
##[param type] can be: [code]""xy,x,y[/code]
static func screenCenter(object: Variant, type: String = 'xy') -> void:
	object = _find_object(object)
	if !object: return
		
	var pos = Vector2.ZERO
	if object.has_method('screenCenter'): object.screenCenter(type)
	else:
		pos = screenSize/2.0
		
		var tex = object.get('texture')
		if tex: object -= tex.get_size()/2.0
		
		match type:
			'x': object.position.x = pos.x
			'y': object.position.y = pos.x
			_: object.position = pos

##Scale object.
##If not [param centered], the sprite will scale from his top left corner.
static func scaleObject(object: Variant,x: float = 1.0,y: float = 1.0, centered: bool = false) -> void:
	object = _find_object(object)
	if !object: return
	object.set('scale',Vector2(x,y))
	if !centered and object is Sprite: object.offset = object.pivot_offset*(Vector2.ONE - object.scale)

##Set the scroll factor from the sprite.[br]
##This makes the object have a depth effect, [u]the lower the value, the greater the depth[/u].
static func setScrollFactor(object: Variant, x: float = 1, y: float = 1) -> void:
	var obj = _find_object(object)
	if obj: obj.set('scrollFactor',Vector2(x,y))

##Set the order of the object in the screen, similar to [member CanvasItem.z_index].
static func setObjectOrder(object: Variant, order: int)  -> void:
	object = _find_object(object)
	if not object: return
	
	var parent: Node = object.get('_parent_camera')
	if parent is CameraCanvas:
		parent.move_to_order(object,order)
		return
	parent = object.get_parent()
	if parent: parent.move_child(object,clamp(order,0,parent.get_child_count()))

##Returns the object's order.
static func getObjectOrder(object: Variant) -> int:
	object = _find_object(object)
	if !object: return 0
	return object.get_index() if object is Node else -1

static func updateHitbox(object: Variant) -> void:
	object = _find_object(object)
	if !object: return
	if object is Sprite: object.centerOrigin()
	
static func updateHitboxFromGroup(group: String, index) -> void: updateHitbox(_find_group_members(group,int(index)))

##Returns if the sprite, created using [method makeSprite] or [method makeAnimatedSprite] or [method setVar], exists.
static func spriteExists(tag: StringName) -> bool:
	return spritesCreated.get(tag) is Sprite or modVars.get(tag) is Sprite
	

##Returns the midpoint.x of the object. See also [method getMidpointY].
static func getMidpointX(object: Variant) -> float:
	object = _find_object(object)
	if object is Sprite: return object.getMidpoint().x
	if (object is CanvasItem) and object.get('texture'): return object.position.x + (object.texture.get_size().x/2.0)
	return 0.0

##Returns the midpoint.y of the object. See also [method getMidpointX].
static func getMidpointY(object: Variant) -> float:
	object = _find_object(object)
	if object is Sprite: return object.getMidpoint().y
	if (object is CanvasItem) and object.get('texture'): return object.position.y + (object.texture.get_size().y/2.0)
	return 0.0
#endregion


#region Animation Methods
##Add Animation Frames for the [param object], useful if you are creating custom [Icon]s.
static func addAnimation(object: Variant, animName: StringName, frames: Array = [], frameRate: float = 24, loop: bool = false) -> Dictionary:
	object = _find_object(object)
	if !object or !object.get('animation'): return {}
	return object.animation.addFrameAnim(animName,frames,frameRate,loop)
	
##Add animation to a [Sprite] using the prefix of his image.
static func addAnimationByPrefix(object: Variant, animName: StringName, xmlAnim: StringName, frameRate: float = 24, loop: bool = false) -> Dictionary:
	object = _find_object(object)
	if !object or !object.get('animation'): return {}
	var frames = object.animation.addAnimByPrefix(animName,xmlAnim,frameRate,loop)
	return frames

##Add [Animation] using the preffix of the sprite, can set the frames that will be played
static func addAnimationByIndices(object: Variant, animName: StringName, xmlAnim: StringName, indices: Variant = [], frameRate: float = 24, loop: bool = false) -> Dictionary:
	object = _find_object(object)
	if !object or !object.get('animation'): return {}
	return object.animation.addAnimByPrefix(animName,xmlAnim,frameRate,loop,indices)


##Makes the [param object] play a animation, if exists. If [param force] and the current anim as the same name, that anim will be restarted.
static func playAnim(object: Variant, anim: StringName, force: bool = false, reverse: bool = false) -> void:
	object = _find_object(object)
	if not (object is Sprite and object.animation): return
	object.animation.play(anim,force)

##Add offset for the animation of the sprite.
static func addOffset(object: Variant, anim: StringName, offsetX: float, offsetY: float)  -> void:
	object = _find_object(object)
	if object is Sprite: object.addAnimOffset(anim,offsetX,offsetY)

#endregion


#region Text Methods
##Creates a Text
static func makeText(tag: String,text: Variant = '', width: float = 500, x: float = 0, y:float = 0) -> GDText:
	removeText(tag)
	var newText = GDText.new(str(text),x,y,width)
	newText.name = tag
	modVars[tag] = newText
	return newText


##Set the text string
static func setTextString(reference: Variant, text: Variant = '') -> void:
	reference = _find_object(reference)
	if reference is Label:
		reference.text = str(text)

##Set the color from the text
static func setTextColor(text: Variant, color: Variant) -> void:
	text = _find_object(text)
	if text is Label: text.color = _get_color(color)

##Set Text Border
static func setTextBorder(text: Variant, border: float, color: Color = Color.BLACK) -> void:
	text = _find_object(text)
	if !text is GDText: return
	text.label_settings.outline_color = color
	text.label_settings.outline_size = border
	
##Set the Font of the Text
static func setTextFont(text: Variant, font = 'vcr.ttf') -> void:
	text = _find_object(text)
	if text is GDText: text.set_font(font)
	elif text is Label:
		var fontText = Paths.font(font)
		if fontText != null: text.add_theme_font_override(fontText)
	
##Set the Text Alignment
static func setTextAlignment(tag: Variant, alignmentHorizontal: StringName = 'left', alignmentVertical: StringName = '') -> void:
	var obj = _find_object(tag)
	if !obj is Label: return
		
	match alignmentHorizontal:
		'left': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		'center': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		'right': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		'fill': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	
	match alignmentVertical:
		'left': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		'center': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		'right': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		'fill': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	
	match alignmentVertical:
		'top': obj.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		'center': obj.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		'bottom': obj.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		'fill': obj.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		

##Set the font's size of the Text
static func setTextSize(text: Variant, size: float = 15) -> void:
	text = _find_object(text)
	if !text is Label: return
	if !text.label_settings: text.label_settings = LabelSettings.new()
	text.label_settings.font_size = size
		
##Add Text to game
static func addText(text: Variant, front: bool = false) -> void:
	text = _find_object(text)
	if !text is Label: return
	
	var cam = text.get('camera')
	if !cam: cam = camHUD; if !cam: return
	if cam is CameraCanvas: cam.add(text,front)
	else: cam.add_child(text)

##Returns the string of the Text
static func getTextString(tag: String) -> String:
	if tag in textsCreated: return textsCreated[tag].text
	return ''

##Remove Text from the game, if [code]delete[/code] is [code]true[/code], the text will be removed from the memory.
static func removeText(text: Variant,delete: bool = false) -> void:
	text = _find_object(text)
	if !text: return
	if delete: textsCreated.erase(text.name); text.queue_free()
	else: var parent = text.get_parent(); if parent: parent.remove_child(text)

##Check if the Text as created
static func textsExits(tag: String) -> bool: return textsCreated.has(tag)
#endregion


#region Tween Methods
##Start Tween. See [method TweenHelper.createTween] to see how its works.
static func startTween(tag: String,object: Variant, what: Dictionary,time = 1.0, easing: String = '') -> Tween:
	if object is String:
		var split = _find_object(object,true)
		object = split[0]
		if split[1]:
			var split_join = String(":").join(split[1])
			for i in what.keys(): DictionaryHelper.rename_key(what,i,split_join+':'+i)
	
	if !object: return
	
	#Create Tween
	var bind_node = game if game else Global
	var tween: Tween = bind_node.create_tween()
	tween = TweenHelper.set_tween_ease(tween,easing)
	tween.set_parallel()
	tween = tween.bind_node(bind_node)
	
	#Start
	for property: String in what:
		var has_variable: bool = object.get(property) != null
		if has_variable == null and property.contains(':'):
			has_variable = object.get_indexed(property) != null
		if has_variable: 
			tween.tween_property(object,property,what[property],time)
		elif alternative_variables.has(property):
			
			tween.tween_property(object,alternative_variables[property],what[property],time)
			
	tween.finished.connect(_tween_completed.bind(tag))
	if !tag: return tween
	cancelTween(tag)
	tweensCreated[tag] = tween
	return tween


##Similar to [method Tween.tween_method].
static func startTweenMethod(tag: String, from: Variant, to: Variant, time, ease: String, method: Callable) -> Tween:
	cancelTween(tag)
	var tween = TweenHelper.createTweenMethod(method,from,to,time,ease,game)
	tweensCreated[tag] = tween
	return tween

static func _tween_completed(tag: String):
	callOnScripts('onTweenCompleted',[tag])
	tweensCreated.erase(tag)

##Do Tween for a [ShaderMaterial].[br][br]
##[code]shader[/code] can be a [ShaderMaterial] or a tag([String]) used in [method initShader].
##Example of Code:[codeblock]
##var shader_material: ShaderMaterial = Paths.loadShader('ChromaticAbberration')
##setShaderFloat(shader_material,'strength',0.005)
##doShaderTween(shader_material,'strength',0.0,0.2,'linear','chrom_tag')
##
##initShader('ChromaticAbberation','chrom')
##setShaderFloat('chrom','strength',0.01)
##doShaderTween('chrom','strength',0.0,0.2,'linear','chrom_tag')[/codeblock]
static func doShaderTween(shader: Variant, parameter: StringName, value: float, time: float, ease: StringName = 'linear', tag: StringName = '') -> Tween:
	var material = _find_shader_material(shader)
	if !material:
		return
	if !tag and shader is String:
		tag = 'shader'+shader+parameter

	var tween = TweenHelper.tween_shader(material,parameter,float(value),float(time),ease,game)
	if tag:
		cancelTween(tag)
		tweensCreated[tag] = tween
	return tween

##Cancel the Tween. See also [method startTween].
static func cancelTween(tag: String):
	if not tag in tweensCreated:
		return
	tweensCreated[tag].kill()
	tweensCreated.erase(tag)

##Detect if the a Tween is running by its tag.
static func isTweenRunning(tag: String) -> bool:
	return tag in tweensCreated

##Creates a TweenZoom for cameras.
static func doTweenZoom(tag: String,object: Variant, toZoom, time = 1.0, tweenEase: String = 'linear') -> Tween:
	return startTween(tag,object,{'zoom': float(toZoom)},float(time),tweenEase)

##Create a Tween changing the x value, can be usefull not just for positions, but for anothers variables too, the same for the different tweens.
##Example: [codeblock]
##doTweenX('tween','boyfriend',2) #Make a tween of the boyfriend position.
##doTweenX('tween','boyfriend.offset',2) #Make a tween of the boyfriend offset.
##[/codeblock]
##See also [method doTweenY] and [method doTweenAngle].
static func doTweenX(tag: String,object: Variant, to: Variant, time: float = 1.0, tweenEase: String = 'linear') -> Tween:
	return startTween(tag,object,{'x': float(to)},float(time),tweenEase)

##Creates a Tween for the y value. See also [method doTweenX] and [method doTweenAngle].
static func doTweenY(tag: String,object: Variant, to: Variant, time = 1.0, tweenEase: String = 'linear') -> Tween:
	return startTween(tag,object,{'y': float(to)},float(time),tweenEase)

##Creates a Tween for the alpha of a [Node]. See also [method doTweenColor].
static func doTweenAlpha(tag: String, object: Variant, to: Variant, time = 1.0, tweenEase: String = 'linear') -> Tween:
	return startTween(tag,object,{'alpha': float(to)},float(time),tweenEase)
	
##Creates a Tween for the color of a [Node]. See also [method doTweenAlpha].
static func doTweenColor(tag: String, object: Variant,color: Variant, time = 1.0, tweenEase: String = 'linear') -> Tween:
	object = _find_object(object)
	color = _get_color(color)
	if object:
		color.a = object.modulate.a
		return startTween(tag,object,{'modulate': color},float(time),tweenEase)
	return null

##Creates a Tween for the rotation of a [Node]. See also [method doTweenX] and [method doTweenY].
static func doTweenAngle(tag: String, object: Variant, to, time = 1.0, tweenEase: String = 'linear') -> Tween:
	return startTween(tag,object,{'angle': float(to)},time,tweenEase)
#endregion


#region Note Tween Methods
##Creates a Tween for the rotation of a Note. See also [method noteTweenY] and [method noteTweenAngle].
static func noteTweenX(tag: String,noteID: Variant = 0,target = 0.0,time = 1.0,tweenEase: String = 'linear') -> Tween:
	return startTween(
		tag,
		_find_group_members('strumLineNotes',int(noteID)),
		{'x': float(target)},
		float(time),
		tweenEase
	)

##Creates a Tween for the rotation of a Note. See also [method noteTweenX] and [method noteTweenAngle].
static func noteTweenY(tag: String,noteID,target = 0.0,time = 1.0,tweenEase: String = 'linear') -> Tween:
	return startTween(
		tag,
		_find_group_members('strumLineNotes',int(noteID)),
		{'y': float(target)},
		float(time),
		tweenEase
	)

##Creates a Tween for the rotation of a Note. See also [method noteTweenColor].
static func noteTweenAlpha(tag: String,noteID,target = 0.0,time = 1.0,tweenEase: String = 'linear') -> Tween:
	return startTween(
		tag,
		_find_group_members('strumLineNotes',int(noteID)),
		{'alpha': float(target)},
		float(time),
		tweenEase
	)

##Creates a Tween for the rotation of a Note. See also [method noteTweenY] and [method noteTweenAngle].
static func noteTweenAngle(tag: String,noteID,target = 0.0,time = 1.0,tweenEase: String = 'linear') -> Tween:
	return startTween(
		tag,
		_find_group_members('strumLineNotes',int(noteID)),
		{'angle': float(target)},
		float(time),
		tweenEase
	)

##Creates a Tween for the rotation of a Note. See also [method noteTweenY] and [method noteTweenAngle].
static func noteTweenDirection(tag: String,noteID,target = 0.0,time = 1.0,tweenEase: String = 'linear') -> Tween:
	return startTween(
		tag,
		_find_group_members('strumLineNotes',int(noteID)),
		{'direction': float(target)},
		float(time),
		tweenEase
	)

##Creates a Tween for the color of a Note. See also [method noteTweenAlpha].
static func noteTweenColor(tag: String,noteID,target = 0.0,time = 1.0,tweenEase: String = 'linear') -> Tween:
	return startTween(
		tag,
		_find_group_members('strumLineNotes',int(noteID)),
		{'modulate': float(target)},
		float(time),
		tweenEase
		)
#endregion

#region Note Methods
##Returns a new Strum Note. If you want to add the Strum to a group, see also [method addSpriteToGroup].
static func createStrumNote(image_path: String, note_data: int = 0, tag: String = ''):
	var strum: StrumNote = StrumNote.new(note_data)
	
	strum.texture = image_path
	
	if tag:
		if spritesCreated.get(tag):
			spritesCreated[tag].queue_free()
		spritesCreated[tag] = strum
	return strum
#endregion

#region Shader Methods
##Create Shader using tags, making it possible to create several shaders from the same material;[br][br]
##Example: [codeblock]
##initShader('shader1','Chrom');
##initShader('shader2','Chrom');
##setShaderFloat('shader2','strength',1.0);
##[/codeblock][br]
##[b]OBS:[/b] if [code]obrigatory[/code], the shader will be started 
##even if [code]shadersEnabled[/code] is false.
static func initShader(shader: String, tag: String = '', obrigatory: bool = false) -> ShaderMaterial:
	if !obrigatory and !shadersEnabled: return
	if !tag: tag = shader
	if tag in shadersCreated and shadersCreated[tag].shader.resource_name == shader:
		return shadersCreated[tag]
	
	var shader_material: ShaderMaterial = Paths.loadShader(shader)
	if !shader_material: return
	shader_material.resource_name = tag
	shader_material = shader_material.duplicate()
	shadersCreated[tag] = shader_material
	callOnScripts('onLoadShader',[shader,shader_material,tag])
	
	shadersCameras[tag] = Array([],TYPE_OBJECT,'CanvasItem',null)
	return shader_material
	
##Add [Material] to a [code]camera[/code], [code]shader[/code] can be a [String] or a [Array].[br][br]
##[b]OBS:[/b] If the [code]shader[/code] was not started using [method initShader], this function will call automatically.
##[br][br]Example of code:[codeblock]
##var shader_material1 = ShaderMaterial.new()
##var shader_material2 = ShaderMaterial.new()
##addShaderCamera('game',shader_material1)
##addShaderCamera('game',shader_material2)
###or
##addShaderCamera('game',[shader_material1,shader_material2])
###or
##addShaderCamera('game',['ChromaticAberration',shader_material2])
##[/codeblock][br]
##If you want to add the same shader in more cams:
##[codeblock]
##addShaderCamera(['game','hud'],shader_material2)
##[/codeblock]
##[b]Note:[/b] The same works for [method removeShaderCamera].
##[br][br]See also [method setSpriteShader].
static func addShaderCamera(camera: Variant, shader: Variant) -> void:
	var cameras = camera if camera is Array else [camera]
	
	#Detect Shaders
	var shaders_array: Array[Material]
	if shader is String or shader is Material: shader = [shader]
	
	##Add Shaders to array
	for i in shader:
		if i is String: i = _find_shader_material(i)
		if i: shaders_array.append(i)
	
	#Set Shaders to Cameras
	for cam in cameras:
		cam = getCamera(cam)
		if !cam: return
		cam.addFilters(shaders_array)
	
##Remove shader from the camera, [code]shader[/code] can be a [String] or a [Array].
##[br]See also [method addShaderCamera].
static func removeShaderCamera(camera: Variant, shader: Variant) -> void:
	var cam = getCamera(camera)
	if !cam: return
	shader = _find_shader_material(shader)
	
	if !shader:return
	cam.removeFilter(shader)

##Set the sprite's shader, [code]shader[/code] can be a [ShaderMaterial] or a [String].
##[br][br]See also [method addShaderCamera].
static func setSpriteShader(object: Variant, shader: Variant) -> void:
	object = _find_object(object)
	if !object: return
	object.set('material',_find_shader_material(shader))

##Remove the current shader from the object
static func removeSpriteShader(object: Variant) -> void:
	object = _find_object(object)
	if !object: return
	object.set('material',null)

static func setShaderParameter(shader: Variant, parameter: String, value: Variant):
	var material = _find_shader_material(shader)
	if material:
		material.set_shader_parameter(parameter,value)
		
static func setShaderFloat(shader: Variant, parameter: String, value: float):
	var material = _find_shader_material(shader)
	if material: material.set_shader_parameter(parameter,value)

static func setShaderBool(shader: Variant, parameter: String, value: bool):
	var material = _find_shader_material(shader)
	if material: material.set_shader_parameter(parameter,value)

#region Shader Values Methods
##Add [code]value[/code] to a [u][float] parameter[/u] of a [code]shader[/code] created using [method initShader].
static func addShaderFloat(shader: Variant, parameter: String, value: float):
	var material = _find_shader_material(shader)
	if !material: return
	var vars = material.get_shader_parameter(parameter)
	if vars != null:
		material.set_shader_parameter(parameter,vars+value)

static func getShaderFloat(shader: String, shaderVar: String) -> float:
	var value = getShaderParameter(shader,shaderVar)
	if !value: return 0
	return float(value)

static func getShaderBool(shader: String, shaderVar: String) -> bool:
	return !!getShaderParameter(shader,shaderVar)

static func getShaderParameter(shader: String, shaderVar: String) -> Variant:
	var material = _find_shader_material(shader)
	return material.get_shader_parameter(shaderVar) if material else null
#endregion

##Sets Object Blend mode, can be: [code]add,subtract,mix[/code]
static func setBlendMode(object: Variant, blend: String) -> void:
	object = _find_object(object)
	if not object is CanvasItem: return
	
	if object is Sprite: object.blend = blend; return
	
	var material = ShaderHelper.get_blend(blend)
	if material: object.material = material

static func _find_shader_material(shader: Variant) -> ShaderMaterial:
	if !shader: return null
	if shader is ShaderMaterial: return shader
	if shadersCreated.has(shader): return shadersCreated[shader]
	var obj = _find_object(shader)
	if obj and obj.get('material'): return obj.material
	return initShader(shader)
#endregion


#region Camera Methods
static func createCamera(tag: String, order: int = 5) -> CameraCanvas:
	if tag in modVars: return modVars[tag]
	var cam = CameraCanvas.new()
	cam.name = tag
	modVars[tag] = cam
	game.add_child(cam)
	game.move_child(cam,order)
	return cam

##Do Camera Flash
static func cameraFlash(cam: String, flashColor: Variant = Color.WHITE, time = 1.0, force: bool = false) -> void:
	var obj = getCamera(cam)
	if obj is CameraCanvas:
		obj.flash(flashColor if flashColor is Color else getColorFromHex(flashColor),float(time),force)

##Make a camera shake.
static func cameraShake(cam: String, intensity: float = 0.0, time: float = 1.0) -> void:
	var obj = getCamera(cam)
	if obj is CameraCanvas: obj.shake(float(intensity),float(time))

##Make a fade in, or out, in the camera.
static func cameraFade(cam_name: String, color = '000000', time: Variant = 1.0, force: bool = false, fadeIn: bool = true):
	var cam = getCamera(cam_name)
	if cam is CameraCanvas: cam.fade(color,float(time),force,fadeIn)

##Move the game camera for the [code]target[/code].
static func cameraSetTarget(target: String = 'boyfriend') -> void: game.moveCamera(target)
	
##Set the object camera.
static func setObjectCamera(object: Variant, camera: Variant = 'game'):
	object = _find_object(object)
	if !object: return
	var cam: Node = getCamera(camera)
	if !cam: return
	if object is Sprite: object.set('camera',cam)
	else: cam.add(object)

static func getCenterBetween(object1: Variant, object2: Variant) -> Vector2:
	object1 = _find_object(object1)
	object2 = _find_object(object2)
	
	if !object1 or !object2: return Vector2(-1,-1)
	
	var pos_1 = object1._position if object1 is Sprite else object1.position
	var pos_2 = object2._position if object2 is Sprite else object2.position
	
	return pos_1 - (pos_2 - pos_1)/2.0


##Detect the camera name using a String.
static func cameraAsString(string: String) -> String:
	match string.to_lower():
		'hud', 'camhud':return 'camHUD'
		'other', 'camother':return 'camOther'
		'game','camgame':return 'camGame'
		_:return string

static func getCharacterCamPos(char: Variant) -> Vector2: ##Returns the camera position from [param char].
	if char is String: char = getProperty(char)
	if game: return game.getCameraPos(char)
	if char is Character: return char.getCameraPosition()
	if char is Sprite: return char.getMidpoint()
	
	return char.position


##Returns a [CameraCanvas] created using [method createCamera] or the game's camera named with [param camera]
static func getCamera(camera: Variant) -> CameraCanvas:
	if camera is Node:return camera
	return getProperty(cameraAsString(camera))
#endregion


#region Game Methods
##Starts the song count down.
static func startCountdown() -> void: game.startCountdown()

##Ends the game song.
static func endSong(skip_transition: bool = false): game.endSound()

##Sets the player health.
static func setHealth(value: float) -> void: game.health = value

##Returns the player health.
static func getHealth() -> float: return game.health

static func setHealthBarColors(left: Variant, right: Variant):
	if !game: return
	var healthBar: Bar = game.get('healthBar')
	if !healthBar: return
	healthBar.set_colors(_get_color(left),_get_color(right))
##Starts a video.
static func startVideo(path: Variant, isCutscene: bool = true) -> VideoStreamPlayer:
	return game.startVideo(path, isCutscene)
#endregion


#region Song Methods

static func is_audio(value: Object): return value and value.get_class().begins_with('AudioStreamPlayer')

##Skip the song to [code]time[/code].[br]
##If [code]kill_notes[/code], the notes before that time will be destroyed, avoiding missing them and ending up dying.
static func setSongPosition(time: Variant, kill_notes: bool = false): game.seek_to(float(time),kill_notes)
	
 ##Get Song Position.
static func getSongPosition() -> float: return Conductor.songPositionDelayed

static func getSoundTime(sound: Variant) -> float:##Get the Sound Time.
	if sound is String and sound in soundsPlaying: sound = soundsPlaying[sound]
	
	if !is_audio(sound): return 0.0
	return sound.get_playback_position()

static func setSoundVolume(sound: Variant, volume: float = 1) -> void:
	if sound is String: sound = getProperty(sound)
	if !is_audio(sound): return
	sound.volume_db = -80 + (80*volume)

##Returns the current character section name of the song.
static func detectSection() -> String:  return game.detectSection()

##Play a sound. [code]path[/code] can be a [String] or a [AudionStreamOggVorbis].
##[br]Example of code: [codeblock]
##playSound('noise',1.0,'noise_sound')
##
##var audio = Paths.sound('noise2')
##playSound(audio,1.0,'noise_sound2')
##[/codeblock]
static func playSound(path, volume: float = 1.0, tag: String = "",force: bool = false, loop: bool = false) -> AudioStreamPlayer:
	if !path:
		return null
	var audio: AudioStreamPlayer
	
	if soundsPlaying.get(tag):
		audio = soundsPlaying[tag]
		if audio.playing and !force: return audio
	else:
		audio = _get_sound(path)
		if tag:
			audio.name = tag
			soundsPlaying[tag] = audio
			audio.finished.connect(cancelSound.bind(tag))
		(game if game else Global).add_child(audio)
	
	if audio.stream: audio.stream.loop = loop
	
	audio.play(0)
	return audio

static func cancelSound(tag: StringName):
	if !soundsPlaying.has(tag): return
	soundsPlaying[tag].stop()
	soundsPlaying.erase(tag)
#endregion

static func _get_sound(path):
	var audio = AudioStreamPlayer.new()
	audio.stream = path if path is AudioStreamOggVorbis else Paths.sound(path)
	if not audio.stream: return audio
	audio.finished.connect(audio.queue_free)
	return audio

#region Keyboard Methods
##Detect if the keycode is just pressed. See also [method keyboardJustReleased].
static func keyboardJustPressed(key: String) -> bool:  
	return InputHelper.isKeyJustPressed(OS.find_keycode_from_string(key))

##Detect if the keycode is just pressed. See also [method keyboardJustPressed].
static func keyboardJustReleased(key: String) -> bool:
	return InputHelper.isKeyJustReleased(OS.find_keycode_from_string(key))

##Detect if the keycode is pressed, similar to [method Input.is_key_label_pressed].
##[br]See also [method keyboardJustPressed].
static func keyboardPressed(key: String) -> bool:
	return InputHelper.isKeyPressed(OS.find_keycode_from_string(key))

static func addKey(key: String, action: String):
	pass
#endregion


#region Script Methods
##Detect if a script[u],created using [method addScript],[/u] is running.
static func scriptIsRunning(path: String) -> bool:
	return scriptsCreated.has(path if path.ends_with('.gd') else path+'.gd')


static func callMethod(object: Variant, function: String, variables: Array = []) -> Variant:
	object = _find_object(object)
	if !(object and object.has_method(function)): return
	return object.callv(function,variables)


static func insertScript(script: Object) -> void:
	var script_id = script.get_instance_id()
	scriptsCreated[script.scriptPath if script is FunkinGD else script_id] = script
	var script_args = get_arguments(script)
	arguments[script_id] = script_args
	
	for func_name in script_args:
		if !method_list.has(func_name): method_list[func_name] = []
		method_list[func_name].append(script)
	
	if script_args.has('onCreate'): script.onCreate()
	
	if game and game.stateLoaded and script_args.has('onCreatePost'): script.onCreatePost()
	init_gd()


##Get a script created from the [method addScript].
static func getScript(path: String) -> Object:
	if !path: return
	if not path.ends_with('.gd'): path += '.gd'
	var script = scriptsCreated.get(path)
	return script if script else _load_script(path)

static func _load_script(path: String) -> Object:
	var absolutePath: String = Paths.detectFileFolder(path)
	
	if not absolutePath: return;
	var GScript: GDScript = GDScript.new()
	
	GScript.source_code = FileAccess.get_file_as_string(absolutePath)
	GScript.reload()
	
	return GScript
##Returning a new [Object] with the script created, useful if you want to call a function without using [method callScript] or want to change a variable of the script.
##Example of code:[codeblock]
##var script = addScript('ghosting_trail')
##script.time = 0.5
##script.createTrail()
##[/codeblock]
static func addScript(path: String) -> Object:
	path = Paths.getPath(path,false)
	if !path.ends_with('.gd'): path += '.gd'
	
	if scriptsCreated.has(path): return scriptsCreated[path]
	
	var script = _load_script(path)
	if !script: return
	
	var resource = script.new()
	resource.set('scriptPath',path)
	resource.set('scriptMod',Paths.getModFolder(path))
	insertScript(resource)
	return resource

##Remove the script using its path.
static func removeScript(path: String):
	if !path: return
	path = Paths.getPath(path,false)
	
	var script = scriptsCreated.get(path if path.ends_with('.gd') else path+'.gd')
	if !script: return
	
	callOnScripts('onScriptRemoved',[script])
	for i in arguments[script.get_instance_id()]: method_list[i].erase(script)
	scriptsCreated.erase(path)

##Calls a function in the script, returning a [Variant] that the function returns.
static func callScript(script: Variant,function: String = '', parameters: Array = []) -> Variant:
	if script is String:
		if !script.ends_with('.gd'): script += '.gd'
		if !scriptsCreated.has(script): return
		script = scriptsCreated[script]
		return callScriptNoCheck(script,function,parameters)
	if !script: return
	return callScriptNoCheck(script,function,parameters)

##Calls a function for every script created, 
##returns a [Array] with the values returned from then if [code]return_values[/code] is true.
static func callOnScripts(function: String, parameters: Array = [], return_values: bool = false) -> Variant:
	if !method_list.get(function): 
		if return_values: return []
		return null
	
	if !return_values:
		for i in method_list[function]: callScriptNoCheck(i,function,parameters)
		return
	
	var returns: Array = []
	for i in method_list[function]: returns.append(callScriptNoCheck(i,function,parameters))
	return returns

static func callScriptNoCheck(script: Object, function: String, parameters: Array = []):
	var script_id = script.get_instance_id()
	if not arguments.has(script_id) or not arguments[script_id].has(function): return
	var args = arguments[script_id][function]
	if !args: return script.call(function)
	
	var param_size = parameters.size()
	var index: int = -1
	
	var new_parameters: Array[Variant] = []
	for i in args:
		index +=1
		if index >= param_size: new_parameters.append(i.default); continue
		var variable = parameters[index]
		
		if i.type != TYPE_NIL and typeof(variable) != i.type: new_parameters.append(type_convert(variable,i.type))
		else: new_parameters.append(variable)
	
	return script.callv(function,new_parameters)
	
static func _detect_class(tag: StringName):
	for folder in ['backend','gdscript','global','objects','states','substates']:
		if FileAccess.file_exists('res://source/'+folder+'/'+tag+'.gd'): return 'res://source/'+folder+'/'+tag+'.gd'
			
	return ''


##Get a Class, this can catch every class used in the game, check the file paths here: 
##[url]https://github.com/zlMyt/FNFGodot[/url]
##[br]Example of code:[codeblock]
##const note_class = getClass('objects/Note')
##var Note = note_class.new()
##
##var trail = getClass('effects/Trail')
##[/codeblock]
static func getClass(class_path: String) -> Variant:
	if class_path.ends_with('.tscn'):
		var classInstance: Resource = load(class_path)
		return (classInstance.instantiate() if classInstance else null)

	if !class_path.ends_with('.gd'): class_path += '.gd'
	
	var search: Array[StringName] = [
		'',
		'res://',
		'res://source/',
		'res://source/general/',
		'res://source/objects/',
		Paths.exePath+'/assets/'
	]
	
	
	var path: String = ''
	for dir in search:
		var file = dir+class_path
		if FileAccess.file_exists(file):
			path = file
			break
	return load(path) if path else null


func close() -> void: ##Remove script.
	removeScript(scriptPath)
#endregion


#region Event Methods
##Trigger Event, if [code]value2[/code] is setted, [variables] will be considered as a value1;[br]
##Example: [codeblock]
###Similar to the old versions of Psych Engine, more limited.
##triggerEvent('eventName','value1','value2')
##
###Can set multiply variables, useful for complex events
##triggerEvent('eventName',{'x': 0.0,'y': 0.0,'angle': 0.0})
##[/codeblock]
static func triggerEvent(event: String,variables: Variant = '', value2: Variant = ''):
	addScript('custom_events/'+event+'.gd') #Add script event if not added
	if !variables is String: game.triggerEvent(event,variables)
	
	var default: Dictionary = EventNote.get_event_variables(event)
	var event_keys = default.keys()
	var parameters: Dictionary = {}
	
	for i in default: parameters[i] = default[i].default_value
	
	if variables:
		var first_key = event_keys[0]
		parameters[first_key] = EventNote.convert_event_type(
				variables,
				default[first_key].type
			)
	
	if value2 and event_keys.size() > 1:
		parameters[event_keys[1]] = EventNote.convert_event_type(
			value2,
			default[event_keys[1]].type
		)
	
	game.triggerEvent(event,parameters)
#endregion

#region Color Methods
static func _get_color(color: Variant):
	if color is String: return getColorFromHex(color)
	return color
##Return [Color] using Hex
static func getColorFromHex(color: String, default: Color = Color.WHITE) -> Color:
	if !color: return Color.WHITE
	if color.begins_with('0x'): color = color.right(-4)
	while color.length() < 6: color += '0'
	
	return Color.html(color.to_lower())

##Returns a [Color] using a [Array][[color=red]r[/color], [color=green]g[/color], [color=blue]b[/color]]:
##Example:[codeblock]
##getColorFromArray([255,255,255],true)# Returns Color.WHITE (Color(1,1,1))
##getColorFromArray([1,1,1],false) #Also returns Color.WHITE (Color(1,1,1))
##getColorFromArray([255,0,0])# Returns Color(1,0,0)
##[/codeblock]
static func getColorFromArray(array: Array, divided_by_255: bool = true) -> Color:
	if divided_by_255: return Color(array[0]/255.0,array[1]/255.0,array[2]/255.0)
	return Color(array[0],array[1],array[2])

##Returns a [Color] using his name:
##Example:[codeblock]
##getColorFromName('red')# Returns Color.RED (Color(1,0,0))
##getColorFromName('white') #Returns Color.WHITE (Color(1,1,1))
##getColorFromName('BLACK') #Returns Color.BLACK (Color(0,0,0))
##getColorFromName('invalid color') #Returns Color.WHITE(default)
##getColorFromName([255,0,0])# Returns Color(1,0,0)
##[/codeblock]
static func getColorFromName(color_name: String, default: Color = Color.WHITE) -> Color:
	return Color.from_string(color_name.to_lower(),default)
#endregion
	
#region Unnecessary Methods(created to be similar with Psych Engine scripts)
##Similar to [method String.begins_with]
static func stringStartsWith(string: String, text: String): return string.begins_with(text)

##Similar to [method String.ends_with]
static func stringEndsWith(string: String, text: String):return string.ends_with(text)
#endregion
