static var maps_created: Dictionary = {}

##Load the animation and sprites from the map('.json') file
static func loadMap(folder: String) -> Dictionary:
	folder = folder.get_base_dir()
	if folder in maps_created:
		return maps_created[folder]
	
	var json: Dictionary = Paths.loadJson(folder+'/spritemap1.json')
	if not 'ATLAS' in json or not 'SPRITES' in json.ATLAS:
		return {}
	
	var data: Dictionary = {
		'SPRITES': {},
		'animations': {},
		'type': 'map'
	}
	for anim in json.ATLAS.SPRITES:
		if not 'SPRITE' in anim:
			continue
		var spriteData: Dictionary = anim.SPRITE
		var sprite: Sprite2D = Sprite2D.new()
		sprite.region_enabled = true
		sprite.region_rect = Rect2(spriteData.x,spriteData.y,spriteData.w,spriteData.h)
		if spriteData.rotated:
			sprite.rotation_degrees = 90.0
		sprite.name = spriteData.name
		data.SPRITES[spriteData.name] = [sprite,Rect2(
			spriteData.get('x',0.0),
			spriteData.get('y',0.0),
			spriteData.get('width',0.0),
			spriteData.get('height',0.0)
		)]
	maps_created[folder] = data
	
	"""
	var animation = Paths.loadJson(folder+'/Animation.json')
	if animation:
		var anim = data.animations
		var animsToLoad: Array = []
		
		for i in animation.get("AN",{}).get('TL',{}).get('L',[]):
			for anims in i.FR:
				animsToLoad.append_array(anims.E)
		animsToLoad.append(animation.get('SD',{}))
		for anims in animation.get('SD',{}):
			animsToLoad.append(anims)
	"""
	return data
