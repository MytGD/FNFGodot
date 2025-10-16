shader_type canvas_item;

uniform float rOffset = 0.0;
uniform float bOffset = 0.0;
uniform float gOffset = 0.0;
void fragment(){
	vec2 red = texture(TEXTURE, vec2(UV.x + rOffset,UV.y)).ra;
	vec2 blue = texture(TEXTURE, vec2(UV.x + bOffset,UV.y)).ba;
	vec2 green = texture(TEXTURE, vec2(UV.x + gOffset,UV.y)).ga;
	float alpha = max(COLOR.a,max(red.y*red.x, max(blue.y * blue.x, green.y*green.x)));
	COLOR = vec4(red.x,green.x,blue.x,alpha);
}
