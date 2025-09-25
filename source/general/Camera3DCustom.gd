@tool
extends Node3D
class_name Camera3DCustom

var scroll: Vector3 = Vector3.ZERO

var shakeTime: float = 0.0
var shakeIntensity: float = 3.0

var camera: Camera3D = Camera3D.new()
func _init(): add_child(camera)
func _process(delta: float) -> void:
	var real_pos: Vector3 = scroll
	if shakeTime:
		real_pos += Vector3(
			randf_range(0.0,shakeIntensity),
			randf_range(0.0,shakeIntensity),
			randf_range(0.0,shakeIntensity)
		)
		shakeTime -= delta
		if shakeTime <= 0.0: shakeTime = 0.0
	camera.position = real_pos
