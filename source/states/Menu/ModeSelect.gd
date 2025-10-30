extends Node2D
const AlphabetText = preload("res://source/objects/AlphabetText/AlphabetText.gd")

const StoryMenu = preload("res://source/states/StoryMenu/StoryMenu.gd")
const Freeplay = preload("res://source/states/Freeplay.gd")
const Options = preload("res://source/substates/Options/Options.gd")

const menu_options_name: PackedStringArray = ['story_mode','freeplay','mods','options']
const mods_options: PackedStringArray = ['Character Editor','Chart Editor','Modchart Editor']

var bg: Sprite2D = Sprite2D.new()

var camera_limit_y: float = 300

var menu_option_nodes: Dictionary

var options: Array = []
static var curOptionIndex: int = 0

static var option_node: Node

var canSwap: bool = true

var _is_blinking: bool = false

var treeSwap: Timer = Timer.new()

@onready var option_parent: OptionScroll = OptionScroll.new()
@onready var mods_parent: OptionScroll = OptionScroll.new()
@onready var cur_tab: OptionScroll = option_parent

var tab_tweens: Dictionary[OptionScroll,Tween]

var return_tabs: Array[OptionScroll]

var freeplay_node: Freeplay
func spawn():
	option_parent.create_tween().tween_property(option_parent,'modulate:a',1,0.5)
	create_tween().tween_property(self,'modulate',Color.WHITE,0.5)
	set_process_input(true)
	canSwap = true

func transparent():
	for i in menu_option_nodes.values():
		i.create_tween().tween_property(i,'modulate:a',0,0.5)
	stop_blink()
	create_tween().tween_property(self,'modulate',Color.DIM_GRAY,0.5)

func blink(): _is_blinking = true
func stop_blink():
	_is_blinking = false
	canSwap = true
	bg.modulate = Color.WHITE
	if option_node: option_node.visible = true
func _ready():
	bg.texture = Paths.imageTexture('menuBG')
	bg.scale = ScreenUtils.screenSize/ScreenUtils.defaultSize
	bg.centered = false
	add_child(bg)
	
	treeSwap.name = 'treeSwap'
	treeSwap.timeout.connect(func():
		set_process_input(false)
		exitTo(menu_options_name[curOptionIndex])
	)
	add_child(treeSwap)
	
	FunkinGD.playSound(Paths.music('freakyMenu'),1.0,'freakyMenu',false,true)
	
	loadModeSelectOptions()
	loadModsOptions()
	
	_create_version()

func _create_version():
	var version: Label = Label.new()
	version.label_settings = LabelSettings.new()
	version.label_settings.outline_size = 6
	version.label_settings.outline_color = Color.BLACK
	version.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	version.text = 'FNF: Godot Engine v'+str(ProjectSettings.get_setting("application/config/version"))+'\nby n_Myt'
	
	add_child(version)
	version.position.y = ScreenUtils.screenHeight-50

func loadModeSelectOptions():
	option_parent.name = 'Options'
	add_child(option_parent)
	
	var menu_data = getMenuBaseData()
	menu_data.merge(Paths.loadJson('mainmenu/menu'),true)
	option_parent.camera_limit_y = menu_data.camera_limit_y
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
		option_parent.options.append(menu)
		options.append(menu)
		menu_option_nodes['menu_'+menus] = menu
	option_parent.scrolled.connect(func(i,_prev_i):
		option_parent.options[i].animation.play('selected')
		option_parent.options[_prev_i].animation.play('static')
	)

func loadModsOptions():
	var index: int = 0
	for i in mods_options:
		var text = AlphabetText.new(i)
		text.name = i
		text.position.x = ScreenUtils.screenCenter.x-150
		text.position.y = ScreenUtils.screenCenter.y + 150*index - 50
		index += 1
		mods_parent.options.append(text)
		mods_parent.add_child(text)
	mods_parent.modulate.a = 0.0
	add_child(mods_parent)

func _process(delta: float) -> void:
	if _is_blinking:
		var time = Time.get_ticks_usec()/20000.0
		options[curOptionIndex].visible = sin(time) > 0
		bg.modulate = Color.WHITE if not sin(time/3.0) > 0 else Color.MEDIUM_PURPLE

