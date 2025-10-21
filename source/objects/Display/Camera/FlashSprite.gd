@tool
extends SolidSprite
var window: Viewport:
	set(value):
		if window: window.size_changed.disconnect(_update_size)
		window = value
		if !value: return
		window.size_changed.connect(_update_size)
		
		
func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		window = get_viewport()
func _update_size():
	scale = window.size
