extends RefCounted
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
func set_step(s: float) -> void:
	step = s
	if !is_playing: return
	if step >= duration:
		step = duration
		_update()
		is_playing = false
		finished.emit()
	else: _update()

func _update() -> void: pass #Used in another Tweeners

func stop() -> void:
	is_playing = false
	step = 0.0

func pause() -> void:
	is_playing = false

func set_bind_node(node: Node):
	if bind_node and !node: stop()
	bind_node = node
	
func _process(delta: float) -> void:
	if is_playing and (not bind_node or bind_node.is_inside_tree() and bind_node.can_process()): 
		step += delta
