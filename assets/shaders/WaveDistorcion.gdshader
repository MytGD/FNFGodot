shader_type canvas_item;

uniform float strength = 0.05;
uniform float space = 3.0;
uniform float frequency = 2.0;

uniform sampler2D screen_texture: hint_screen_texture;
void fragment(){
	float uv_x = SCREEN_UV.x+cos(SCREEN_UV.y*PI*space + TIME * frequency)*strength;
	COLOR = texture(screen_texture,vec2(uv_x,SCREEN_UV.y));
}