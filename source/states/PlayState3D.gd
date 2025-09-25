extends "res://source/states/PlayStateBase.gd"
var camera

@export var boyfriend: Node3D
@export var gf: Node3D
@export var dad: Node3D


@onready var target: Node3D = boyfriend
var camFollow: Vector3 = Vector3.ZERO
var camGame: Camera3DCustom

func _init() -> void:
	super._init()

func _ready():
	camGame = get_node_or_null('camGame')
	if !camGame:
		camGame = Camera3DCustom.new()
		add_child(camGame)
	super._ready()
func _process(delta: float) -> void:
	super._process(delta)
	camGame.scroll = camGame.scroll.lerp(camFollow,cameraSpeed*delta*3.5)
	
func getCameraPos(object: Node) -> Vector3:
	if !object is Node3D: return Vector3.ZERO
	var target: Vector3 = object.position
	if object is Character3D:
		target += object.cameraPosition
	return object.position
	
func addCharacterToList(char,model) -> Character3D:
	return null
