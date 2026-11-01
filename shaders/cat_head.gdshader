// Fase 200: a cabeça do gato. A malha tem o pivô no pescoço; o shader a gira em volta do y dele, no tempo visual (para na
// pausa): quase sempre de frente, uma vez por volta vira para um lado (que muda a cada volta) e volta. A mesma conta do
// CatView.glance; a CPU não mexe nas cabeças a cada quadro.
// INSTANCE_CUSTOM: r = a volta (s), g = onde a volta começa (0 a 1), b = o lado da primeira volta (0 ou 1), a = sem uso.
shader_type spatial;
render_mode cull_back, shadows_disabled;

global uniform float visual_time;
uniform float look_rad = 0.9;

void vertex() {
	float turns = visual_time / max(INSTANCE_CUSTOM.r, 0.1) + INSTANCE_CUSTOM.g;
	float phase = fract(turns);
	float side = mod(floor(turns) + INSTANCE_CUSTOM.b, 2.0) < 0.5 ? 1.0 : -1.0;
	float angle = side * look_rad * smoothstep(0.5, 0.6, phase) * (1.0 - smoothstep(0.85, 0.95, phase));
	float c = cos(angle);
	float s = sin(angle);
	// o mesmo giro de Basis(Vector3.UP, angle)
	mat3 turn = mat3(vec3(c, 0.0, -s), vec3(0.0, 1.0, 0.0), vec3(s, 0.0, c));
	VERTEX = turn * VERTEX;
	NORMAL = turn * NORMAL;
}

void fragment() {
	// a cor do vértice vezes a da instância chega em sRGB
	ALBEDO = pow(COLOR.rgb, vec3(2.2));
	ROUGHNESS = 0.8;
}
