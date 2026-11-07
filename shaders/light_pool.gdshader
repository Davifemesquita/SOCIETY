// Poça de luz no chão (Fase 119): um disco somado à cena debaixo de cada poste, fogueira e porta de casa acesa, mais forte
// no meio e somindo até a borda, na cor da instância (que chega em sRGB); acende com a noite (global night_light). Não
// escreve profundidade e não faz sombra: é só a luz que o lampião deixaria no chão, sem luz de verdade.
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

global uniform float night_light;
uniform float strength = 0.5;

void fragment() {
	float d = length(UV * 2.0 - 1.0);
	float fall = 1.0 - smoothstep(0.0, 1.0, d);
	fall *= fall;
	vec3 color = pow(COLOR.rgb, vec3(2.2));
	ALBEDO = color * fall * strength * COLOR.a * smoothstep(0.05, 0.6, night_light);
}
