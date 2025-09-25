shader_type canvas_item;

uniform float strength = 0.0;
void fragment(){
	COLOR.rgb = mix(COLOR.rgb,vec3(dot(COLOR.rgb,vec3(0.299, 0.587, 0.114))),strength);
}