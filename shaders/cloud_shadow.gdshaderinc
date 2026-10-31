// Sombra das nuvens (Fase 129): manchas grandes e macias que correm pelo chão e pelo mar na direção do vento. Um ruído de
// valor de duas oitavas (CLOUD_SHADOW_CELL_M) deslizado pelo global cloud_offset (que a WeatherView soma com o vento a
// cada quadro: muda de direção sem saltar e para na pausa), cortado pela cobertura do céu (global cloud_cover, 0 a 1): com
// o céu limpo, nada; nublado, metade do chão na sombra. Só de dia (sun_direction.y). Devolve o quanto escurecer (0 a
// CLOUD_SHADOW_MAX).
global uniform float cloud_cover;
global uniform vec2 cloud_offset;

const float CLOUD_SHADOW_CELL_M = 140.0;
const float CLOUD_SHADOW_MAX = 0.45;

float cloud_hash(vec2 p) {
	vec3 q = fract(vec3(mod(p, 1024.0).xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float cloud_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(cloud_hash(i), cloud_hash(i + vec2(1.0, 0.0)), f.x),
			mix(cloud_hash(i + vec2(0.0, 1.0)), cloud_hash(i + vec2(1.0)), f.x), f.y);
}

// sun_up: a altura do sol (sun_direction.y).
float cloud_shadow(vec2 world_xz, float sun_up) {
	if (cloud_cover <= 0.02 || sun_up <= 0.0) {
		return 0.0;
	}
	vec2 p = (world_xz - cloud_offset) / CLOUD_SHADOW_CELL_M;
	float n = cloud_noise(p) * 0.65 + cloud_noise(p * 2.3 + 11.0) * 0.35;
	// com a cobertura cheia, a sombra pega metade do chão; com pouca, só os picos do ruído
	float edge = mix(0.78, 0.45, cloud_cover);
	float shade = smoothstep(edge, edge + 0.12, n);
	return shade * CLOUD_SHADOW_MAX * smoothstep(0.0, 0.15, sun_up);
}