func set_option(index: int = curOptionIndex):
	if not canSwap:return
	
	var optionSize = cur_tab.options.size()-1
	if index > optionSize: index = 0
	elif index < 0:index = optionSize
	
	curOptionIndex = index
	
	cur_tab.option_index = index
	
	option_node = cur_tab.options[curOptionIndex]
	FunkinGD.playSound('scrollMenu')

#region Tabs
func select_tab(tab: OptionScroll):
	var tween = cur_tab.create_tween()
	do_tab_tween(cur_tab,{'modulate:a': 0.5,'scale': Vector2(0.8,0.8)},1.0,true)
	return_tabs.append(cur_tab)
	
	var index: int = 1
	for i in return_tabs:
		i.create_tween().tween_property(i,'position:x',-300*index,1.0).set_trans(Tween.TRANS_CUBIC)
		index += 1
	cur_tab = tab
	cur_tab.position.x = 0.0
	cur_tab.scale = Vector2.ONE
	do_tab_tween(tab,{'modulate:a': 1.0,'scale': Vector2.ONE},1.0,true)

func return_tab():
	if !return_tabs: return
	
	do_tab_tween(cur_tab,{'modulate:a': 0.0},0.2)
	
	cur_tab = return_tabs.pop_back()
	do_tab_tween(cur_tab,{'position:x': 0.0,'modulate:a': 1.0,'scale': Vector2.ONE},1.0,true)
	var index: int = return_tabs.size()
	for i in return_tabs:
		do_tab_tween(i,{'position:x': -200*index},1.0,true)
		index -= 1
	
func do_tab_tween(tab: OptionScroll, properties: Dictionary, duration: float, kill: bool = false):
	var tween: Tween = tab_tweens.get(tab)
	if tween and kill: 
		tween.stop()
		tween = null
	if !tween: 
		tween = tab.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.set_parallel(true)
		tab_tweens[tab] = tween
		tween.finished.connect(func(): tab_tweens.erase(tab))
	
	for i in properties: tween.tween_property(tab,i,properties[i],duration)
	return tween
#endregion

func selectOption(node: Node = option_node):
	option_node = node
	if cur_tab == option_parent:
		canSwap = false
		FunkinGD.playSound('confirmMenu')
		blink()
		treeSwap.start(1)
	else:
		exitTo(option_node.name)

func exitTo(option: String):
	if cur_tab == option_parent:
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
			'mods':
				select_tab(mods_parent)
				set_process_input(true)
			'options':
				var i = Options.new()
				i.back_to = get_script()
				Global.swapTree(i)
			_:
				set_process_input(true)
	elif cur_tab == mods_parent:
		match option:
			'Character Editor': print('character editor')
			'Chart Editor': print('chart editor')
			_: set_process_input(true)
	treeSwap.stop()
	stop_blink()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP: set_option(cur_tab.option_index - 1)
			KEY_DOWN: set_option(cur_tab.option_index + 1)
			KEY_ENTER: selectOption()
			KEY_BACKSPACE:
				FunkinGD.playSound('cancelMenu')
				if _is_blinking:
					stop_blink()
					treeSwap.stop()
				else: return_tab()
				
	elif Paths.is_on_mobile and event is InputEventMouseButton and event.pressed and event.button_index == 1:
		var index: int = 0
		for i in options:
			if MathHelper.is_pos_in_area(event.position,i.global_position,i.image.region_rect.size):
				if index == curOptionIndex: selectOption(i)
				else: set_option(index)
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


class OptionScroll extends Node2D:
	var options: Array[Node]
	var option_index: int = 0: set = _set_option_index
	var camera_limit_y = 500
	signal scrolled(index: int, old_index: int)
	func _ready() -> void: option_index = 0
	func _set_option_index(index: int):
		scrolled.emit(index,option_index)
		option_index = index
	
	func _process(delta: float) -> void:
		position.y = lerpf(
			position.y,
			-camera_limit_y*(float(option_index)/options.size()),
			10*delta
		)
	
	
