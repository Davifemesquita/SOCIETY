// Janelas dos prédios (seção 11: janelas acesas à noite). De dia, vidro escuro; ao anoitecer, cada
// janela acende num ponto diferente da transição (dado próprio x = limiar, 0 a 1) e só se o prédio
// está aceso (y = 1: casa com morador, produção trabalhando, serviço aberto). z: o arco do alto (Fase 369).
shader_type spatial;
render_mode cull_back;

global uniform float night_light;

uniform vec3 glass_color : source_color = vec3(0.08, 0.09, 0.11);
uniform vec3 light_color : source_color = vec3(1.0, 0.72, 0.38);
uniform float light_energy = 2.2;

varying flat vec4 data;

void vertex() {
	data = INSTANCE_CUSTOM;
}

void fragment() {
	// Fase 369: a janela de volta redonda (z = quanto do alto do vidro é arco) não acende os cantos de cima
	if (data.z > 0.001 && UV.y < data.z) {
		vec2 arch = vec2((UV.x - 0.5) * 2.0, (data.z - UV.y) / data.z);
		if (dot(arch, arch) > 1.0) {
			discard;
		}
	}
	// a última janela acende quando a noite chega a 90%; a primeira, logo no começo do anoitecer
	// 15% das janelas ficam apagadas a noite toda (cômodo vazio)
	float on = data.y * step(data.x * 0.75 + 0.12, night_light) * step(data.x, 0.85);
	ALBEDO = glass_color;
	ROUGHNESS = 0.25;
	EMISSION = light_color * light_energy * on;
}
