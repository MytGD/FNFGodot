shader_type canvas_item;

uniform float strength: hint_range(0.0, 300, 0.2) = 0.0;
varying vec4 modulate;
void vertex(){
	modulate = COLOR;
}
void fragment(){
	if(strength != 0.0){
		vec2 tex_size = TEXTURE_PIXEL_SIZE*strength;
		COLOR = texture(TEXTURE,tex_size*floor(UV/(tex_size) + 0.5))*modulate;
	}
}