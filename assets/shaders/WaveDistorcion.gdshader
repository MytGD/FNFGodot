shader_type canvas_item;

uniform float strength = 0.015;
uniform float space = 3.0;
uniform float frequency = 1.0;
uniform float offset = 0.0;
uniform sampler2D screen_texture: hint_screen_texture;
vec2 get_distorcion(vec2 uv){
	float uv_x = cos((uv.y - offset - TIME * frequency)*PI*space)*strength;
	uv_x *= clamp((uv.y - offset)*space,-1.0,1.0);
	uv_x += uv.x;
	return vec2(uv_x,uv.y);
}
void fragment(){
	//COLOR = texture(screen_texture,get_distorcion(SCREEN_UV));
	vec2 uv = get_distorcion(SCREEN_UV);
	COLOR = texture(screen_texture,uv);
}