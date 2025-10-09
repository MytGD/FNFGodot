extends Node
const AlphabetText = preload("res://source/objects/AlphabetText/AlphabetText.gd")
const NumberRange = preload("res://source/substates/Options/NumberRange.gd")
const NumberRangeKeys = preload("res://source/substates/Options/NumberRangeKeys.gd")

var back_to: GDScript
var bg: Sprite2D = Sprite2D.new()
const check_box = preload("res://source/states/Menu/CheckBoxSprite.gd")

# option: [object/dictionary that have that property, property, value_names, default_value]
var options = {
	'Keybinds': {},
	'Gameplay Options': {
		'downscroll': [ClientPrefs.data, 'downscroll'],
		'middlescroll': [ClientPrefs.data, 'middlescroll'],
		'Play As Opponent': [ClientPrefs.data, 'playAsOpponent']
	},
	'Visual Options': {
		'hideHud': [ClientPrefs.data, 'hideHud'],
		'lowQuality': [ClientPrefs.data, 'lowQuality'],
		'frameRate': [Engine, 'max_fps', [50,360,1]]
	}
}

var old_options: Array = []
var textNodes: Array[Node]

var textsGroup: Node2D = Node2D.new()

var curNode: Node

var curOption: Dictionary
var curSelected: int:
	set(value):
		if not textNodes:
			return
		var size = textNodes.size()
		if value >= size:
			value = 0
		if value < 0:
			value = size-1
			
		if value != curSelected:
			FunkinGD.playSound('scrollMenu')
		curNode = textNodes[value]
		curNode.modulate = Color.WHITE
		
		textNodes[curSelected].modulate = Color.GRAY
		curSelected = value
		
func _init():
	if Paths.is_on_mobile: removeComputerOptions()
	
	add_child(bg)
	add_child(textsGroup)
	
	bg.centered = false
	bg.texture = Paths.imageTexture('menuDesat')
	
	loadOptions(options)

func removeComputerOptions() -> void:
	options["Visual Options"].erase("Window Mode")
	
func loadOptions(data, save_old: bool = true):
	if !data: return
	curSelected = 0
	for text in textNodes: text.queue_free()
	
	textNodes.clear()
	textsGroup.position.y = 0
	var id = -1
	
	
	for option in data:
		id += 1
		var node = AlphabetText.new(option+':' if not data[option] is Dictionary else option)
		node.name = option
		node.position = Vector2(10,50 + 100*id)
		node.modulate = Color.GRAY
		textsGroup.add_child(node)
		textNodes.append(node)
		
		var option_data = data[option]
		if option_data is Array: createOptions(node,option_data)
	
	if save_old: old_options.append(curOption)
	curOption = data
	curSelected = 0
	
func createOptions(node: Node,option_data: Array):
	var object = option_data[0]
	var variable = option_data[1]
	var value = null
	if ArrayHelper.get_array_index(option_data,3) is String and object is Object and object.has_method(option_data[3]): 
		value = object.call(option_data[3])
	else: 
		value = object.get(variable)
	
	var type = typeof(value)
	
	if ArrayHelper.get_array_index(option_data,3) is Dictionary:
		var number = createOptionControl(NumberRangeKeys,node,object,variable)
		number.name = 'num_range'
		number.set_index_keys(option_data[3])
		connect_class_to_value(option_data,number.index_changed_key)
		number.index = value
		return
		
	match type:
		TYPE_BOOL:
			var box = createOptionControl(check_box,node,object,variable)
			box.scale = Vector2(0.8,0.8)
			box.name = 'box'
			box.position.y = -30
			box.value = value
			connect_class_to_value(option_data,box.toggled)
		
		TYPE_INT,TYPE_FLOAT:
			var number = createOptionControl(NumberRange,node,object,variable)
			number.int_value = (type == TYPE_INT)
			number.name = 'num_range'
			connect_class_to_value(option_data,number.value_changed)
			number.value = value
			
			if option_data.size() >= 2:
				number.limit_min = true
				number.limit_max = true
				
				number.value_min = option_data[2][0]
				number.value_max = option_data[2][1]
				number.value_to_add = option_data[2][2]

func addValue(curNode):
	var node = findChildRange(curNode)
	if !node: return
	if node is NumberRange: node.value += 1
	elif node is NumberRangeKeys: node.index += 1

func subValue(curNode):
	var node = findChildRange(curNode)
	if !node: return
	if node is NumberRange: node.value -= 1
	elif node is NumberRangeKeys: node.index -= 1

func findChildRange(node: Node) -> Node:
	if !node: return null
	var child = node.get_node_or_null('num_range')
	if child: return child
	return null
	
func connect_class_to_value(option_data: Array, _signal: Signal):
	var _class = option_data[1]
	if _class is Object and _class.has_method(option_data[1]):
		_signal.connect(func(value):
			_class.call(option_data[1],value)
		)
		return
	
	_signal.connect(func(value):
		option_data[0].set(option_data[1],value)
	)
func createOptionControl(option_class,option_node, object_to_set: Variant, variable: Variant) -> Variant:
	var obj = option_class.new()
	option_node.add_child(obj)
	obj.position.x = option_node.x + option_node.width + 50
	return obj

func exit():
	if !back_to: return
	Global.swapTree(back_to.new())
	Global.onSwapTree.connect(queue_free)
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP: curSelected -= 1
			KEY_DOWN: curSelected += 1
			KEY_LEFT: subValue(curNode)
			KEY_RIGHT: addValue(curNode)
			KEY_ENTER:
				if not curNode: return
				var optionName = curNode.name
				var optionSelected = curOption[optionName]
				var have_box = curNode.get_node_or_null('box')
				if optionSelected is Dictionary: loadOptions(optionSelected)
				elif have_box: have_box.value = !have_box.value
			KEY_BACKSPACE:
				if old_options: loadOptions(old_options.pop_back(),false)
				else: exit()
					
