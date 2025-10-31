shader_type canvas_item;

// UNIFORMS ORIGINAIS
uniform vec4 grid_color: source_color = vec4(vec3(0.2),1.0);
uniform vec4 grid_bg: source_color = vec4(0.0);
uniform vec4 grid_beat_color: source_color = vec4(vec3(0.4),1.0);

uniform vec4 grid_negative_bg: source_color = vec4(0.0);
uniform vec4 grid_negative_beat_color: source_color = vec4(vec3(0.4,0.0,0.4),1.0);
uniform vec4 grid_negative_color: source_color = vec4(0.2,0.0,0.0,1.0);

uniform int section_beats = 4;

uniform float x = 0.0;
uniform float y = 0.0; 
uniform vec2 grid_size = vec2(40.0, 24.0);
uniform vec2 parent_size = vec2(1070.0, 156.0);

void fragment() {
	vec2 uv_scaled = UV * (parent_size / grid_size) + vec2(x, y);
	
	bool negative = (uv_scaled.x < 0.0 || uv_scaled.y < 0.0);
	
	vec2 abs_uv = abs(uv_scaled);
	vec2 grid = fract(abs_uv);
	
	vec2 px = max(vec2(0.05), fwidth(uv_scaled));

	bool left_margin = grid.x < px.x;
	bool top_margin = grid.y < px.y;
	
    bool is_on_line = left_margin || top_margin;
	
	int beat_mod = int(abs_uv.x) % section_beats;
	bool is_beat_line = left_margin && (beat_mod == 0);
	
	if (negative) {
		COLOR = grid_negative_bg;
		if (is_on_line) COLOR = grid_negative_color;
		if (is_beat_line) COLOR = grid_negative_beat_color;
	} else {
		COLOR = grid_bg;
		if (is_on_line)COLOR = grid_color;
		if (is_beat_line)COLOR = grid_beat_color;
	}
}