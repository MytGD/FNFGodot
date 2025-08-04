shader_type spatial;

uniform float strength = 0.0;

uniform sampler2D TEXTURE;
void fragment(){
	vec4 tex = texture(TEXTURE,UV);
	tex.rgb = mix(tex.rgb,vec3(dot(tex.rgb,vec3(0.299, 0.587, 0.114))),strength);
	ALBEDO.rgb = tex.rgb;
	ALPHA = tex.a;
}