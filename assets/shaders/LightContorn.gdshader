shader_type canvas_item;

uniform bool check_top = true;
uniform bool check_bottom = true;
uniform bool check_left = true;
uniform bool check_right = true;

uniform float smooth_value: hint_range(0.0, 1.0, 0.05) = 1.0;
uniform float pixels: hint_range(0.0, 50.0, 1.0) = 10.0;
uniform float strength: hint_range(1.0, 10.0, 0.1) = 1.2;

uniform vec3 color: source_color = vec3(1.0);

float vec3_max(vec3 vec){return max(vec.x,max(vec.y,vec.z));}
float check_dir(vec2 dir, float limit, sampler2D tex, vec2 uv, vec2 pixel_dist) {
	for (float i = 0.0; i < limit; i++) {
		vec2 uv_offset = uv + (pixel_dist * dir * i);
		if (texture(tex, uv_offset).a <= 0.0 || uv_offset.x <= 0.0 || uv_offset.x >= 1.0 || uv_offset.y <= 0.0 || uv_offset.y >= 1.0){
			return (limit-i) / limit;
		}
	}
	return 0.0;
}

void fragment() {
	if(COLOR.a == 0.0) discard;
	float dist = 0.0;
	if(check_left) dist = check_dir(vec2(-1.0, 0.0), pixels,TEXTURE,UV,TEXTURE_PIXEL_SIZE);
	if(check_right)dist = max(dist,check_dir(vec2(1.0, 0.0), pixels,TEXTURE,UV,TEXTURE_PIXEL_SIZE));
	if(check_top)dist = max(dist,check_dir(vec2(0.0,-1.0), pixels,TEXTURE,UV,TEXTURE_PIXEL_SIZE));
	if(check_bottom)dist = max(dist,check_dir(vec2(0.0, 1.0), pixels,TEXTURE,UV,TEXTURE_PIXEL_SIZE));
	
	if(dist>0.0){
		float mult = vec3_max(COLOR.rgb);
		if(smooth_value > 0.0) mult*=smoothstep(0.0,smooth_value,dist);
		COLOR.rgb = mix(COLOR.rgb,color*strength,mult);
	}
}
