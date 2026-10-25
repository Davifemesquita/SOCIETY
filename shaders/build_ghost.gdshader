// Prévia da ferramenta de construção (Fase 33): o fantasma do prédio, translúcido, com a borda clara pelo ângulo
// (contorno sem stencil). Onde não pode (e na demolição) leva listras diagonais: nada depende só da cor.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, blend_mix, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.35, 0.9, 0.4, 0.45);
uniform bool striped = false;
uniform float stripe_m = 0.6;
uniform float rim_strength = 0.6;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0) * rim_strength;
	float alpha = tint.a;
	if (striped) {
		float band = fract((world_position.x + world_position.y + world_position.z) / (stripe_m * 2.0));
		alpha *= band < 0.5 ? 1.35 : 0.35;
	}
	ALBEDO = mix(tint.rgb, vec3(1.0), rim);
	ALPHA = clamp(alpha + rim * 0.5, 0.0, 1.0);
}
