class_name Paths extends Object
const game_name = "Friday Night Funkin'"
const AnimationService = preload("res://source/general/animation/AnimationService.gd")
const Character = preload("res://source/objects/Sprite/Character.gd")
static var is_on_mobile: bool = false


static var curDevice: String = OS.get_name()
static var is_system_case_sensitive: bool = curDevice in ['macOS','Linux',"FreeBSD", "NetBSD", "OpenBSD", "BSD"]

static var exePath: StringName = get_exe_path()
static var savePath: StringName = 'res:/'
static var enableMods: bool = true:
	set(value):
		enableMods = value
		updateDirectories()

static var modsFounded: Dictionary[String,Dictionary] = {}
static var modsEnabled: PackedStringArray = []
static var textFiles: Dictionary = {}

static var replace_paths: Array = [exePath,'assets/mods','assets/','mods/']
static var curMod: String = '': 
	set(mod):
		if mod == curMod: return
		curMod = mod
		updateDirectories() 

const commomFolders: PackedStringArray = [
	"characters",
	"custom_events",
	"custom_notetypes",
	"data",
	"fonts",
	"images",
	"scripts",
	"shaders",
	"shared",
	"songs",
	"sounds",
	"stages",
	"weeks"
]

static var mods_enabled: Dictionary = ClientPrefs.data.modsEnabled
static var extraDirectory: String: 
	set(dir):
		if extraDirectory == dir: return
		extraDirectory = dir
		updateDirectories()

const icons_dictionaries: PackedStringArray = ['icons/','icons/icon-','winning_icons/','winning_icons/icon-']
const data_dictionaries: PackedStringArray = ['data/','data/songs/']

static var _files_directories_cache: Dictionary[String,String] = {}
static var _dir_exists_cache: Dictionary[String,DirAccess] = {}

static var imagesCreated: Dictionary[String,Image] = {}
static var imagesTextures: Dictionary[String,ImageTexture] = {}

static var songsCreated: Dictionary[String,AudioStream] = {}
static var soundsCreated: Dictionary[String,AudioStream] = {}

static var musicCreated: Dictionary[String,AudioStream] = {}
static var fontsCreated: Dictionary[String,FontFile] = {}
static var shadersCreated: Dictionary[String,Material] = {}
static var shadersCodes: Dictionary[String,Shader] = {}

static var jsonsLoaded: Dictionary[String,Dictionary] = {}

static var modelsCreated: Dictionary[String,Object] = {}
const model_formats: PackedStringArray = ['.tres','.glb']

static var videosCreated: Dictionary[String,VideoStream] = {}

static var dirsToSearch: PackedStringArray = []
static var searchAllMods: bool = false: 
	set(value): searchAllMods = value; updateDirectories()


static func get_exe_path() -> String:
	match curDevice:
		"Android": return '/storage/emulated/0/.FunkinGD'
		_: return OS.get_executable_path().get_base_dir()
		
static func _init() -> void:
	is_on_mobile = curDevice == 'Android' or curDevice == 'iOs'
	if is_on_mobile: OS.request_permissions()
	replace_paths[0] = exePath+'/'
	replace_paths.make_read_only()
	
	detectMods()
	modsEnabled = getRunningMods()
	updateDirectories()

static func updateDirectories():
	_files_directories_cache.clear()
	_dir_exists_cache.clear()
	dirsToSearch.clear()
	
	var new_dirs: PackedStringArray
	if enableMods:
		for i in (modsFounded if searchAllMods else getRunningMods()): new_dirs.append(exePath+'/mods/'+i+'/')
		new_dirs.append(exePath+'/mods/')
	
	new_dirs.append(exePath+'/assets/')
	new_dirs.append('res://assets/')
	
	for i in new_dirs: 
		if extraDirectory: dirsToSearch.append(i+extraDirectory+'/')
		dirsToSearch.append(i)
	
static func detectMods() -> void:
	modsFounded.clear()
	for mods in DirAccess.get_directories_at(exePath+'/mods'):
		if commomFolders.has(mods): continue
		
		var modpack = {
			"runsGlobally": false,
			"name": mods,
			"restart": false,
			"description": "nothing"
		}
		#Check if the mod have "pack.json" data
		var _real_path = exePath+'/mods/'+mods+'/pack.json'
		if file_exists(_real_path):
			modpack.merge(JSON.parse_string(FileAccess.get_file_as_string(_real_path)),true)
		
		if !modpack.get('name') or modpack.name.to_lower() == 'name': modpack.name = mods
		
		if !mods_enabled.has(mods): mods_enabled[mods] = true
		
		modsFounded[mods] = modpack

