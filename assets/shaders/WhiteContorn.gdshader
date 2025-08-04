shader_type canvas_item;

uniform int size : hint_range(1, 10) = 2;
uniform vec4 contour_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform bool show_inside = true;

struct Light{
	vec2 position;
	vec3 color;
    float radius;
};
const int maxLights = 8;

void fragment() {
	if(COLOR.a == 0.0){
		discard;
		
	}
	vec2 texel = 1.0 / vec2(textureSize(TEXTURE, 0));
	
	bool is_edge = false;
	
	for (int x = -size; x <= size && !is_edge; x++) {
	    for (int y = -size; y <= size; y++) {
			float alpha = texture(TEXTURE, UV + vec2(float(x), float(y)) * texel).a;
			if (alpha <= 0.) {
				is_edge = true;
				break;
			}
		}
		if(is_edge){
			break;
		}
	}
	
	if (is_edge) {
		COLOR = contour_color;
	} 
	else{
		COLOR = show_inside ? texture(TEXTURE, UV) : vec4(0.0);
	}
}
