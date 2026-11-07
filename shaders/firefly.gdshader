// Fase 178: os vaga-lumes. Cada instância é um pontinho de luz (um quadrado de frente para a câmera) num enxame; o shader o
// faz vagar baixo numa volta própria e piscar (acende depressa, some devagar, quase apagado entre um pisca e outro), no tempo
// visual (para na pausa), só com a noite (global night_light). Somado à cena, sem profundidade nem sombra.
// INSTANCE_CUSTOM: r = fase do pisca, g = fase da volta, b = ritmo próprio, a = sem uso.
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

global uniform float visual_time;
global uniform float night_light;

uniform vec4 glow : source_color = vec4(0.78, 1.0, 0.36, 1.0);
uniform float size_m = 0.24;
uniform float wander_m = 0.8;
uniform float blink_s = 2.8;
uniform float strength = 4.0;
// Some com a distância da câmera (o MultiMesh cobre o mundo todo: o alcance de visibilidade não serve).
uniform float fade_begin_m = 110.0;
uniform float fade_end_m = 190.0;

varying float v_light;
varying vec2 v_uv;

void vertex() {
	float t = visual_time;
	float speed = 0.6 + 0.6 * INSTANCE_CUSTOM.b;
	float phase = INSTANCE_CUSTOM.g * 6.2831853;
	vec3 drift = vec3(sin(t * 0.37 * speed + phase) + 0.5 * sin(t * 0.83 * speed + phase * 2.0),
			0.45 * sin(t * 0.51 * speed + phase * 3.0),
			cos(t * 0.29 * speed + phase) + 0.5 * cos(t * 0.71 * speed + phase * 1.7)) * wander_m;
	vec3 center = (MODEL_MATRIX * vec4(drift, 1.0)).xyz;
	vec3 right = INV_VIEW_MATRIX[0].xyz;
	vec3 up = INV_VIEW_MATRIX[1].xyz;
	vec3 world = center + (right * VERTEX.x + up * VERTEX.y) * size_m;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	float b = fract(t / (blink_s * (0.8 + 0.5 * INSTANCE_CUSTOM.b)) + INSTANCE_CUSTOM.r);
	float pulse = smoothstep(0.0, 0.08, b) * (1.0 - smoothstep(0.15, 0.55, b));
	float distance_m = length(world - INV_VIEW_MATRIX[3].xyz);
	float fade = 1.0 - smoothstep(fade_begin_m, fade_end_m, distance_m);
	v_light = (0.1 + pulse) * smoothstep(0.15, 0.7, night_light) * fade;
	v_uv = UV;
}

void fragment() {
	float d = length(v_uv * 2.0 - 1.0);
	// o pontinho aceso e o halo mole em volta dele
	float halo = 1.0 - smoothstep(0.0, 1.0, d);
	float core = halo * halo * halo * halo;
	ALBEDO = glow.rgb * (core + 0.25 * halo * halo) * v_light * strength;
}
