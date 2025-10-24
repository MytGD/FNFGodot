shader_type canvas_item;

uniform float rOffset: hint_range(-0.5,0.5,0.001) = 0.0;
uniform float bOffset: hint_range(-0.5,0.5,0.001) = 0.0;
uniform float gOffset: hint_range(-0.5,0.5,0.001) = 0.0;
void fragment(){
	vec2 red = texture(TEXTURE, vec2(UV.x + rOffset,UV.y)).ra;
	vec2 blue = texture(TEXTURE, vec2(UV.x + bOffset,UV.y)).ba;
	vec2 green = texture(TEXTURE, vec2(UV.x + gOffset,UV.y)).ga;
	COLOR.rgb = vec3(red.x,green.x,blue.x);
	COLOR.a += ((red.y - COLOR.a)*red.x) + ((blue.y- COLOR.a)*blue.x) + ((green.y-COLOR.a)*green.x);
}
