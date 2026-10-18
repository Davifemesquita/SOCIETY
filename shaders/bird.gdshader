// Pássaro (Fase 20): a cor dos vértices (vezes a do bando, na instância) e a asa batendo. O BirdView põe o
// ângulo da batida em INSTANCE_CUSTOM.r a cada quadro; o vértice da asa (UV.x = 1) gira em volta do eixo do
// corpo (z, na altura do ombro) por esse ângulo, cada asa para o seu lado. O corpo (UV.x = 0) fica parado.
shader_type spatial;
render_mode cull_disabled;

uniform float shoulder_y = 0.03;

void vertex() {
	float angle = INSTANCE_CUSTOM.r * UV.x;
	float side = sign(VERTEX.x);
	vec2 arm = vec2(abs(VERTEX.x), VERTEX.y - shoulder_y);
	vec2 turned = vec2(arm.x * cos(angle) - arm.y * sin(angle), arm.x * sin(angle) + arm.y * cos(angle));
	VERTEX.x = side * turned.x;
	VERTEX.y = shoulder_y + turned.y;
	NORMAL.y = mix(NORMAL.y, NORMAL.y * cos(angle) + abs(NORMAL.x) * sin(angle), UV.x);
}

void fragment() {
	vec3 color = COLOR.rgb;
	// a cor vem em sRGB, como no vertex_color_is_srgb do StandardMaterial3D
	ALBEDO = mix(pow((color + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), color * (1.0 / 12.92), lessThan(color, vec3(0.04045)));
	ROUGHNESS = 0.9;
}
