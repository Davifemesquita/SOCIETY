// Fase 290: os estratos da rocha, divididos pelo terrain.gdshader e pelo sea_rock.gdshader. Camadas quase horizontais de
// strata_m de altura, onduladas pelo ruído ao longo da costa (não fatias retas), cada uma com a borda de cima mais clara (o
// ressalto que pega luz) e a de baixo na sombra; e sulcos descendo pela encosta (o ruído esticado ao longo da inclinação). Tudo
// em fator de cor (1 = nada), pela altura e pelo lugar no mundo: a rocha do terreno e as pedras soltas batem nas mesmas camadas.

uniform float strata_m = 1.15;
uniform float strata_warp_m = 0.5;
uniform float strata_light = 0.32;
uniform float strata_shade = 0.38;
uniform float gully_strength = 0.18;

float strata_hash(vec2 p) {
	uvec2 q = uvec2(ivec2(floor(p)));
	uint h = q.x * 1597334677u ^ q.y * 3812015801u;
	h ^= h >> 16u;
	h *= 2654435769u;
	return float(h >> 8u) / 16777216.0;
}

float strata_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(strata_hash(i), strata_hash(i + vec2(1.0, 0.0)), f.x),
			mix(strata_hash(i + vec2(0.0, 1.0)), strata_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// O fator de cor dos estratos no ponto do mundo com a normal dada (só na face inclinada: steep de 0 na plana a 1 na de pé).
float strata_factor(vec3 at, vec3 normal_w) {
	float steep = 1.0 - smoothstep(0.55, 0.9, normal_w.y);
	if (steep <= 0.0) {
		return 1.0;
	}
	float warp = (strata_noise(at.xz * 0.07) - 0.5) * 2.0 * strata_warp_m
			+ (strata_noise(at.xz * 0.31) - 0.5) * strata_warp_m * 0.5;
	float layer = fract((at.y + warp) / strata_m);
	// em cima da camada (layer perto de 1) a borda clara; logo embaixo (perto de 0) a sombra
	float lip = smoothstep(0.78, 0.97, layer) * (1.0 - smoothstep(0.97, 1.0, layer));
	float under = 1.0 - smoothstep(0.0, 0.22, layer);
	// os sulcos: o ruído esticado ao longo da descida (a direção da normal no plano), estreito de través
	vec2 down = normalize(normal_w.xz + vec2(1e-4, 0.0));
	vec2 across = vec2(-down.y, down.x);
	float along_m = dot(at.xz, down) - at.y;
	float gully = smoothstep(0.62, 0.8, strata_noise(vec2(dot(at.xz, across) * 0.9, along_m * 0.12)));
	float factor = 1.0 + lip * strata_light - under * strata_shade - gully * gully_strength;
	return mix(1.0, factor, steep);
}
