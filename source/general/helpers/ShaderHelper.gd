class_name ShaderHelper

const replace_frag: Dictionary = {
	'#pragma header': '',
	'main': 'fragment',
	'openfl_TextureSize': 'vec2(textureSize(bitmap,0))',
	'flixel_texture2D': 'texture',
	'flixel_texture': 'texture',
	'texture2D': 'texture',
	'gl_FragColor': 'COLOR'
}

static func fragToGd(shaderCode: String) -> String:
	for r in replace_frag:
		shaderCode = shaderCode.replace(r,replace_frag[r])
	
	#if type == 0 and not 'uniform sampler2D screen_texture : hint_screen_texture;' in shaderCode:
		#shaderCode = 'uniform sampler2D screen_texture : hint_screen_texture;\n'+shaderCode
		#GDCode = 'uniform sampler2D screen_texture;\n'+GDCode
	if not 'shader_type canvas_item;' in shaderCode: shaderCode = 'shader_type canvas_item;\n'+shaderCode
	
	shaderCode = shaderCode.replace('openfl_TextureCoordv','UV').replace('bitmap','TEXTURE')
	shaderCode = shaderCode.replace('texture(TEXTURE,UV)','COLOR').replace('texture(TEXTURE, UV)','COLOR')
	#shaderCode = shaderCode.replace('iResolution','vec2'+str(ScreenUtils.screenSize))
	
	return shaderCode
	
#region Blend Methods
static func get_blend(blend: String) -> Material:
	match blend.to_lower():
		'add':
			var canvas = CanvasItemMaterial.new()
			canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			return canvas
		'mix':
			var canvas = CanvasItemMaterial.new()
			canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
			return canvas
		'subtract':
			var canvas = CanvasItemMaterial.new()
			canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
			return canvas
		'premult_alpha':
			var canvas = CanvasItemMaterial.new()
			canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
			return canvas
		'overlay':
			var shader_material = ShaderMaterial.new()
			shader_material.shader = Shader.new()
			shader_material.shader.code = "
			shader_type canvas_item;
			uniform sampler2D screen_texture : hint_screen_texture;
			void fragment(){
				vec4 color = texture(screen_texture,SCREEN_UV);
				vec4 tex = texture(TEXTURE,UV);
				COLOR = mix(2.0 * COLOR * tex, 1.0 - 2.0 * (1.0 - COLOR) * (1.0 - tex), step(0.5, tex));
			}
			"
			return shader_material
		_:
			return null
static func set_object_blend(object,blendMode: String) -> void:
	if !object:
		return
	object.set('material',get_blend(blendMode))
	

static func set_texture_hue(texture: ImageTexture, hue_shift: float):
	if !texture:
		return
	var image = texture.get_image().duplicate()
	if !image:
		return
	for x in image.get_width():
		for y in image.get_height():
			var color = image.get_pixel(x, y)
			color.h = fmod(color.h + hue_shift, 1.0)
			if color.h < 0:
				color.h += 1.0
			image.set_pixel(x, y, Color.from_hsv(color.h, color.s, color.v, color.a))
	texture.update(image)
#endregion
