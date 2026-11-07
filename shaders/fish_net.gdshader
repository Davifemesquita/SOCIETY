// Rede de pesca (Fase 139): a malha recortada pela UV, que vem em metros da rede: fios de mesh_m em losango, um pouco
// tortos pelo ruído, o resto vazado (alpha scissor). A cor da rede vem do vértice (sRGB).
shader_type spatial;
render_mode cull_disabled;

uniform float mesh_m = 0.075;
uniform float thread = 0.16;

float net_hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

void fragment() {
	// losangos: as duas diagonais da UV
	vec2 d = vec2(UV.x + UV.y, UV.x - UV.y) / mesh_m;
	vec2 wobble = vec2(net_hash(floor(d)), net_hash(floor(d) + 7.0)) * 0.12;
	vec2 f = abs(fract(d + wobble) - 0.5);
	float line = step(0.5 - thread, max(f.x, f.y));
	vec3 color = COLOR.rgb;
	ALBEDO = mix(pow((color + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), color * (1.0 / 12.92), lessThan(color, vec3(0.04045)));
	ROUGHNESS = 0.95;
	ALPHA = line;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
