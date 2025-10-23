extends ScrollContainer
const Explorer = preload("res://source/states/Editors/Modchart/Editor/Explorer.gd")
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
	node_button.explorer = self
	node_button.object = obj
	
	var sprite = Sprite2D.new()
	sprite.texture = _get_node_icon(obj)
	sprite.centered = false
	sprite.position = Vector2(15,5)
	node_button.add_child(sprite)
	
	if !parent: add_child(node_button)
	else: parent.add_item(node_button)
	node_button.position.x = nodes_offset.x
	return node_button

func _get_node_icon(node: Object) -> Texture:
	var script = node if node is Script else node.get_script()
	if script and _icon_exists(script): 
		return icons_found[script]
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
	if _name is Script:
		path = 'res://icons/'+_name.resource_path.get_basename().get_file()+'.svg'
	else: path = 'res://icons/'+_name+'.svg'
	
	if ResourceLoader.exists(path):
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
	var is_minized: bool = true
	var container: VBoxContainer
	
	var explorer: Explorer
	func _init() -> void:
		minize_button.name = 'Minize Button'
		minize_button.text = '>'
		minize_button.pivot_offset = Vector2(8,12)
		minize_button.scale = Vector2(0.8,0.8)
		minize_button.modulate = Color.DARK_GRAY
		
		minize_button.flat = true
		minize_button.focus_mode = Control.FOCUS_NONE
		
		minize_button.toggle_mode = true
		minize_button.button_pressed = !is_minized
		_check_minimize()
		
		interator.flat = true
	func _ready() -> void:
		interator.position.x = 15
		interator.pressed.connect(func(): explorer.on_button_selected.emit(self))
		minize_button.toggled.connect(func(_t):
			is_minized = !_t
			_check_minimize()
			_check_children()
			update_size()
		)
		_check_children()
		
		add_child(minize_button)
		add_child(interator)
		update_size()
	
	func _check_children():
		if !object: return
		var children = object.get_children()
		minize_button.visible = !!children
		if !is_minized: for i in children: explorer.add_new_child(i,self)
	
	func _check_minimize() -> void:
		minize_button.rotation_degrees = 0 if is_minized else 90
		if container and is_minized: for i in container.get_children(): i.queue_free()
		
	func add_item(node: ButtonExplorer) -> void:
		if is_minized: return
		if !container: _create_container()
		container.add_child(node)
	func _create_container() -> void:
		container =  VBoxContainer.new()
		container.name = 'Container'
		add_child(container)
		container.position = Vector2(nodes_offset.x,23)
		container.minimum_size_changed.connect(update_size)
		
	func _child_entered(n: Node): 
		if !explorer: return
		minize_button.visible = true
		if !is_minized: explorer.add_new_child(n,self)
		
	func _child_exited(_n: Node) -> void:
		if !container or object.get_child_count() > 1: return
		container.queue_free()
		minize_button.visible = false
		update_size()
		queue_redraw()

	func update_size() -> void:
		if container and container.visible:  custom_minimum_size.y = interator.get_minimum_size().y+container.size.y
		else: custom_minimum_size.y = interator.get_minimum_size().y
	
	func set_object(obj: Node) -> void:
		if object:
			object.child_entered_tree.disconnect(_child_entered)
			object.child_exiting_tree.disconnect(_child_exited)
			object.tree_exiting.disconnect(queue_free)
		if !obj: return
		interator.text = '  '+obj.name
		object = obj
		object.child_entered_tree.connect(_child_entered)
		object.child_exiting_tree.connect(_child_exited)
		object.tree_exited.connect(queue_free)
	
	#Draw Connection Lines
	func _draw() -> void:
		if is_minized: return
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
