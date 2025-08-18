shader_type canvas_item;
uniform vec3 light_color : source_color = vec3(1.5, 1.5, 1.2);
uniform vec4 darken_color : source_color = vec4(0.8,0.8,0.8,1.0);
uniform int edge_width : hint_range(0, 30) = 4; // largura da borda iluminada (em pixels)

uniform float light_strength = 1.2;
uniform bool check_left = true;
uniform bool check_right = true;
uniform bool check_top = true;
uniform bool check_bottom = true;

void fragment() {
    if (COLOR.a == 0.0) discard;

	float edge_float = float(edge_width);
	float borders_offset = 1.0;
    vec2 pixel = vec2(1.0) / vec2(textureSize(TEXTURE, 0));

	int left = -1;
	int right = int(check_right);
	if(!check_left) left = right;


	for(int border_x = -int(check_left); border_x <= int(check_right); border_x += 2){
		for (int x = 1; x <= edge_width; x++){
			float uv_x = UV.x + float(x*border_x)*pixel.x;
			if(texture(TEXTURE,vec2(uv_x,UV.y)).a < 0.1 || uv_x <= 0.0 || uv_x >= 1.0){
				borders_offset = min(borders_offset,float(abs(x))/edge_float);
				break;
			}
		}
	}

	int top = -1;
	int bottom = int(check_bottom);
	if(!check_top) top = bottom;
	for(int border_y = top; border_y <= bottom; border_y += 2){
		for (int y = 1; y <= edge_width; y++){
			float uv_y = UV.y + float(y*border_y)*pixel.y;
			if(texture(TEXTURE,vec2(UV.x,uv_y)).a < 0.1 || uv_y <= 0.0 || uv_y >= 1.0){
				borders_offset = min(borders_offset,float(abs(y))/edge_float);
				break;
			}
		}
	}

	if(borders_offset < 1.0){
		COLOR.rgb = mix(COLOR.rgb,texture(TEXTURE,UV).rgb*light_color*light_strength,(1.0 - borders_offset));
	}
}