extends "res://source/general/utils/Tween/Tweener.gd"

##Properties that will be tweened. 
##[br]That contains [code]{"property_name": [init_val,final_val]}[/code].
var properties: Dictionary = {} 
var _prop_keys: Array
##Object that will be tweened. Can be a [Object] or a [ShaderMaterial].
var object: Object  


func _init(
	_object: Object, 
	_duration: float, 
	_transition: Tween.TransitionType = Tween.TRANS_LINEAR, 
	_ease: Tween.EaseType = Tween.EASE_OUT
) -> void:
	object = _object
	duration = _duration
	transition = _transition
	ease = _ease

func _update() -> void:
	if !object: stop(); return
	var index: int = 0
	var prop_length = _prop_keys.size()
	while index < prop_length:
		var i = _prop_keys[index]
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
		
		if object is ShaderMaterial: object.set_shader_parameter(i,final_val)
		else: 
			if i is NodePath: object.set_indexed(i,final_val)
			else: object.set(i,final_val)
		index += 1
func tween_property(property: String, to: Variant) -> void: ##Tween the [member object] property.
	if !object: return
	var init_val: Variant
	var prop = property
	if object is ShaderMaterial: 
		init_val = object.get_shader_parameter(property)
		if init_val == null: init_val = MathUtils.get_new_value(typeof(to))
	else:
		if property.contains(':'): prop = NodePath(property); init_val = object.get_indexed(prop)
		else: init_val = object.get(prop)
	if init_val != null and init_val != to: 
		properties[prop] = [init_val,to]
		_prop_keys.append(prop)
