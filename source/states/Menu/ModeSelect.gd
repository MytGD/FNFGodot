extends Node2D

const StoryMenu = preload("res://source/states/StoryMenu/StoryMenu.gd")
const Freeplay = preload("res://source/states/Freeplay.gd")
const Options = preload("res://source/substates/Options/Options.gd")

const menu_options_name: PackedStringArray = ['story_mode','freeplay','mods','options']

var bg: Sprite2D = Sprite2D.new()

var camera_limit_y: float = 300

var menu_option_nodes: Dictionary

var options: Array = []
static var curOptionIndex: int = 0

static var option_node: Node:
	set(value):
		if option_node:
			option_node.animation.play('static')
		option_node = value
		if value:
			value.animation.play('selected')
			
var canSwap: bool = true

var blink: bool = false

var treeSwap: Timer = Timer.new()

@onready var option_parent = Node2D.new()

var freeplay_node: Freeplay
func spawn():
	for i in menu_option_nodes.values():
		i.create_tween().tween_property(i,'modulate:a',1,0.5)
	create_tween().tween_property(self,'modulate',Color.WHITE,0.5)
	set_process_input(true)
	canSwap = true
	
func transparent():
	for i in menu_option_nodes.values():
		i.create_tween().tween_property(i,'modulate:a',0,0.5)
	blink = false
	bg.modulate = Color.WHITE
	create_tween().tween_property(self,'modulate',Color.DIM_GRAY,0.5)
	
func _ready():
	bg.texture = Paths.imageTexture('menuBG')
	bg.scale = ScreenUtils.screenSize/ScreenUtils.defaultSize
	bg.centered = false
	add_child(bg)
	
	option_parent.name = 'Options'
	add_child(option_parent)
	
	treeSwap.name = 'treeSwap'
	treeSwap.timeout.connect(func():
		set_process_input(false)
		exitTo(menu_options_name[curOptionIndex])
	)
	add_child(treeSwap)
	
	FunkinGD.playSound(Paths.music('freakyMenu'),1.0,'freakyMenu',false,true)
	
	options.clear()
	
	var menu_data = getMenuBaseData()
	menu_data.merge(Paths.loadJson('mainmenu/menu'),true)
	camera_limit_y = menu_data.camera_limit_y
	for menus in menu_options_name:
		var menu_pos = menu_data.get(menus+'_position',[0,0])
		var menu: Sprite = Sprite.new('mainmenu/menu_'+menus,true)
		menu.animation.addAnimByPrefix('static',menus+' basic',24,true)
		menu.animation.addAnimByPrefix('selected',menus+' white',24,true)
		menu.offset_follow_scale = true
		menu.addAnimOffset('selected',menu.pivot_offset/3)
		menu.addAnimOffset('static',Vector2.ZERO)
		menu.set_pos(Vector2(menu_pos[0] - menu.pivot_offset.x,menu_pos[1]) - ScreenUtils.screenOffset/2.0)
		option_parent.add_child(menu)
		options.append(menu)
		menu_option_nodes['menu_'+menus] = menu
	
	var version: Label = Label.new()
	version.label_settings = LabelSettings.new()
	version.label_settings.outline_size = 6
	version.label_settings.outline_color = Color.BLACK
	version.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	version.text = 'FNF: Godot Engine v'+str(ProjectSettings.get_setting("application/config/version"))+'\nby n_Myt'
	
	set_option()
	add_child(version)
	version.position.y = ScreenUtils.screenHeight-50
		
func _process(delta: float) -> void:
	if blink:
		var time = Time.get_ticks_usec()/20000.0
		options[curOptionIndex].visible = sin(time) > 0
		bg.modulate = Color.WHITE if not sin(time/3.0) > 0 else Color.MEDIUM_PURPLE
		
	option_parent.position.y = lerpf(
		option_parent.position.y,
		-camera_limit_y*(float(curOptionIndex)/menu_options_name.size()),
		10*delta
	)
	
func set_option(index: int = curOptionIndex):
	if not canSwap:
		return
	var optionSize = options.size()-1
	if index > optionSize: index = 0
	elif index < 0:index = optionSize
	curOptionIndex = index
	option_node = options[curOptionIndex]
	FunkinGD.playSound('scrollMenu')

func selectOption(node: Node = option_node):
	canSwap = false
	FunkinGD.playSound('confirmMenu')
	blink = true
	treeSwap.start(1)
	option_node = node

func exitTo(option: String):
	match option:
		'story_mode':
			var story_menu = StoryMenu.new()
			story_menu.back_to = get_script()
			Global.swapTree(story_menu,true)
		'freeplay':
			freeplay_node = Freeplay.new()
			freeplay_node.exiting.connect(spawn)
			add_child(freeplay_node)
			transparent()
		'options':
			var i = Options.new()
			i.back_to = get_script()
			Global.swapTree(i)
		_:
			set_process_input(true)
	treeSwap.stop()
	blink = false
	
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				set_option(curOptionIndex - 1)
			KEY_DOWN:
				set_option(curOptionIndex + 1)
			KEY_ENTER:
				selectOption()
			KEY_BACKSPACE:
				if not canSwap:
					FunkinGD.playSound('cancelMenu')
					canSwap = true
					blink = false
					treeSwap.stop()
					if option_node:
						option_node.visible = true
					bg.modulate = Color.WHITE
				
	elif event is InputEventMouseButton and event.pressed and event.button_index == 1:
		var index: int = 0
		for i in options:
			if MathHelper.is_pos_in_area(event.position,i.global_position,i.image.region_rect.size):
				if index == curOptionIndex:
					selectOption(i)
				else:
					set_option(index)
				break
			index += 1
		

static func getMenuBaseData() -> Dictionary:
	return {
		"story_mode_position": [640,50],
		"freeplay_position": [640,225],
		"mods_position": [640,400],
		"options_position": [640,575],
		"camera_limit_y": 100
	}
