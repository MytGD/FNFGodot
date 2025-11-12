shader_type canvas_item;

uniform float strength = 1.0;
void fragment(){
	vec4 col = texture(TEXTURE,UV);
	COLOR.rgb = mix(col.rgb,vec3(dot(col.rgb,vec3(0.299, 0.587, 0.114))),strength);
}