shader_type canvas_item;

uniform float rotate_x : hint_range(-1.57, 1.57) = 0.0; // Rotação em radianos
uniform float rotate_y : hint_range(-1.57, 1.57) = 0.0;

void fragment() {
    // UV centralizado no range -1..1
    vec2 uv = (UV - 0.5) * 5.0;

	// --- Rotação em X ---
    float cosx = cos(rotate_x);
    float sinx = sin(rotate_x);


    vec3 pos = vec3(
        uv.x,
        uv.y * cosx - sinx,
        uv.y * sinx + cosx
    );

	// --- Rotação em Y ---
    float cosy = cos(rotate_y);
    float siny = sin(rotate_y);

    pos = vec3(
        pos.x * cosy + pos.z * siny,
        pos.y,
       -pos.x * siny + pos.z * cosy
    );

    // --- Perspectiva ---
    vec2 proj = pos.xy / pos.z;

    // Normalizar de volta para 0..1
    vec2 uv_proj = proj * 0.2 + 0.5;
	if (uv_proj.x < 0.0 || uv_proj.x > 1.0 || uv_proj.y < 0.0 || uv_proj.y > 1.0) discard;
	COLOR = texture(TEXTURE, uv_proj);
}
