shader_type canvas_item;

uniform int strength: hint_range(0, 50, 1) = 0;
uniform float steps: hint_range(0.0, 50.0, 0.2) = 2.0;

varying vec4 modulate;
void vertex(){
	modulate = COLOR;
}
void fragment(){
	if(strength > 0 && steps > 0.0){
		vec2 pixel_step = TEXTURE_PIXEL_SIZE*steps;
		vec4 col = COLOR;
		float div = 1.0;
		for(int i = 1; i <= strength; i ++){
			vec2 uv_step = float(i)*pixel_step;
			col += texture(TEXTURE,UV+uv_step);
			col += texture(TEXTURE,UV+vec2(uv_step.x,0.0));
			col += texture(TEXTURE,UV+vec2(0.0,uv_step.y));

			col += texture(TEXTURE,UV-uv_step);
			col += texture(TEXTURE,UV-vec2(uv_step.x,0.0));
			col += texture(TEXTURE,UV-vec2(0.0,uv_step.y));
			div += 6.0;
		}
		COLOR = col/div * modulate;
	}
}