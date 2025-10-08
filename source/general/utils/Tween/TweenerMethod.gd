extends "res://source/general/utils/Tween/Tweener.gd"
var init_val: Variant
var value: Variant
var callable: Callable
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

func _update() -> void:
	callable.call(Tween.interpolate_value(init_val,value-init_val,minf(step,duration),duration,transition,ease))