static func detectFileFolder(path: String, case_sensive: bool = false) -> String:
	var path_cache = _files_directories_cache.get(path)
	if path_cache: return path_cache
	
	if case_sensive:
		var file = path.get_file()
		var folder = path.get_base_dir()
		for d in dirsToSearch:
			var dir_path = d+folder
			var dir: DirAccess = get_dir(dir_path)
			if !dir: continue
			for i in dir.get_files():
				if not i == file: continue
				var full_path: String = dir_path+'/'+file
				_files_directories_cache[path] = full_path
				return full_path
		return ''
	
	if FileAccess.file_exists(path): 
		_files_directories_cache[path] = path
		return path
	for d in dirsToSearch:
		var curPath: String = d+path
		if FileAccess.file_exists(curPath):
			_files_directories_cache[path] = curPath
			return curPath
	return ''

static func image(path: String,imagesDirectory: bool = true) -> Image:
	path = imagePath(path,imagesDirectory)
	if imagesCreated.has(path): return imagesCreated[path]
	
	if !path: return null
	
	var imageFile: Image = Image.load_from_file(path)
	imageFile.resource_name = path.left(-4)
	imagesCreated[path] = imageFile
	
	return imageFile

static func imageTexture(path: String, imagesDirectory: bool = true) -> ImageTexture:
	if imagesTextures.has(path): return imagesTextures[path]
	
	var image = image(path,imagesDirectory)
	if !image: return null
	
	var texture = ImageTexture.create_from_image(image)
	texture.resource_name = image.resource_name
	imagesTextures[path] = texture
	return texture


#region Path Methods
static func imagePath(path: String, imagesDirectory: bool = true) -> String:
	path = getPath(path,false)
	
	if !path.ends_with('.png'): path += '.png'
	if imagesDirectory and not path.begins_with('images/'): path = 'images/'+path
	return detectFileFolder(path)

static func text(path: String):
	if not path.ends_with('.txt'): path += '.txt'
	path = getPath(path,false)
	if textFiles.has(path): return textFiles[path]
	
	var textFile = detectFileFolder(path)
	if !textFile: return ''
	var file = FileAccess.get_file_as_string(textFile)
	textFiles[path] = file
	return file

static func font(path: String) -> String:
	var fontPath = detectFileFolder('fonts/'+path)
	if !fontPath:
		fontPath = 'res://assets/fonts/'+path
		if not FileAccess.file_exists(fontPath): return ''
			
	return detectFileFolder('fonts/'+path)

const shader_formats: PackedStringArray = ['.frag','.gdshader']
static func shaderPath(path: String) -> String:
	if FileAccess.file_exists(path): return path
	if !path.begins_with('shaders/'): path = 'shaders/'+path
	
	for i in shader_formats:
		var path_to_share = path
		if !path.ends_with(i): path_to_share += i
		
		var shader_path = detectFileFolder(path_to_share)
		if shader_path: return shader_path
	return ''
	
	
static func stage(path: String)-> String: return detectFileFolder('stages/'+path+'.json')

static func event(path: String) -> String: return detectFileFolder('custom_events/'+path+'.gd')

static func characterPath(path: String) -> String:
	if !path.ends_with('.json'): path += '.json'
	return detectFileFolder('characters/'+path)

static func character(path: String) -> Dictionary:
	var file = characterPath(path)
	if !file: return {}
	
	var json = loadJson(file)
	var needs_to_convert = json.has('image')
	if needs_to_convert: json.merge(Character._convert_psych_to_original(json),true)
	else: json.merge(Character.getCharacterBaseData(),false)
	return json
	
##Get the [param video] path
static func video(path: String) -> VideoStreamTheora:
	if !path.ends_with('.ogv'): path += '.ogv'
	
	if path in videosCreated: return videosCreated[path]
	
	var videoPath = detectFileFolder('videos/'+path)
	if !videoPath: return null
	
	var video = load(videoPath)
	videosCreated[path] = video
	return video

static func song(path: String) -> AudioStreamOggVorbis:
	if songsCreated.has(path): return songsCreated[path].duplicate()
	
	var songPath = songPath(path)
	if !songPath: return null
	return audio(songPath)

static func songPath(path):
	path = getPath(path)
	if !path.begins_with('songs/'): path = 'songs/'+path
	
	if !path.get_extension(): path += '.ogg'
	
	var paths: PackedStringArray = [path,path.to_lower()]
	
	for i in paths:
		var songPath = detectFileFolder(i)
		if songPath: return songPath
		
		songPath = detectFileFolder(i.replace(' ','-'))
		if songPath: return songPath
	return ''
static func audio(path):
	if songsCreated.has(path): return songsCreated[path].duplicate()
	var stream_path = detectFileFolder(path)
	if !stream_path: return null
	
	var audio
	match stream_path.get_extension():
		'ogg': audio = AudioStreamOggVorbis.load_from_file(stream_path)
		'mp3': audio = AudioStreamMP3.load_from_file(stream_path)
		'wav': audio = AudioStreamWAV.load_from_file(stream_path)
		_: return null
	
	songsCreated[path] = audio
	return audio.duplicate()


