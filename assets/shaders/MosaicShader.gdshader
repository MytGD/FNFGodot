shader_type canvas_item;


uniform float strength = 0.0;
varying vec4 modulate;
void vertex(){
	modulate = COLOR;
}
void fragment(){
	if(strength != 0.){
		vec2 mosaic_strength = strength/vec2(textureSize(TEXTURE,0));
		vec2 uv = floor(UV/mosaic_strength + 0.5)*mosaic_strength;
		COLOR = texture(TEXTURE,uv)*modulate;
	}
}