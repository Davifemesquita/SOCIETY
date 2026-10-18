// Tábua de madeira gasta (Fase 20), gerada no shader: veio ao longo da tábua, o tom de cada uma um pouco
// diferente e, com board_m acima de zero, as frestas escuras entre as tábuas de uma parede de tábuas em pé.
// Tudo em metros da própria peça (o vértice vezes a escala da transformação), então a caixa esticada do
// multimesh tem o veio do mesmo tamanho. Na peça de uma tábua só (board_m = 0) o tom sai do INSTANCE_ID.
shader_type spatial;
render_mode cull_back;

#include "res://shaders/wet_surface.gdshaderinc"

uniform vec4 albedo : source_color = vec4(0.5, 0.38, 0.26, 1.0);
// largura da tábua na parede (0 = a peça é uma tábua) e a fresta (fração da tábua)
uniform float board_m = 0.0;
uniform float gap = 0.08;
// no tampo, o veio corre em z (true) ou em x
uniform bool top_along_z = false;
// largura do veio e quanto ele escurece; quanto o tom varia de tábua para tábua
uniform float grain_m = 0.025;
uniform float grain = 0.22;
uniform float spread = 0.22;

varying vec3 local_m;
varying vec3 local_normal;
varying flat int piece;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	local_m = VERTEX * scale;
	local_normal = abs(NORMAL);
	piece = INSTANCE_ID;
}

void fragment() {
	// across: de tábua para tábua; along: ao longo do veio
	float across;
	float along;
	if (local_normal.y > 0.5) {
		across = top_along_z ? local_m.x : local_m.z;
		along = top_along_z ? local_m.z : local_m.x;
	} else {
		across = local_normal.x > local_normal.z ? local_m.z : local_m.x;
		along = local_m.y;
	}
	float board = board_m > 0.0 ? floor(across / board_m) : float(piece);
	float tone = 1.0 + (hash(vec2(board, 7.0)) - 0.5) * spread * 2.0;
	float streak = value_noise(vec2(across / grain_m + board * 13.0, along * 1.5));
	float fine = value_noise(vec2(across / (grain_m * 0.35), along * 4.0 + board));
	vec3 color = albedo.rgb * tone * (1.0 - grain * (0.6 * streak + 0.4 * fine));
	float roughness = 0.82 + 0.15 * streak;
	if (board_m > 0.0) {
		float f = fract(across / board_m);
		float seam = smoothstep(0.0, gap, f) * smoothstep(0.0, gap, 1.0 - f);
		color *= mix(0.3, 1.0, seam);
		roughness = mix(1.0, roughness, seam);
	}
	ALBEDO = wet_albedo(color, 1.0);
	ROUGHNESS = wet_roughness(roughness, 1.0);
}
