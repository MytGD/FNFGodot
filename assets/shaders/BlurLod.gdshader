shader_type canvas_item;
render_mode unshaded;
uniform float strength: hint_range(0, 50.0, 0.1) = 0.0;
uniform sampler2D my_tex: filter_linear_mipmap;
varying vec4 modulate;
void vertex(){
	UV -= 0.5;
	UV = UV*2.0 + 0.5;
	modulate = COLOR;
}
void fragment(){
	if(UV.x < 0.0 || UV.x > 1.0 || UV.y < 0.0 || UV.y > 1.0) discard;
	COLOR = textureLod(my_tex,UV*0.5,strength) * modulate;
}