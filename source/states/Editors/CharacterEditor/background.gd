@tool
extends Node2D
func _ready():
	$BG.texture = Paths.texture('editors/character_editor/bg')
	$Ground.texture = Paths.texture('editors/character_editor/ground')
	if not Engine.is_editor_hint(): set_script(null)
