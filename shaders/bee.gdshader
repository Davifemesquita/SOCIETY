// Fase 190: as abelhas. Cada instância é um pontinho escuro (um quadrado de frente para a câmera) em volta da boca de uma
// colmeia; o shader o faz rodar depressa e sem rumo, entrando e saindo, no tempo visual (para na pausa). Some de longe (o
// MultiMesh cobre o arquipélago).
// INSTANCE_CUSTOM: r = fase da volta, g = fase do vaivém, b = ritmo próprio, a = sem uso.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

global uniform float visual_time;

uniform vec4 tint : source_color = vec4(0.18, 0.14, 0.05, 1.0);
uniform float size_m = 0.05;
uniform float reach_m = 0.7;
uniform float fade_end_m = 45.0;

varying vec2 v_uv;
varying float v_fade;

void vertex() {
	float t = visual_time * (1.6 + 1.2 * INSTANCE_CUSTOM.b);
	float phase = INSTANCE_CUSTOM.r * 6.2831853;
	// a distância da boca vai e volta (a abelha sai e entra) e a volta é torta
	float out_m = reach_m * (0.25 + 0.75 * abs(sin(t * 0.7 + INSTANCE_CUSTOM.g * 6.2831853)));
	vec3 drift = vec3(cos(t * 2.3 + phase) + 0.4 * sin(t * 5.1 + phase), 0.35 * sin(t * 3.7 + phase * 2.0) + 0.3,
			-abs(sin(t * 1.9 + phase)) - 0.2 * cos(t * 4.3)) * out_m;
	vec3 center = (MODEL_MATRIX * vec4(drift, 1.0)).xyz;
	vec3 right = INV_VIEW_MATRIX[0].xyz;
	vec3 up = INV_VIEW_MATRIX[1].xyz;
	vec3 world = center + (right * VERTEX.x + up * VERTEX.y) * size_m;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	v_fade = 1.0 - smoothstep(fade_end_m * 0.7, fade_end_m, length(world - INV_VIEW_MATRIX[3].xyz));
	v_uv = UV;
}

void fragment() {
	float d = length(v_uv * 2.0 - 1.0);
	if (d > 1.0 || v_fade <= 0.01) {
		discard;
	}
	ALBEDO = tint.rgb;
}
