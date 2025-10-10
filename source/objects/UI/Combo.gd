extends Sprite2D

var velocity: Vector2 = Vector2(0,-200)
func _init(posX: float = 0,posY: float = 0):
	position = Vector2(posX,posY)
	centered = false
func _physics_process(delta):
	velocity.y += 800*delta
	position += velocity*delta
	if velocity.y >= 0:
		modulate.a -= delta*2.0
	
	if modulate.a <= 0:
		queue_free()
