// Animais da cidade viva (Fase 13): malha do VatModel animada pelas texturas de posição e de normal,
// como os pedestres, mas sem andar sozinhos (a CPU põe o bicho no lugar: pasto, porta da casa ou a
// frente da carroça). Dado próprio da instância: x = animação, y = fase (0..1), z = ritmo (1 = normal).
// A cor é a do vértice (o material da Quaternius, em sRGB) vezes a cor da instância (variação).
shader_type spatial;
render_mode cull_back;

global uniform float visual_time;

uniform sampler2D vat_positions : filter_nearest, repeat_disable;
uniform sampler2D vat_normals : filter_nearest, repeat_disable;
// Por animação: linha inicial, quadros, quadros por segundo e (sem uso aqui) o passo.
uniform vec4 clips[4];

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	vec4 data = INSTANCE_CUSTOM;
	int clip = clamp(int(data.x + 0.5), 0, 3);
	vec4 info = clips[clip];
	float frames = max(info.y, 1.0);
	float cycle = data.y + visual_time * info.z * max(data.z, 0.0) / frames;
	float frame = fract(cycle) * frames;
	int f0 = int(frame);
	int f1 = (f0 + 1) % int(frames);
	float blend = frame - float(f0);
	ivec2 a = ivec2(int(UV2.x + 0.5), int(info.x) + f0);
	ivec2 b = ivec2(a.x, int(info.x) + f1);
	VERTEX = mix(texelFetch(vat_positions, a, 0).xyz, texelFetch(vat_positions, b, 0).xyz, blend);
	NORMAL = normalize(mix(texelFetch(vat_normals, a, 0).xyz, texelFetch(vat_normals, b, 0).xyz, blend) * 2.0 - 1.0);
}

void fragment() {
	ALBEDO = srgb_to_linear(COLOR.rgb);
	ROUGHNESS = 0.9;
}
