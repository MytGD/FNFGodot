shader_type canvas_item;

uniform float strength = 0.015;
uniform float space = 3.0;
uniform float frequency = 1.0;
uniform float offset = 0.0;
uniform sampler2D screen_texture: hint_screen_texture;
void fragment(){
	float uv_x = cos((SCREEN_UV.y - offset - TIME * frequency)*PI*space)*strength;
	uv_x *= clamp((SCREEN_UV.y - offset)*space,-1.0,1.0);
	uv_x += SCREEN_UV.x;
	if(uv_x < 0.0 || uv_x > 1.0) discard;
	COLOR = texture(screen_texture,vec2(uv_x,SCREEN_UV.y));
}