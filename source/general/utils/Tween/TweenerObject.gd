extends "res://source/general/utils/Tween/Tweener.gd"

##Properties that will be tweened. 
##[br]That contains [code]{"property_name": [init_value,final_value,final_value - init_value]}[/code].
var properties: Dictionary = {} 

var object: Object  ##Object that will be tweened. Can be a [Object] or a [ShaderMaterial].


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

signal updated()
func _update() -> void:
	if !object: stop(); return
	for i in properties:
		var prop = properties[i]
		var final_val: Variant
		if step >= duration: final_val = prop[1]
		else:
			final_val = Tween.interpolate_value(
				prop[0],
				prop[2],
				step,
				duration,
				transition,
				ease,
			)
		if object is ShaderMaterial: object.set_shader_parameter(i,final_val)
		else: 
			if i is NodePath: object.set_indexed(i,final_val)
			else: object.set(i,final_val)
	updated.emit()

func tween_property(property: Variant, to: Variant) -> void: ##Tween the [member object] property.
	if !object: return
	var init_val: Variant
	if object is ShaderMaterial: 
		if property is String: property = StringName(property)
		init_val = object.get_shader_parameter(property)
		if init_val == null: init_val = MathUtils.get_new_value(typeof(to))
	else:
		if property is NodePath: init_val = object.get_indexed(property)
		elif property.contains(':'): property = NodePath(property); init_val = object.get_indexed(property)
		else: property = StringName(property); init_val = object.get(property);
	
	if init_val != null: properties[property] = [init_val,to,to - init_val]
