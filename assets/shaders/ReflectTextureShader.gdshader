shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

uniform int edge_width : hint_range(1, 30) = 15;
uniform float light_mult = 2.5;
uniform float light_limit = 0.3;

uniform bool check_left = true;
uniform bool check_right = true;
uniform bool check_top = true;
uniform bool check_bottom = true;

float vec3max(vec3 v) {
    return max(v.r, max(v.g, v.b));
}

void fragment() {
	if (COLOR.a == 0.0) discard;
	
	vec2 pixel = 1.0 / vec2(textureSize(TEXTURE, 0));
	vec2 screen_pixel = 1.0 / vec2(textureSize(screen_texture, 0));

	vec3 light_accum = vec3(0.0);
	float weight_total = 0.0;
	
	int left = -int(check_left);
	int right = int(check_right);
	for (int dir = left; dir <= right; dir += 2) {
		for (int i = 1; i <= edge_width; i++) {
			float offset = float(i) * float(dir);
			vec2 tex_uv = UV + vec2(offset * pixel.x, 0.0);
			
			if (texture(TEXTURE, tex_uv).a > 0.1) continue;
			
			vec2 screen_uv = SCREEN_UV + vec2(float(edge_width) * screen_pixel.x, 0.0);
			vec3 screen_col = texture(screen_texture, screen_uv).rgb;
			float falloff = float(i) / float(edge_width);
			if (vec3max(screen_col) > light_limit) {
				// Falloff linear simples (quanto mais longe, menos peso)
				light_accum += screen_col * falloff;
            }
			
			weight_total += falloff;
        }
    }
	int top = -int(check_top);
	int bottom = int(check_bottom);
	for (int dir = top; dir <= bottom; dir += 2) {
		for (int i = 1; i <= edge_width; i++) {
			float offset = float(i) * float(dir);
			vec2 tex_uv = UV + vec2(0.0, offset * pixel.y);
			
			if (texture(TEXTURE, tex_uv).a > 0.1) continue;
			
			vec2 screen_uv = SCREEN_UV + vec2(0.0, float(edge_width) * screen_pixel.y);
			vec3 screen_col = texture(screen_texture, screen_uv).rgb;
			
			float falloff = float(i) / float(edge_width);
			if (vec3max(screen_col) > light_limit) {
				light_accum += screen_col * falloff;
			}
			weight_total += falloff;
        }
    }

    if (weight_total > 0.0) {
        vec3 blend_color = vec3max(texture(TEXTURE,UV).rgb) * (light_accum / weight_total) * light_mult;

        float strength = smoothstep(0.0, 1.0, weight_total / float(edge_width));
        COLOR.rgb += blend_color * strength;
    }
}
