extends RefCounted
var init_val: Variant
var value: Variant
var callable: Callable

var transition: Tween.TransitionType
var ease: Tween.EaseType

var duration: float
var step: float

var bind_node: Node
func _init(
	_callable: Callable,
	_init_val: float, 
	to: float, 
	_duration: float, 
	_transition: Tween.TransitionType = Tween.TRANS_LINEAR, 
	_ease: Tween.EaseType = Tween.EASE_OUT
):
	callable = _callable
	init_val = _init_val
	value = to
	duration = _duration
	transition = _transition
	ease = _ease
	
func set_step(s: float) -> void:
	step = s
	if callable: 
		callable.call(Tween.interpolate_value(init_val,value - init_val,step,duration,transition,ease))
	
func _process(delta: float) -> void:
	if step < duration and (not bind_node or bind_node.is_inside_tree() and bind_node.can_process()): step += delta
