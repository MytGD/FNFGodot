shader_type canvas_item;
uniform sampler2D screen_texture: hint_screen_texture;
uniform vec3 rain_constrast: source_color = vec3(0.1,0.1,0.1);

void fragment() {
	if(COLOR.a < 0.6){
		discard;
	}
	vec2 tex_size = vec2(textureSize(screen_texture,0));
	vec2 uv_offset = 1.0/tex_size;
	uv_offset.y *= cos(UV.x*5.)*5.0;
	vec2 screen_position = tex_size * SCREEN_UV/tex_size;
	//uv_offset *= 10.0*cos(SCREEN_UV*PI+TIME);
	COLOR.rgb = texture(screen_texture,SCREEN_UV + uv_offset).rgb + rain_constrast;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
