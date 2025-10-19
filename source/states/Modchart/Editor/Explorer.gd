extends ScrollContainer

const nodes_offset = Vector2(20,20)
const nodes_offset_center = Vector2(10,10)
@export var object: Node: set = set_object
@export var add_parent: bool = true

var icons_found: Dictionary = {}
signal on_button_selected(node: ButtonExplorer)
func set_object(obj: Node):
	object = obj
	if is_node_ready():
		for i in get_children(): i.queue_free()
		update()

func _ready() -> void: update()
	
func add_new_child(obj: Node, parent: ButtonExplorer = null):
	var node_button = ButtonExplorer.new()
	node_button.object = obj
	
	var sprite = Sprite2D.new()
	sprite.texture = _get_node_icon(obj)
	sprite.centered = false
	sprite.position = Vector2(15,5)
	node_button.add_child(sprite)
	
	if !parent: add_child(node_button)
	else: parent.add_item(node_button)
	node_button.position.x = nodes_offset.x
	node_button.interator.pressed.connect(func(): on_button_selected.emit(node_button))
	
	var func_bind = _button_child_enter_tree.bind(node_button)
	obj.child_entered_tree.connect(func_bind)
	obj.tree_exiting.connect(func(): 
		node_button.queue_free();
		obj.child_entered_tree.disconnect(func_bind),
		CONNECT_ONE_SHOT
	)
	return node_button

func _button_child_enter_tree(node: Node, button: ButtonExplorer): add_new_child(node,button)

func _button_child_exit_tree(node: Node, button: ButtonExplorer): pass

func _get_node_icon(node: Node) -> Texture:
	var script = node.get_script()
	if script and _icon_exists(script): return icons_found[script]
	return _get_class_icon(node.get_class())
func _get_class_icon(_class: String,default_icon: String = 'Node') -> Texture:
	var getting_default: bool = false
	while _class:
		if _icon_exists(_class): return icons_found[_class]
		_class = ClassDB.get_parent_class(_class)
		if !_class and !getting_default: _class = default_icon 
	return null

func _icon_exists(_name: Variant) -> bool:
	var icon = icons_found.get(_name)
	if icon: return true
	var path: String
	if _name is Script:path = 'res://icons/'+_name.resource_path.get_basename().get_file()+'.svg'
	else: path = 'res://icons/'+_name+'.svg'
	if FileAccess.file_exists(path):
		icons_found[_name] = load(path)
		return true
	return false
func add_childs(childs: Array,parent: Control = null):
	for i in childs: 
		var button = add_new_child(i,parent)
		var children = i.get_children()
		if children: add_childs(children,button)

func update():
	if !object: return
	var button = add_new_child(object)
	add_childs(object.get_children(),button)
	#update_childs_pos()

class ButtonExplorer extends Control:
	var object: Node: set = set_object 
	var interator: Button = Button.new()
	var minize_button = Button.new()
	var container: VBoxContainer
	func _ready() -> void:
		minize_button.text = '>'
		minize_button.pivot_offset = Vector2(8,12)
		minize_button.scale = Vector2(0.8,0.8)
		minize_button.modulate = Color.DARK_GRAY

		minize_button.toggle_mode = true
		minize_button.button_pressed = true
		minize_button.visible = !!container
		minize_button.flat = true
		minize_button.focus_mode = Control.FOCUS_NONE
		
		interator.flat = true
		minize_button.name = 'Minize Button'
		minize_button.toggled.connect(func(_t):
			_check_minimize()
			update_size()
		)
		_check_minimize()
		
		add_child(minize_button)
		interator.position.x = 15
		add_child(interator)
		update_size()
	
	func _check_minimize() -> void:
		minize_button.rotation_degrees = 0 if minize_button.button_pressed else 90
		if container: container.visible = !minize_button.button_pressed
	
	func add_item(node: ButtonExplorer) -> void:
		if !container: _create_container()
		container.add_child(node)
	
	func _create_container() -> void:
		container =  VBoxContainer.new()
		container.name = 'Container'
		add_child(container)
		container.position = Vector2(nodes_offset.x,23)
		container.minimum_size_changed.connect(update_size)
		container.visible = !minize_button.button_pressed
		container.child_exiting_tree.connect(_child_exited)
		minize_button.visible = true
	
	func _child_exited(_n: Node) -> void:
		if container.get_child_count() <= 1:
			container.visible = false
			container.queue_free();
			minize_button.visible = false
			update_size()
			queue_redraw()
			
	func update_size() -> void:
		if container and container.visible:  custom_minimum_size.y = interator.get_minimum_size().y+container.size.y
		else: custom_minimum_size.y = interator.get_minimum_size().y
	
	func set_object(obj: Node) -> void:
		if !obj: return
		interator.text = '  '+obj.name
		object = obj
	
	#Draw Connection Lines
	func _draw() -> void:
		if !container or !container.visible: return
		var last_pos: float = 0.0
		var col = Color(0.2,0.2,0.2,1)
		for i in container.get_children():
			last_pos = i.position.y
			draw_rect(Rect2(Vector2(7,last_pos+35),Vector2(nodes_offset.x-10,2)),col)
		
		draw_rect(Rect2(
				Vector2(7,20),
				Vector2(2,last_pos + 5 + nodes_offset_center.y)
			),
			col
		)
