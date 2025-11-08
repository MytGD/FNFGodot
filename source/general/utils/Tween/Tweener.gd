@abstract
extends RefCounted
var duration: float  ##Tween duration.
var step: float: set = set_step ##Tween step.
var transition: Tween.TransitionType ##[enum Tween.TransitionType].
var ease: Tween.EaseType ##[enum Tween.EaseType].

var is_playing: bool = true ##If this tween is playing.

##When set and this node is not processing, this tween will also not progress until the node is processed again.
var bind_node: Node: set = set_bind_node

var running: bool

signal finished ##Called when the tween finishes.
func set_step(s: float) -> void:
	step = s
	if !is_playing: return
	if step >= duration:
		step = duration
		_update()
		is_playing = false
		finished.emit()
		
	else: _update()

@abstract func _update() #Used in another Tweeners

func stop() -> void: is_playing = false; step = 0.0

func pause() -> void: is_playing = false

func set_bind_node(node: Node):
	if bind_node and !node: stop()
	bind_node = node
	
func _process(delta: float) -> void:
	if !is_playing: return
	if !bind_node: stop(); return
	if (bind_node.is_inside_tree() and bind_node.can_process()): 
		step += delta
