extends Panel

@onready var modchart_editor := $/root/ModchartEditor
@onready var game := $/root/ModchartEditor/GameView

#region Shader
@onready var shadersOptions := $TabContainer/Shader/Shaders
@onready var shadersPop: PopupMenu = shadersOptions.get_popup()
@onready var shaderTag := $TabContainer/Shader/ShaderTag

@onready var addShaderToGame := $TabContainer/Shader/camGame
@onready var addShaderToHUD := $TabContainer/Shader/camHUD
@onready var addShaderToOther := $TabContainer/Shader/camOther
#endregion

#region Object
@onready var objectTag := $TabContainer/Object/Tag
@onready var objectType := $TabContainer/Object/Type
#endregion

#region Camera
@onready var cameraTag := $TabContainer/Camera/Cameras
var shader_dialog: FileDialog

func _ready():
	shadersPop.min_size.x = 250
	reloadShaders()
	shadersPop.index_pressed.connect(onShaderFileSelected)
	shaderTag.placeholder_text = ''

func reloadShaders():
	shadersPop.clear()
	var last_mod: String = ''
	for i in Paths.getFilesAt("shaders",true,['frag','gdshader'],true):
		var mod = Paths.getModFolder(i)
		if last_mod != mod:
			last_mod = mod
			shadersPop.add_separator(mod)
		shadersPop.add_item(i.get_file())
		
func addShader():
	var tag = shaderTag.text if shaderTag.text else shaderTag.placeholder_text
	if modchart_editor.objects_created.has(tag):
		Global.show_label_error("Shader Already Created!")
		return
	
	var cameras: PackedStringArray = []
	if addShaderToGame.button_pressed:
		cameras.append('camGame')
	if addShaderToHUD.button_pressed:
		cameras.append('camHUD')
	if addShaderToOther.button_pressed:
		cameras.append('camOther')
	modchart_editor.insertShader(shadersOptions.text,tag,cameras)

func addObject(tag: String = objectTag.text, type: int = objectType.selected):
	if !tag:
		tag = objectTag.placeholder_text
	modchart_editor.insertObject(tag,type)

func addCamera(tag: String = cameraTag.text):
	modchart_editor.insertObject(tag,modchart_editor.PROPERTY_TYPES.TYPE_CAMERA)
func selectShaderManually():
	if !shader_dialog:
		shader_dialog = Paths.get_dialog()
		shader_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		shader_dialog.add_filter('*.frag')
		shader_dialog.add_filter('*.gdshader')
		shader_dialog.file_selected.connect(func(file):
			shadersOptions.text = file
			shaderTag.placeholder_text = file.get_file().get_basename()
		)
		add_child(shader_dialog)
	shader_dialog.visible = true
	
	
func onShaderFileSelected(index: int):
	var shader = shadersPop.get_item_text(index)
	shadersOptions.text = shader
	shaderTag.placeholder_text = shader.get_basename()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE or event is InputEventMouseButton:
		hide()
