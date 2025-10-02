extends RefCounted

##Object that will be tweened. Can be a [Object] or a [ShaderMaterial].
var object: Object  

##Properties that will be tweened. 
##[br]That contains [code]{"property_name": [init_val,final_val]}[/code].
var properties: Dictionary = {} 

 ##Tween duration.
var duration: float

##Tween step.
var step: float = 0.0: set = set_step 

##[enum Tween.TransitionType].
var transition: Tween.TransitionType

##[enum Tween.EaseType].
var ease: Tween.EaseType 

var is_playing: bool = true ##If this tween is playing.

##When set and this node is not processing, this tween will also not progress until the node is processed again.
var bind_node: Node: set = set_bind_node

signal finished ##Called when the tween finishes.
signal onUpdate
func _init(
	_object: Object, 
	_duration: float, 
	_transition: Tween.TransitionType = Tween.TRANS_LINEAR, 
	_ease: Tween.EaseType = Tween.EASE_OUT) -> void:
		object = _object
		duration = _duration
		transition = _transition
		ease = _ease

##Tween the [member object] property.
func tween_property(property: String, to: Variant) -> void:
	if !object: return
	
	var init_val: Variant
	var prop = property
	if object is ShaderMaterial: 
		init_val = object.get_shader_parameter(property)
		if init_val == null: init_val = MathHelper.get_new_value(typeof(to))
	else:
		var is_indexed = property.contains(':')
		if is_indexed:
			prop = NodePath(property)
			init_val = object.get_indexed(prop)
		else: init_val = object.get(prop)
	
	if init_val != null and init_val != to: properties[prop] = [init_val,to]

func set_step(s: float) -> void:
	step = s
	if !is_playing: return
	_update()
	if step >= duration: 
		is_playing = false
		finished.emit()

func stop() -> void:
	is_playing = false
	step = 0.0

func pause() -> void:
	is_playing = false
	
func _update() -> void:
	if !object: return
	
	for i in properties:
		var prop = properties[i]
		var final_val: Variant
		if step < duration:
			final_val = Tween.interpolate_value(
				prop[0],
				prop[1] - prop[0],
				step,
				duration,
				transition,
				ease,
			)
		else: final_val = prop[1]
		
		
		if object is ShaderMaterial: 
			object.set_shader_parameter(i,final_val)
		else: 
			if i is NodePath: object.set_indexed(i,final_val)
			else: object.set(i,final_val)

func set_bind_node(node: Node):
	if bind_node and !node: stop()
	bind_node = node
func _process(delta: float) -> void:
	if is_playing and (not bind_node or bind_node.is_inside_tree() and bind_node.can_process()): 
		step += delta
