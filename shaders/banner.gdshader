// Fase 205: o estandarte pendurado na fachada. A malha tem o alto do pano em y = 0 (o braço de ferro fica acima, parado) e o
// pano descendo em −y; o shader o balança para fora e para dentro da fachada (no máximo ~0,3 m embaixo, menos que o braço:
// o pano nunca entra na parede), mais embaixo que em cima, com uma onda pelo comprido, mais forte com o vento (os globais da
// Fase 22), no tempo visual (para na pausa).
// COLOR: rgb = a cor fixa (o ferro, o galão dourado), a = 1 onde o pano leva a cor da instância (INSTANCE_CUSTOM.rgb, em sRGB);
// INSTANCE_CUSTOM.a = a fase do balanço.
shader_type spatial;
render_mode cull_disabled;

global uniform float visual_time;
global uniform float wind_strength;

uniform float sway_m = 0.03;
uniform float wind_sway_m = 0.1;

varying vec3 v_field;

void vertex() {
	float down = max(-VERTEX.y, 0.0);
	float phase = INSTANCE_CUSTOM.a * 6.2831853;
	float t = visual_time * (1.1 + 0.9 * wind_strength) + phase;
	float amount = (sway_m + wind_sway_m * wind_strength) * down;
	VERTEX.z += amount * (0.6 * sin(t) + 0.4 * sin(t * 2.3 + down * 2.0));
	v_field = INSTANCE_CUSTOM.rgb;
}

void fragment() {
	vec3 fixed = pow(COLOR.rgb, vec3(2.2));
	vec3 field = pow(v_field, vec3(2.2));
	ALBEDO = mix(fixed, field, COLOR.a);
	ROUGHNESS = 0.85;
}
