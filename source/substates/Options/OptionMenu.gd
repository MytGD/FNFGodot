extends Node2D
const FunkinText = preload("res://source/objects/AlphabetText/AlphabetText.gd")
const FunkinCheckBox = preload("res://source/states/Menu/CheckBoxSprite.gd")
const NumberRange = preload("res://source/substates/Options/NumberRange.gd")
const TextRange = preload("res://source/substates/Options/NumberRangeKeys.gd")
var data: Array
var optionIndex: int = 0: set = set_option_index
var cur_data: Dictionary

signal on_index_changed
func _ready(): set_process_input(visible)

func set_option_index(value: int):
	if !data: return
	if value > data.size()-1: value = 0
	elif value < 0: value = data.size()-1
	
	optionIndex = value
	if cur_data:
		var last_node = get_node(cur_data.name)
		if last_node: last_node.modulate = Color.DARK_GRAY
		FunkinGD.playSound('scrollMenu')
	
	cur_data = data[optionIndex]
	var node = get_node(cur_data.name)
	if node: node.modulate = Color.WHITE
	on_index_changed.emit()
	
func loadInterators():
	var index: int = 0
	while index < data.size():
		var pos = Vector2(20,50 + 120*index)
		var data = data[index]
		
		var text_n = FunkinText.new()
		text_n.scale = Vector2(0.8,0.8)
		var obj = data.get('object')
		var value_type: int = TYPE_NIL
		var value = null
		
		if obj: 
			if data.has('getter'): 
				var params = data.get('getter_params')
				if params: value = data.getter.callv(params)
				else: value = data.getter.call()
			else:  value = obj.get(data.property)
			value_type = typeof(value)
			data.type = value_type
			
		text_n.modulate = Color.DARK_GRAY
		if value_type:
			text_n.text = data.name+':'
			createOptionInterator(data,value,text_n)
			
		else: text_n.text = data.name
		add_child(text_n)
		
		text_n.name = data.name
		text_n.position = pos
		index += 1
	set_option_index(0)
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP: optionIndex -= 1
			KEY_DOWN: optionIndex += 1
static func createOptionInterator(option_data: Dictionary, value: Variant, at: FunkinText = null) -> Node:
	var object
	var pos = Vector2.ZERO
	var value_options = option_data.get('options')
	match typeof(value):
		TYPE_BOOL: object = FunkinCheckBox.new(); pos.y -= 50
		TYPE_FLOAT: object = NumberRange.new()
		TYPE_INT:
			if value_options:
				object = TextRange.new()
				object.variables = value_options
			else:
				object = NumberRange.new()
				object.int_value = true
				object.value_to_add = 1
		_: return
	
	#Set Current Value
	if object is TextRange: object.set_index_from_key(value)
	else: object.value = value
	
	object.name = 'value'
	
	if at: object.position = Vector2(at.width+pos.x,pos.y); at.add_child(object)
	return object
