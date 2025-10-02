shader_type canvas_item;

const float pi_div = PI/180.0;

uniform vec2 pivot = vec2(0.5);
uniform float zoom = 1.0;
uniform float x = 0.0;
uniform float y = 0.0;
uniform float angle = 0.0;
uniform bool mirror = true;
varying vec4 modulate;
void vertex(){modulate = COLOR;}
vec2 repeat(vec2 uv){
	if(mirror){
		uv = mod(uv,vec2(2.0));
		uv = abs(uv - floor(uv)*2.0);
	}
	return uv - floor(uv);
}
void fragment(){
	vec2 uv = UV - pivot;
	if(angle != 0.0){
		vec2 tex_size = vec2(textureSize(TEXTURE,0));
		float rotation = -angle * pi_div;
		float c = cos(rotation);
		float s = sin(rotation);
		uv *= mat2(
		    vec2(c,-s/(tex_size.x/tex_size.y)),
		    vec2(s/(tex_size.y/tex_size.x),c)
		);
	}
	COLOR = texture(TEXTURE,repeat(uv*zoom+pivot+vec2(x,y))) * modulate;
}