shader_type canvas_item;

uniform float smoke_speed = 0.1;
uniform float smoke_alpha = 1;
uniform float limit_top = 0.0;
uniform float limit_bottom = 1.0;
uniform float limit_left = 0.0;
uniform float limit_right = 1.0;
uniform float fade_margin = 0.5;
uniform bool move_x = true;
uniform bool move_y = false;
uniform sampler2D smoke_texture;

vec2 mirror_repeat(vec2 uv){
	//uv = mod(uv,vec2(2.0));
	return abs(uv - (trunc(uv)));
}
void fragment(){
	vec2 uv = UV;
	if(move_x && move_y){
		uv = mirror_repeat(UV - (TIME*smoke_speed));
	}
	else if(move_x){
		uv = mirror_repeat(UV - (TIME*vec2(smoke_speed,0.0)));
	}
	else if(move_y){
		uv = mirror_repeat(UV - TIME*vec2(0.0,smoke_speed));
	}

	float alpha = smoke_alpha;
	if (UV.x < limit_left) alpha *= smoothstep(limit_left - fade_margin, limit_left, UV.x);
	if (UV.x > limit_right) alpha *= smoothstep(limit_right + fade_margin, limit_right, UV.x);
	if (UV.y < limit_top) alpha *= smoothstep(limit_top - fade_margin, limit_top, UV.y);
	if (UV.y > limit_bottom) alpha *= smoothstep(limit_bottom + fade_margin, limit_bottom, UV.y);

	vec4 smoke_tex = texture(TEXTURE, uv);
	COLOR = vec4(smoke_tex.rgb, alpha * max(smoke_tex.r,max(smoke_tex.g,smoke_tex.b)));
}
