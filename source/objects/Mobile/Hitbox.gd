extends Node2D

const Note = preload("res://source/objects/Notes/Note.gd")

var count: int = 4
var hitboxs: Array = []
var touchs: Array = []

var hitbox_offset: Vector2 = Vector2.ZERO
var alpha_touched: float = 0.5
var alpha_untouched: float = 0
var touches_positions: Dictionary = {}

class HitBox extends Sprite2D:
	var alpha_pressed: float = 1.0
	var alpha_unpressed: float = 0
	var action: String = ''
	var pressed: 
		set(value):
			if value == pressed: return
			pressed = value
			
			create_tween().tween_property(self,"modulate:a",alpha_pressed if pressed else alpha_unpressed,0.1)
			if pressed: Input.action_press(action)
			else: Input.action_release(action)
	
	func _init(): texture = Paths.imageTexture('mobile/hitbox')
	
	
func _init(hitbox_count: int = 4):
	count = hitbox_count
	process_priority = 2
	
func _ready():
	name = 'HitBox'
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	hitbox_offset = Vector2(ScreenUtils.screenWidth/count,ScreenUtils.screenHeight)
	
	var scale = hitbox_offset/(ScreenUtils.screenWidth/count)
	
	var keys = Note.getNoteAction(count)
	for i in range(count):
		var sprite = HitBox.new()
		hitboxs.append(sprite)
		sprite.position.x = hitbox_offset.x*i
		sprite.modulate.a = alpha_untouched
		sprite.centered = false
		sprite.alpha_pressed = alpha_touched
		sprite.alpha_unpressed = alpha_untouched
		sprite.action = keys[i]
		add_child(sprite)
		
	touchs.resize(count)
	touchs.fill([Vector2.ZERO])
func _get_touched_hitboxes() -> Array[HitBox]:
	var hitboxs_array: Array[HitBox] = []
	for hitbox in hitboxs:
		for i in touches_positions:
			if MathUtils.is_pos_in_area(touches_positions[i],hitbox.position,hitbox_offset):
				hitboxs_array.append(hitbox)
				break
	return hitboxs_array
	
func _update_hitboxs():
	var touches = _get_touched_hitboxes()
	for i: HitBox in hitboxs:
		i.pressed = i in touches
	
func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			touches_positions[event.index] = event.position
		else:
			touches_positions.erase(event.index)
		_update_hitboxs()
	elif event is InputEventScreenDrag:
		touches_positions[event.index] = event.position
		_update_hitboxs()
		
	
