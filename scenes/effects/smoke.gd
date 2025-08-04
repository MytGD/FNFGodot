@tool
extends Sprite2D

func _ready():
	var tex: NoiseTexture2D = texture
	if texture and texture.width <= 1: texture.width = ScreenUtils.screenWidth
