shader_type spatial;
// Vidro do poste e chama da fogueira (Fase 13): acendem com a noite (global night_light, o mesmo das
// janelas). A chama (COLOR.a = 1) tremula e encolhe até sumir de dia; o vidro (COLOR.a = 0) só apaga.
render_mode unshaded, cull_disabled;

global uniform float night_light;
uniform vec4 day_color : source_color = vec4(0.25, 0.24, 0.22, 1.0);
// a chama passa de 1,5 e satura em branco; o vidro aguenta mais
uniform float glass_energy = 2.2;
uniform float flame_energy = 1.3;

varying float flame;

void vertex() {
	flame = COLOR.a;
	if (flame > 0.5) {
		float seed = NODE_POSITION_WORLD.x * 1.7 + NODE_POSITION_WORLD.z * 2.3;
		float flicker = 0.85 + 0.15 * sin(TIME * 9.0 + seed) * sin(TIME * 5.3 + seed * 1.9);
		VERTEX.y *= smoothstep(0.0, 0.4, night_light) * flicker;
		VERTEX.xz *= 0.9 + 0.1 * flicker;
	}
}

void fragment() {
	// a cor da instância chega em sRGB
	vec3 lit = pow(COLOR.rgb, vec3(2.2)) * (flame > 0.5 ? flame_energy : glass_energy);
	ALBEDO = mix(day_color.rgb, lit, smoothstep(0.05, 0.5, night_light));
}
