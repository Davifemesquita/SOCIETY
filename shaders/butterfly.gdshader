// Fase 180: as borboletas. Cada instância é uma borboleta (o corpo ao longo de z, as asas em x, a dobra no corpo) em volta
// do lugar do grupo dela; o shader a faz esvoaçar numa volta própria, virada para onde vai, subindo e descendo, e bater as
// asas (a dobra em volta do corpo, pela distância de x), tudo no tempo visual (para na pausa). A cor da asa sai da espécie.
// INSTANCE_CUSTOM: r = fase da volta, g = fase das asas, b = ritmo próprio, a = espécie (0..3 em quartos).
shader_type spatial;
render_mode cull_disabled, shadows_disabled;

global uniform float visual_time;

uniform vec4 white : source_color = vec4(0.95, 0.94, 0.88, 1.0);
uniform vec4 yellow : source_color = vec4(0.95, 0.82, 0.25, 1.0);
uniform vec4 orange : source_color = vec4(0.92, 0.45, 0.12, 1.0);
uniform vec4 blue : source_color = vec4(0.3, 0.48, 0.9, 1.0);
uniform vec4 body : source_color = vec4(0.12, 0.1, 0.08, 1.0);
uniform float wander_m = 1.6;
uniform float bob_m = 0.35;
uniform float flap_hz = 7.0;
// Some com a distância da câmera (o MultiMesh cobre o mundo todo: o alcance de visibilidade não serve).
uniform float fade_end_m = 90.0;

varying vec3 v_wing;
varying float v_body;

vec3 path(float t, float phase, float speed) {
	return vec3(sin(t * 0.43 * speed + phase) + 0.6 * sin(t * 1.1 * speed + phase * 2.3),
			0.5 + 0.5 * sin(t * 0.9 * speed + phase * 1.7),
			cos(t * 0.37 * speed + phase) + 0.6 * cos(t * 0.97 * speed + phase * 1.3));
}

void vertex() {
	float t = visual_time;
	float speed = 0.7 + 0.6 * INSTANCE_CUSTOM.b;
	float phase = INSTANCE_CUSTOM.r * 6.2831853;
	vec3 here = path(t, phase, speed) * vec3(wander_m, bob_m, wander_m);
	vec3 ahead = path(t + 0.15, phase, speed) * vec3(wander_m, bob_m, wander_m);
	vec3 forward = ahead - here;
	forward.y = 0.0;
	forward = length(forward) > 0.0001 ? normalize(forward) : vec3(0.0, 0.0, 1.0);
	vec3 side = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
	// as asas sobem e descem em volta do corpo: a parte de fora gira mais (o x é a distância do corpo)
	float flap = 0.75 * sin(t * flap_hz * 6.2831853 * (0.85 + 0.3 * INSTANCE_CUSTOM.b) + INSTANCE_CUSTOM.g * 6.2831853) + 0.35;
	vec3 local = VERTEX;
	float out_m = abs(local.x);
	local.y += out_m * sin(flap);
	local.x = sign(local.x) * out_m * cos(flap);
	VERTEX = here + side * local.x + vec3(0.0, local.y, 0.0) + forward * local.z;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float distance_m = length(world - INV_VIEW_MATRIX[3].xyz);
	// o pontinho longe vira nada: encolhe até sumir
	VERTEX = mix(here, VERTEX, 1.0 - smoothstep(fade_end_m * 0.7, fade_end_m, distance_m));
	NORMAL = vec3(0.0, 1.0, 0.0);
	float kind = floor(INSTANCE_CUSTOM.a * 4.0 + 0.5);
	v_wing = kind < 0.5 ? white.rgb : (kind < 1.5 ? yellow.rgb : (kind < 2.5 ? orange.rgb : blue.rgb));
	v_body = step(out_m, 0.012);
}

void fragment() {
	// a borda da asa mais escura
	float edge = smoothstep(0.75, 1.0, UV.x);
	ALBEDO = mix(mix(v_wing, v_wing * 0.35, edge), body.rgb, v_body);
	ROUGHNESS = 0.8;
}
