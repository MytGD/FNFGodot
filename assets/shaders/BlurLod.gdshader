shader_type canvas_item;
render_mode unshaded;
uniform float strength: hint_range(0, 10.0, 0.5) = 0.0;
varying vec4 modulate;
void vertex(){
	modulate = COLOR;
}
void fragment(){
	COLOR = texture(TEXTURE,UV,strength);
}