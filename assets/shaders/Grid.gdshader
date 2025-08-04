shader_type canvas_item;

uniform vec4 grid_color: source_color = vec4(vec3(0.2),1.0);
uniform vec4 grid_bg: source_color = vec4(0.0);
uniform vec4 grid_beat_color: source_color = vec4(vec3(0.4),1.0);

uniform vec4 grid_negative_bg: source_color = vec4(0.0);
uniform vec4 grid_negative_beat_color: source_color = vec4(vec3(0.4,0.0,0.4),1.0);
uniform vec4 grid_negative_color: source_color = vec4(0.2,0.0,0.0,1.0);


uniform int section_beats = 4;
uniform bool grid_bg_enabled = false;

uniform float x = 0.0;
uniform float y = 0.0;
uniform vec2 grid_size = vec2(40.0, 24.0);     // Tamanho de cada célula
uniform vec2 parent_size = vec2(1070.0, 156.0); // Tamanho do Control (enviado pelo script)

void fragment() {
	vec2 cells = parent_size / grid_size;
	vec2 uv = UV * cells + vec2(x, y);
	bool negative = (uv.x < 0.0 || uv.y < 0.0);
	uv = abs(uv);
	ivec2 uv_mod = ivec2(uv);
	vec2 grid = uv - vec2(uv_mod);

	vec2 px = max(vec2(0.05),fwidth(uv));

	bool left_margin = grid.x < px.x;
	bool right_margin = grid.x > 1.0 - px.x;
	bool top_margin = grid.y < px.y;
	bool bottom_margin = grid.y > 1.0 - px.y;

	if(grid_bg_enabled){
		COLOR = negative ? grid_negative_bg : grid_bg;
	}
	if (left_margin || right_margin ||
	    top_margin || bottom_margin) {
		COLOR = negative ? grid_negative_color : grid_color;
		if(uv_mod.x > 0){
			int beat_mod = uv_mod.x % section_beats;
			if(beat_mod == 0 && left_margin || beat_mod == 3 && right_margin){
				COLOR = negative ? grid_negative_beat_color : grid_beat_color;
			}
		}
	}
}