static func sound(path: String) -> AudioStreamOggVorbis:
	if !path.ends_with('.gg'): path += '.ogg'
	if songsCreated.has(path): return soundsCreated[path].duplicate()
	
	var songPath = detectFileFolder('sounds/'+path)
	if !songPath: return null
	var audio = AudioStreamOggVorbis.load_from_file(songPath)
	if !audio: return
	audio.resource_name = path
	soundsCreated[path] = audio
	return audio.duplicate()

static func music(path: String) -> AudioStreamOggVorbis:
	if not path in musicCreated:
		var musicPath: String = detectFileFolder('music/'+path+'.ogg')
		if not musicPath: return null
		musicCreated[path] = AudioStreamOggVorbis.load_from_file(musicPath)
	return musicCreated[path]

static func data(json: String = '',preffix: String = '',folder: String = '') -> String:
	if file_exists(json): return json
	if json.ends_with(".json"): json = json.left(-5)
	
	if !folder: folder = json
	else: 
		folder = getPath(folder,false)
		if folder.begins_with('data/'): folder = folder.right(-5)
	
	var json_path = folder+'/'+json
	var paths_to_lock: PackedStringArray = []
	
	if preffix:
		if preffix.to_lower() == 'normal':  paths_to_lock.append(json_path+'.json')
		
		paths_to_lock.append_array([
			json_path+'-'+preffix+'.json',
			json_path+'-chart-'+preffix+'.json'
		])
	
	else: paths_to_lock.append(json_path+'.json')
	
	paths_to_lock.append(json_path+'-chart.json')
	
	var contain_space = json_path.contains(' ')
	var path_found: String = ''
	
	for i in paths_to_lock:
		for d in data_dictionaries:
			path_found = detectFileFolder(d+i,!is_system_case_sensitive)
			if path_found: return path_found
			
		if contain_space:
			i = i.replace(' ','-')
			for d in data_dictionaries:
				path_found = detectFileFolder(d+i,!is_system_case_sensitive)
				if path_found: return path_found
		
		i = i.to_lower()
		for d in data_dictionaries:
			path_found = detectFileFolder(d+i)
			if path_found: return path_found
	return ''

static func icon(path: String) -> String:
	for iconPath in icons_dictionaries:
		var icon = imagePath(iconPath+path)
		if icon:
			return icon
	return ''

static func model(path: String) -> Node3D:
	if path in modelsCreated:
		return modelsCreated[path]
	
	for formats in model_formats:
		var modelPath = detectFileFolder(path+formats)
		if modelPath:
			var model = load(modelPath)
			if formats == '.tres': pass
			modelsCreated[path] = model
			return model
	modelsCreated[path] = null
	return null

static func getPath(path: String, withMod: bool = true) -> String:
	if !path: return path
	for paths in replace_paths:
		if path.begins_with(paths): path = path.right(-paths.length())
	
	if !withMod:
		var find = path.find('/')
		var path_mod = path.left(find)
		if path_mod in modsFounded: path = path.right(-find-1)
	
	path = path.strip_edges()
	return path


##Returns the mod folder in [param path]. [br]
##[b]Note:[/b] If don't found, will return [param default].
static func getModFolder(path: String, default: String = game_name) -> String:
	path = getPath(path)
	if path.begins_with('mods/'): path = path.right(-5)
	elif path.begins_with('assets/'): path = path.left(-7)
	
	var bar_find = path.find('/')
	if bar_find != -1: path = path.left(bar_find)
	
	if !path or path in commomFolders: return default
	return path

#endregion


#region File metods
static func get_dialog(dir: String = '') -> FileDialog:
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	if not dir.ends_with('/'): dir = dir+'/'
	
	dialog.current_path = (dir if dir_exists(dir) else exePath+'/')
	dialog.size = ScreenUtils.screenSize/1.5
	dialog.visible = true
	dialog.visibility_changed.connect(func():
		if !dialog.visible: dialog.queue_free()
	)
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	
	return dialog


##Save a File. If [param external] is [code]true[/code], the file will be saved in the game's folder.
static func saveFile(json: Variant, path: String, extension: String = '.json') -> void:
	if json is Dictionary: json = JSON.stringify(json,'\t')
	else: json = str(json)
	if not path.ends_with(extension): path += extension
	var folder_acess = FileAccess.open(path, FileAccess.WRITE)
	if folder_acess: folder_acess.store_string(json)
	
static func clearFiles() -> void:
	soundsCreated.clear()
	imagesTextures.clear()
	imagesCreated.clear()
	jsonsLoaded.clear()
	clearLocalFiles()
	AnimationService._clearAnims()
	
