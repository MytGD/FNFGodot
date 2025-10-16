shader_type canvas_item;

uniform float strength = 1.0;
uniform sampler2D screen_texture: hint_screen_texture;
void fragment(){
	vec4 col = texture(screen_texture,SCREEN_UV);
	COLOR.rgb = mix(col.rgb,vec3(dot(col.rgb,vec3(0.299, 0.587, 0.114))),strength);
}