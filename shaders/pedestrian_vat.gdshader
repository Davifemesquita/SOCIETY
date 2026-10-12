// Pedestre da multidão (seção 9): malha do VatModel animada pelas texturas de posição e de normal
// (uma linha por quadro, uma coluna por vértice) e andando sozinho pelo trecho reto atual.
// Dado próprio da instância: x = início do trecho (tempo visual), y = comprimento do trecho,
// z = velocidade (0 = parado), w = animação + fase. Cor da instância: roupa de cima (rgb) e
// semente (a) para a pele e o cabelo. A CPU só mexe na instância quando o trecho muda.
shader_type spatial;
render_mode cull_back;

global uniform float visual_time;

uniform sampler2D vat_positions : filter_nearest, repeat_disable;
uniform sampler2D vat_normals : filter_nearest, repeat_disable;
// Por animação: linha inicial, quadros, quadros por segundo, passo (m por ciclo; 0 = parada).
uniform vec4 clips[4];
uniform vec3 trousers_color : source_color = vec3(0.25, 0.22, 0.2);
uniform vec3 shoes_color : source_color = vec3(0.12, 0.08, 0.06);
uniform vec3 skin_a : source_color = vec3(0.93, 0.76, 0.62);
uniform vec3 skin_b : source_color = vec3(0.8, 0.6, 0.45);
uniform vec3 skin_c : source_color = vec3(0.55, 0.38, 0.27);
uniform vec3 hair_a : source_color = vec3(0.12, 0.09, 0.07);
uniform vec3 hair_b : source_color = vec3(0.3, 0.2, 0.12);
uniform vec3 hair_c : source_color = vec3(0.55, 0.42, 0.25);
uniform vec3 hair_d : source_color = vec3(0.5, 0.48, 0.45);

varying flat float region;
varying flat vec4 outfit;

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	vec4 data = INSTANCE_CUSTOM;
	float elapsed = max(visual_time - data.x, 0.0);
	float dist = min(elapsed * data.z, data.y);
	int clip = clamp(int(data.w), 0, 3);
	vec4 info = clips[clip];
	float frames = max(info.y, 1.0);
	float cycle = info.w > 0.0 ? fract(data.w) + dist / info.w : fract(data.w) + elapsed * info.z / frames;
	float frame = fract(cycle) * frames;
	int f0 = int(frame);
	int f1 = (f0 + 1) % int(frames);
	float blend = frame - float(f0);
	ivec2 a = ivec2(int(UV2.x + 0.5), int(info.x) + f0);
	ivec2 b = ivec2(a.x, int(info.x) + f1);
	VERTEX = mix(texelFetch(vat_positions, a, 0).xyz, texelFetch(vat_positions, b, 0).xyz, blend);
	NORMAL = normalize(mix(texelFetch(vat_normals, a, 0).xyz, texelFetch(vat_normals, b, 0).xyz, blend) * 2.0 - 1.0);
	VERTEX.z -= dist;
	region = UV.x;
	outfit = COLOR;
}

void fragment() {
	int part = int(region + 0.5);
	float seed = outfit.a;
	vec3 color = srgb_to_linear(outfit.rgb);
	if (part == 0) {
		color = seed < 0.4 ? skin_a : (seed < 0.8 ? skin_b : skin_c);
	} else if (part == 1) {
		float pick = fract(seed * 7.31);
		color = pick < 0.35 ? hair_a : (pick < 0.7 ? hair_b : (pick < 0.88 ? hair_c : hair_d));
	} else if (part == 3) {
		color = trousers_color;
	} else if (part == 4) {
		color = shoes_color;
	}
	ALBEDO = color;
	ROUGHNESS = 0.85;
}
