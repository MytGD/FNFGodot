extends Node2D

var sprite = Sprite2D.new()
signal finished

func _ready():
	name = 'Transition'
	sprite = Sprite2D.new()
	sprite.name = 'gradiant'
	sprite.texture = GradientTexture2D.new()
	sprite.texture.width = ScreenUtils.screenWidth
	sprite.texture.height = ScreenUtils.screenHeight*2
	sprite.centered = false
	
	sprite.texture.fill_from = Vector2(0.5,0.5)
	sprite.texture.fill_to = Vector2(0.5,1)
	sprite.texture.set_gradient(Gradient.new())
	sprite.texture.gradient.colors[1] = Color(0,0,0,0)
	sprite.texture.repeat = 0
	add_child(sprite)
	
	#var gradiant = GradientTexture1D.new()

func startTrans():
	sprite.position.x = 0
	sprite.position.y = -ScreenUtils.screenHeight*2
	var tween: Tween = create_tween()
	tween.tween_property(self,'position:y',ScreenUtils.screenHeight*2.0,0.5)
	tween.tween_callback(
		func():
			finished.emit()
	)
func removeTrans():
	var tween: Tween = create_tween()
	sprite.rotation_degrees = 180
	sprite.position.x = ScreenUtils.screenWidth
	sprite.position.y = ScreenUtils.screenHeight
	position.y = 0
	tween.tween_property(self,'position:y',ScreenUtils.screenHeight*2.0,1)
	tween.finished.connect(queue_free)
	
