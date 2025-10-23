@tool
extends Node2D
func _ready():
	$BG.texture = Paths.imageTexture('editors/character_editor/bg')
	$Ground.texture = Paths.imageTexture('editors/character_editor/ground')
	if not Engine.is_editor_hint(): set_script(null)
