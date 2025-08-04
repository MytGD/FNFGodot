extends "res://source/states/PlayStateBase.gd"


var camera

@export var boyfriend: Node3D
@export var gf: Node3D
@export var dad: Node3D


@onready var target: Node3D = boyfriend
var camFollow: Vector3 = Vector3.ZERO
var camGame: Camera3DCustom = Camera3DCustom.new()

func _init() -> void:
	for chars in ['boyfriend','dad','gf']:
		if !get(chars):
			set(chars,Character3D.new())
	
	super._init()

func _process(delta: float) -> void:
	super._process(delta)
	if target:
		camGame.scroll = camGame.scroll.lerp(camFollow,0.2)
	
func getCameraPos(object_name: StringName) -> Vector3:
	var obj = FunkinGD.getProperty(object_name)
	if !obj is Node3D:
		return Vector3.ZERO
	var target: Vector3 = obj.position
	match target:
		'boyfriend':
			target += obj.cameraPosition
		'dad':
			target -= obj.cameraPosition
	return obj.position
func addCharacterToList(char,model) -> Character3D:
	return null
