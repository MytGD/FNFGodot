extends Node

static var mapEvents: Dictionary = {}

static var touchs_positions: Dictionary[int,Vector2]

func _ready() -> void: process_priority = 5

static func is_any_actions_pressed(actions: PackedStringArray) -> bool:
	for i in actions:
		if Input.is_action_pressed(i): return true
	return false
	
static func get_map_keys(map: String) -> Array:
	if not mapEvents.has(map): mapEvents[map] = InputMap.action_get_events(map)
	return mapEvents[map]

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed: touchs_positions[event.index] = event.position
		else: touchs_positions.erase(event.index)
	elif event is InputEventScreenDrag: touchs_positions[event.index] = event.position

#region Tounch Functions
##Return the touch position using his index. If the touch don't exists, returns [code]Vector2(-1,-1)[/code]
func get_touch_position(index: int) -> Vector2:
	return touchs_positions[index] if index in touchs_positions else Vector2(-1,-1)

func is_touching_2d_object(object: Variant) -> bool:
	if !object: return false
	
	var obj_position = object._position if object is Sprite else object.get('position')
	if !obj_position: return false
	
	var texture = object.get('texture')
	if !texture: return false
	var tex_size = texture.get_size()*object.scale
	var position = Rect2(obj_position,obj_position+tex_size)
	for i in touchs_positions.values():
		if i >= position.position and i <= position.size: return true
	return false
#endregion
