extends Node
const OptionMenu = preload("res://source/substates/Options/OptionMenu.gd")
var back_to: Variant #Can be a GDScript or a PackedScene
var cur_visual: Node
var visuals: Dictionary = {}

var options: Array[Dictionary] = [
	{'name': 'Gameplay Options', 'menu': [
		{
			'name': 'middlescroll', 'visual': "Strums",
			'object': ClientPrefs.data, 'property': 'middlescroll', 'setter': set_middlescroll
		},
		{
			'name': 'downscroll','visual': "Strums",
			'object': ClientPrefs.data, 'property': 'downscroll', 'setter': set_downscroll
		},
		{
			'name': 'play as opponent','visual': "Strums",
			'object': ClientPrefs.data, 'property': 'playAsOpponent', 'setter': set_play_as_opponent
		}
	]},
	{'name': 'Visual Options', 'menu': [
		{
			'name': 'Low Quality', 
			'object': ClientPrefs.data, 
			'property': 'lowQuality'
		},
		{
			'name': 'Vsync', 
			'object': DisplayServer, 'getter': DisplayServer.window_get_vsync_mode
		}
	]
	}
]
var cur_menu: OptionMenu: 
	set(menu):
		if cur_menu: disableNode(cur_menu)
		cur_menu = menu
		enableNode(menu)
		_on_option_selected(cur_menu)

var menus_created: Dictionary = {}
var prev_menus: Array = []


var bg: Sprite2D = Sprite2D.new()

func _ready() -> void:
	add_child(bg)
	bg.centered = false
	bg.texture = Paths.imageTexture('menuDesat')
	var dir = "res://source/substates/Options/Visuals/"
	for i in DirAccess.get_files_at(dir):
		if i.ends_with('.tscn'): 
			var obj_name = i.get_basename()
			var scene = load(dir+i).instantiate()
			visuals[obj_name] = scene
			add_child(scene)
			scene.name = obj_name
			disableNode(scene)
	
	#Load Options
	cur_menu = createMenuOptions(options,'default')

func createMenuOptions(option_data: Array, tag: String):
	if menus_created.has(tag): return menus_created[tag]
	
	var node = OptionMenu.new()
	node.data = option_data
	node.loadInterators()
	node.on_index_changed.connect(_on_option_selected.bind(node))
	add_child(node)
	return node
	
func backMenu():
	if !prev_menus:
		if back_to: Global.swapTree(back_to)
		return
	var prev_menu = prev_menus.pop_back()
	cur_menu = prev_menu

#region Options Visual

func _on_option_selected(menu: OptionMenu):
	show_visual(menu.cur_data.get('visual',''))

func show_visual(visual_name: String):
	if !visual_name and !cur_visual: return
	if cur_visual: 
		if visual_name == cur_visual.name: return
		disableNode(cur_visual)
	cur_visual = get_node(visual_name)
	if !cur_visual: return
	enableNode(cur_visual)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_BACKSPACE: backMenu()
			KEY_ENTER:
				var cur_option_data = cur_menu.cur_data
				if !cur_option_data: return
				if cur_option_data.has('menu'):
					prev_menus.append(cur_menu)
					cur_menu = createMenuOptions(cur_option_data.menu,cur_option_data.name)
				else:
					var obj = cur_menu.get_node(cur_option_data.name)
					if obj and obj.has_node('value'): obj = obj.get_node('value')
					var value: Variant
					match cur_option_data.get('type',0):
						TYPE_BOOL: value = !obj.value
						_: return
					obj.value = value
					var setter = cur_option_data.get('setter')
					if setter: setter.call(value)

#region Setters
func set_middlescroll(middle: bool):
	ClientPrefs.data.middlescroll = middle
	cur_visual.middle = middle

func set_downscroll(down: bool):
	ClientPrefs.data.downscroll = down
	cur_visual.downscroll = down
	
func set_play_as_opponent(play: bool):
	ClientPrefs.data.playAsOpponent = play
	cur_visual.left_side = play
#endregion

static func disableNode(node: Node):
	if !node: return
	node.process_mode = Node.PROCESS_MODE_DISABLED
	node.visible = false

static func enableNode(node: Node):
	if !node: return
	node.process_mode = Node.PROCESS_MODE_INHERIT
	node.visible = true
