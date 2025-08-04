shader_type canvas_item;

uniform ivec2 distance_light = ivec2(10,5);

uniform ivec2 direction_min = ivec2(1,1);
uniform ivec2 direction_max = ivec2(1,1);
//uniform ivec2 _light_distance_x = ivec2(6,6);
//uniform ivec2 _light_distance_y = ivec2(6,6);

uniform float strength = 0.5;
uniform float light_min: hint_range(0.0, 1.0, 0.1) = 0.5;

const vec2 NO_LIGHT = vec2(-5);

void fragment(){
	vec2 tex_size = vec2(textureSize(TEXTURE,0));
	vec3 tex_to_mult = vec3(1.0) - (COLOR.rgb);

	float light_div = strength/10.;
	vec2 uv_distance = 1.0/tex_size*3.5;
	vec3 tex_mult = vec3(0.);
	for(int x = distance_light.x*-direction_min.x; x <= distance_light.x*direction_max.x; x ++){
		for(int y = distance_light.y*-direction_min.y; y <= distance_light.y*direction_max.y; y ++){
			vec2 offset = vec2(float(x),float(y));

			vec3 screen_tex = texture(TEXTURE,UV+offset/tex_size).rgb;
			float max_color = max(screen_tex.r,max(screen_tex.g,screen_tex.b));
			//float screen_max = dot(screen_tex, vec3(0.2126, 0.7152, 0.0722));

			if(max_color > light_min){
				float light_step = smoothstep(light_min+0.1,1.,max_color);
				tex_mult += screen_tex*light_div*light_step;
			}
			else{
				tex_mult = vec3(0.);
			}

		}
	}
	COLOR = vec4(COLOR.rgb + COLOR.rgb*tex_mult,COLOR.a);


	/*
	vec2 light_uv = find_light_offset(distance_light,TEXTURE,UV,tex_size);
	if(light_uv != NO_LIGHT){
		vec2 screen_size = vec2(textureSize(screen_texture,0));
		vec3 screen_tex = texture(screen_texture,SCREEN_UV+(light_uv/screen_size)).rgb;
		//float screen_max = dot(screen_tex, vec3(0.2126, 0.7152, 0.0722));
		float max_color = max(screen_tex.r,max(screen_tex.g,screen_tex.b));

		if(max_color >= light_min){
			float light_distance = float(max(distance_light.x,distance_light.y));
			float dist = smoothstep(
				0.0,
				1.0,
				(light_distance - length(light_uv))/light_distance
			);

			float light_step = smoothstep(light_min,1.,max_color);

			COLOR.rgb += screen_tex*COLOR.rgb*strength*min(1.0,light_step*dist);
		}
	}*/
}
/*
vec2 find_light_offset(ivec2 offsets, sampler2D tex, vec2 uv, vec2 tex_size){
	vec2 uv_distance = 1.0/tex_size;
	vec2 founded = NO_LIGHT;
	for(int x = 0; x <= offsets.x; x++){
		for(int y = 0; y <= offsets.y; y ++){
			ivec2 offset = ivec2(x,y);

			for(int x_mult = -direction_min.x; x_mult<= direction_max.x; x_mult ++){
				for(int y_mult = -direction_min.y; y_mult<= direction_max.y; y_mult ++){
					vec2 mult = vec2(float(x*x_mult),float(y*y_mult));
					vec2 _uv = uv+(mult*uv_distance);
					if(any(lessThan(_uv,vec2(0.0))) || any(greaterThan(_uv,vec2(1.0)))) return mult;
					if(texture(tex,_uv).a <= 0.3) return mult;
				}
			}

		}
	}
	return NO_LIGHT;
}
*/