// Fase 188: o arco-íris. Um anel largo (o UV.y vai de dentro, violeta, até fora, vermelho) posto pela RainbowView longe da
// câmera em volta do ponto oposto ao sol; somado à cena, sem escrever profundidade (o morro na frente o tapa), sem neblina,
// cortado abaixo do mar e mais fraco junto do horizonte. amount (0 a 1) é quanto ele aparece agora.
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float strength = 0.32;

varying float v_height;

void vertex() {
	v_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

vec3 spectrum(float t) {
	// de dentro para fora: violeta, azul, verde, amarelo, laranja, vermelho
	vec3 c = vec3(0.0);
	c += vec3(0.45, 0.2, 0.75) * (1.0 - smoothstep(0.0, 0.22, t));
	c += vec3(0.2, 0.35, 0.95) * smoothstep(0.0, 0.2, t) * (1.0 - smoothstep(0.2, 0.42, t));
	c += vec3(0.25, 0.85, 0.3) * smoothstep(0.22, 0.4, t) * (1.0 - smoothstep(0.42, 0.6, t));
	c += vec3(0.95, 0.9, 0.25) * smoothstep(0.42, 0.56, t) * (1.0 - smoothstep(0.62, 0.74, t));
	c += vec3(1.0, 0.55, 0.15) * smoothstep(0.6, 0.72, t) * (1.0 - smoothstep(0.78, 0.9, t));
	c += vec3(0.95, 0.18, 0.12) * smoothstep(0.76, 0.88, t);
	return c;
}

void fragment() {
	float t = UV.y;
	float edges = smoothstep(0.0, 0.12, t) * (1.0 - smoothstep(0.88, 1.0, t));
	// nada abaixo do mar e o pé desmanchando perto dele
	float foot = smoothstep(0.0, 40.0, v_height);
	ALBEDO = spectrum(t) * edges * foot * amount * strength;
}
