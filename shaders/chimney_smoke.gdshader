// Fase 100: a fumacinha das chaminés das casas. Cada instância é uma baforada (um quadrado de frente para a câmera)
// na boca de uma chaminé; o shader a faz subir, crescer, deitar com o vento e sumir, no tempo visual (para na pausa).
// INSTANCE_CUSTOM: r = fase da baforada no ciclo, g = sorteio da chaminé, b = acesa (casa com morador), a = sem uso.
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled, shadows_disabled, blend_mix;

global uniform float visual_time;
global uniform vec2 wind_direction;
global uniform float wind_strength;

// Quanto da fumaça aparece agora (a hora do dia: mais de manhã e à noite) e as medidas do ciclo.
uniform float amount : hint_range(0.0, 1.0) = 0.6;
uniform float cycle_s = 7.0;
uniform float rise_m = 4.0;
uniform float drift_m = 2.6;
uniform float start_size_m = 0.6;
uniform float end_size_m = 2.6;
uniform vec4 tint : source_color = vec4(0.82, 0.82, 0.8, 1.0);
uniform float alpha = 0.55;
// Sem luz própria: escurece com a noite (a vista põe o brilho do céu).
uniform float brightness : hint_range(0.0, 1.0) = 1.0;
// Some com a distância da câmera (o MultiMesh cobre o mundo todo: o alcance de visibilidade não serve).
uniform float fade_begin_m = 160.0;
uniform float fade_end_m = 260.0;

varying float v_alpha;
varying vec2 v_uv;

void vertex() {
	float t = fract(visual_time / cycle_s + INSTANCE_CUSTOM.r);
	float seed = INSTANCE_CUSTOM.g;
	vec2 wind = wind_direction * wind_strength;
	// sobe mais devagar no fim (o ar esfria) e deita com o vento, com um vaivém próprio de cada chaminé
	float lift = rise_m * (1.0 - (1.0 - t) * (1.0 - t));
	vec2 side = wind * drift_m * t * t + vec2(sin(t * 5.0 + seed * 6.283), cos(t * 4.0 + seed * 9.0)) * 0.25 * t;
	vec3 center = (MODEL_MATRIX * vec4(side.x, lift, side.y, 1.0)).xyz;
	float size = mix(start_size_m, end_size_m, t);
	vec3 right = INV_VIEW_MATRIX[0].xyz;
	vec3 up = INV_VIEW_MATRIX[1].xyz;
	vec3 world = center + (right * VERTEX.x + up * VERTEX.y) * size;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	float distance_m = length(world - INV_VIEW_MATRIX[3].xyz);
	float fade = 1.0 - smoothstep(fade_begin_m, fade_end_m, distance_m);
	v_alpha = alpha * amount * INSTANCE_CUSTOM.b * fade * smoothstep(0.0, 0.12, t) * (1.0 - t);
	v_uv = UV;
}

void fragment() {
	// a baforada redonda e mole na borda
	vec2 p = v_uv * 2.0 - 1.0;
	float puff = 1.0 - smoothstep(0.35, 1.0, length(p));
	ALBEDO = tint.rgb * brightness;
	ALPHA = puff * v_alpha;
}
