// Boca do forno (Fase 137): o fogo dentro do arco, mais claro embaixo (UV.y = 0 na soleira, 1 no alto do arco) e lambendo
// para cima pelo tempo, tremulando; aceso com a fábrica produzindo (INSTANCE_CUSTOM.r), mais forte à noite (global
// night_light). Parada, fica só a brasa escura. Sem luz de verdade: a cor passa de 1 e o glow do ambiente a espalha.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

global uniform float night_light;
uniform float day_energy = 1.6;
uniform float night_energy = 3.2;

varying float on;
varying float seed;

void vertex() {
	on = INSTANCE_CUSTOM.r;
	seed = float(INSTANCE_ID) * 1.618;
}

void fragment() {
	float flicker = 0.82 + 0.18 * sin(TIME * 7.3 + seed) * sin(TIME * 3.1 + seed * 2.3);
	float lick = 0.5 + 0.5 * sin(UV.x * 13.0 + TIME * 4.6 + seed) * sin(UV.x * 5.0 - TIME * 2.2);
	float heat = clamp(1.15 - UV.y * (0.9 + 0.5 * lick), 0.0, 1.0);
	vec3 hot = mix(vec3(0.45, 0.06, 0.01), vec3(1.0, 0.66, 0.22), heat * heat);
	vec3 ember = vec3(0.1, 0.025, 0.01) * (0.8 + 0.2 * lick);
	float energy = mix(day_energy, night_energy, night_light);
	ALBEDO = mix(ember, hot * flicker * energy, on);
}
