@tool
extends Node2D

@onready var bg :=BG
@onready var ground :=Ground

func _ready():
	bg.texture = Paths.imageTexture('editors/character_editor/bg')
	ground.texture = Paths.imageTexture('editors/character_editor/ground')
