shader_type canvas_item;

uniform int size : hint_range(1, 10) = 2;
uniform vec4 contour_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform bool show_inside = true;
void fragment(){
	bool is_edge = false;
	vec4 col = show_inside ? COLOR : vec4(0.0);
	float dist = 0.0;
	if(texture(TEXTURE,UV).a < 1.0){
		for (int x = -size; x <= size; x++) {
		    for (int y = -size; y <= size; y++) {
				vec2 pos = vec2(float(x), float(y));
				if (texture(TEXTURE, UV + pos * TEXTURE_PIXEL_SIZE).a > 0.0) {
					is_edge = true;
					dist = max(abs(pos.x),abs(pos.y));
					break;
				}
			}
			if(is_edge) break;
		}
	}
	if (is_edge) {
		float size_f = float(size);
		COLOR = mix(col,contour_color,1.0 - COLOR.a);
		//COLOR.a *= min(1.0,size_f/(size_f - (dist + 1.0)) * 1.0);
	} 
	else{
		COLOR = col;
	}
}
