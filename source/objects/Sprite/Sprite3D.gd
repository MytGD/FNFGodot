extends Node3D

@export var model: Node3D

var x: float:
	set(value):
		position.x -= value - x
		_position.x = x
		updatePos()
var y: float:
	set(value):
		position.y -= value - y
		_position.y = value
	get():
		return _position.y

var z: float:
	set(value):
		if z == value:
			return
		position.z -= value - z
		_position.z = value
	get():
		return _position.z

var _position: Vector3 = Vector3.ZERO
var offset: Vector3 = Vector3.ZERO

var animation: AnimationPlayer = AnimationPlayer.new()
var animOffsets: Dictionary = {}

func _init():
	add_child(animation)
func _ready() -> void:
	if model and model.has_node("AnimationPlayer"):
		animation = model.get_node("AnimationPlayer")
func loadModel(path: String):
	model = Paths.model(path)
	
func updatePos() -> void:
	position = _position + offset

func _process(delta: float) -> void:
	updatePos()

func addAnimOffset(animName: StringName, offsetX: float = 0.0, offsetY: float = 0.0, offsetZ: float = 0.0):
	animOffsets[animName] = Vector3(offsetX,offsetY,offsetZ)
	
