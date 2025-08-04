class_name TweenHelper

const transitions = {
	'linear': Tween.TRANS_LINEAR,
	'quart': Tween.TRANS_QUART,
	'quint': Tween.TRANS_QUINT,
	'elastic': Tween.TRANS_ELASTIC,
	'bounce': Tween.TRANS_BOUNCE,
	'circ': Tween.TRANS_CIRC,
	'expo': Tween.TRANS_EXPO,
	'cubic': Tween.TRANS_CUBIC,
	'cube': Tween.TRANS_CUBIC,
	'quad': Tween.TRANS_QUAD,
	'sine': Tween.TRANS_SINE,
	'smoothstep': Tween.TRANS_SINE,
	'spring': Tween.TRANS_SPRING,
	'back': Tween.TRANS_BACK
}
const easings = {
	'in': Tween.EASE_IN,
	'inout': Tween.EASE_IN_OUT,
	'out': Tween.EASE_OUT,
	'outin': Tween.EASE_OUT_IN
}
static func detect_trans(trans: String, default: int = Tween.TRANS_LINEAR) -> int:
	trans = trans.to_lower()
	for keys in transitions:
		if trans.begins_with(keys):
			return transitions[keys]
	return default

static func detect_ease(easing: String, default: int = Tween.EASE_OUT) -> int:
	easing = easing.to_lower()
	for tweenEase in easings:
		if easing.ends_with(tweenEase):
			return easings[tweenEase]
	return default


#region Shader Functions
static func tween_shader(shader_material: ShaderMaterial, parameter: StringName, final_val: float, time: float, easing: StringName = 'linear',bind_node: Node = Global) -> Tween:
	bind_node = get_tween_node(bind_node)
	if !shader_material or !bind_node:
		return
	var tween: Tween = bind_node.create_tween()
	var from = shader_material.get_shader_parameter(parameter)
	if from == null:
		from = 0
	tween = set_tween_ease(tween,easing)
	tween.tween_method(
		func(value: float): 
			shader_material.set_shader_parameter(parameter,value), 
		from,
		final_val,
		time
	)
	return tween
#endregion
	
static func createTween(object: Object,propertys: Dictionary, time: float = 1.0, easing: String = 'linear', bind_node: Node = Global) -> Tween:
	if !object:
		return null
	bind_node = get_tween_node(bind_node)
	if !bind_node:
		return null
	
	var tween: Tween = bind_node.create_tween()
	tween = set_tween_ease(tween,easing)
	tween.set_parallel()
	tween = tween.bind_node(bind_node)
	for property in propertys:
		var value = propertys[property]
		property = property.replace('.',':')
		tween.tween_property(object,property,value,time)
	return tween

static func createTweenMethod(method: Callable, from: Variant, to: Variant, time: float = 1.0, ease: String = 'linear',bind_node: Node = Global):
	bind_node = get_tween_node(bind_node)
	return set_tween_ease(bind_node.create_tween().tween_method(method,from,to,time),ease) if bind_node else null
	
static func get_tween_node(bind_node: Node) -> Node:
	return bind_node if bind_node else Global
	
static func set_tween_ease(tween,easing: StringName):
	if !tween:
		return
	return tween.set_ease(detect_ease(easing)).set_trans(detect_trans(easing))