static func clearLocalFiles() -> void:
	shadersCreated.clear()
	shadersCodes.clear()
	textFiles.clear()
#endregion
static func loadShader(path: String) -> ShaderMaterial:
	var absolute_path = shaderPath(path)
	
	if !absolute_path: return null
	
	var material: ShaderMaterial = shadersCreated.get(absolute_path)
	if material: return material.duplicate()
	
	material = ShaderMaterial.new()
	material.shader = loadShaderCode(absolute_path)
	shadersCreated[absolute_path] = material
	return material

static func loadShaderCode(path: String) -> Shader:
	path = shaderPath(path)
	if !path: return
	
	var shader = shadersCodes.get(path)
	if shader: return shader
	
	shader = Shader.new()
	var shader_code = FileAccess.get_file_as_string(path) 
	shader.resource_name = path.get_file().get_basename()
	shader.code = ShaderHelper.fragToGd(shader_code) if path.ends_with('.frag') else shader_code
	shadersCodes[path] = shader
	return shader
	
static func getFilesAt(folder: String, return_folder: bool = false, filters: Variant = '', with_extension: bool = false) -> PackedStringArray:
	var files: PackedStringArray = PackedStringArray()

	if folder.ends_with('/'): folder = folder.left(-1)
	
	if filters and filters is String:
		if filters.begins_with('.'): filters = PackedStringArray([filters.right(-1)])
		else: filters = PackedStringArray([filters])
	
	for i in dirsToSearch:
		files.append_array(getFilesAtAbsolute(i+folder,return_folder,filters,with_extension))
	
	return files

static func getFilesAtAbsolute(
	folder: String, 
	return_folder: bool = false, 
	filters: Variant = PackedStringArray(), 
	with_extension: bool = false
) -> PackedStringArray:
	if filters and filters is String:
		if filters.begins_with('.'): filters = PackedStringArray([filters.right(-1)])
		else: filters = PackedStringArray([filters])
	if !dir_exists(folder):  return PackedStringArray()
	return _getFilesNoCheck(folder,return_folder,filters,with_extension)

static func _getFilesNoCheck(
	folder: String, 
	return_folder: bool = false, 
	filters: Variant = PackedStringArray(), 
	with_extension: bool = false
) -> PackedStringArray:
	
	if !filters and with_extension: return get_dir(folder).get_files()
	
	var files: Dictionary[String,bool] = {}
	for file in get_dir(folder).get_files():
		if filters:
			var file_extension = file.get_extension()
			if not filters.has(file_extension): continue
			if !with_extension: file = file.left(-file_extension.length()-1)
		
		if return_folder: files[folder+'/'+file] = true; continue
		files[file] = true
	return files.keys()

static func getRunningMods(location: bool = false, folder_name: bool = false) -> PackedStringArray:
	var mods: PackedStringArray = []
	if location: 
		for mod in modsFounded: 
			if isModRunning(mod): mods.append(exePath+'/mods/'+mod+'/')
	else: for mod in modsFounded: if isModRunning(mod): mods.append(mod)
	return mods

static func isModRunning(mod_name: String) -> bool:
	return mod_name == curMod \
			or mods_enabled.get(mod_name,false)\
			and modsFounded[mod_name].runsGlobally

static func isModEnabled(mod_name) -> bool:
	return mod_name == curMod or mods_enabled.get(mod_name,false)
	
static func getModsEnabled(location: bool = false) -> PackedStringArray:
	var mods: PackedStringArray = []
	for mod in modsFounded:
		if isModEnabled(mod):
			mods.append(mod if not location else exePath+'/mods/'+mod+'/')
	return mods

static func folder(path: String) -> String:
	for search in dirsToSearch:
		var dir = search+path
		if dir_exists(dir): return dir
	return ''

static func dir_exists(dir: String): return !!get_dir(dir)

static func get_dir(dir: String):
	var _dir = _dir_exists_cache.get(dir)
	if _dir: return _dir
	if DirAccess.dir_exists_absolute(dir): _dir = DirAccess.open(dir)
	_dir_exists_cache[dir] = _dir
	return _dir
	
static func file_exists(path: String) -> bool: 
	return !!detectFileFolder(path)

##Returns the json file from [param path].[br]
##Obs: If [param duplicate], this will returns a duplicated json, 
##making it possible to modify without damaging the original json
static func loadJson(path: String, duplicate: bool = true) -> Dictionary:
	if not path.ends_with('.json'): path += '.json'
	var json = jsonsLoaded.get(path)
	if json == null: 
		var absolute_path = detectFileFolder(path)
		if not absolute_path: return {}
		json = JSON.parse_string(FileAccess.get_file_as_string(absolute_path))
		if json == null: return {}
		jsonsLoaded[path] = json
	return json.duplicate(true) if duplicate else json
