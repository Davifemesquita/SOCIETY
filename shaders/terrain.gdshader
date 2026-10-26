// Terreno das ilhas (seção 7): grama no plano e rocha na encosta (pela inclinação), areia na praia
// e no fundo do mar, chão de floresta onde há árvores. O tipo de chão vem de uma textura por
// região (surface_weights: r = areia, g = floresta, b = lama), de 2 em 2 m, filtrada (transição
// suave). A lama (Fase 19) cobre o leito e a margem do rio: terra escura, úmida e lisa, com a borda
// recortada pela altura da textura de grama; na praia, a areia fica molhada junto da água.
// Texturas da Poly Haven (CC0) empacotadas: cor + altura (a) e normal OpenGL + aspereza (a).
//
// Fase 34 (chão sem xadrez), sem mudar nenhuma altura:
// - as bordas de areia, floresta e lama passam por um ruído de 2 e 4 m e se misturam pela altura do alfa de cada
//   textura (height-blend), no lugar do degradê linear que desenhava losangos de 2 m;
// - macro-variação em 40, 150 e 500 m e as texturas de dados do TerrainBake (terrain_data: inclinação, curvatura,
//   distância da água, umidade): grama mais seca nas cristas, mais verde perto da água, terra úmida nos vales;
// - hex-tiling na grama e na floresta perto da câmera (implementação própria pelo artigo de Mikkelsen, "Practical
//   Real-Time Hex-Tiling", JCGT 11(3), 2022), com o normal map girado junto;
// - triplanar na rocha, só onde a encosta pede.
shader_type spatial;
render_mode cull_back;

#include "res://shaders/wet_surface.gdshaderinc"

uniform sampler2D grass_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D forest_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D forest_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_weights : filter_linear, repeat_disable;
// Fase 34: r inclinação, g curvatura (acima de 0,5 é vale), b distância da água, a umidade
uniform sampler2D terrain_data : filter_linear, repeat_disable;
// canto da região no mundo (x, z) e o tamanho dela, em metros
uniform vec4 region_bounds = vec4(0.0, 0.0, 512.0, 512.0);
// metros por repetição da textura
uniform float texture_meters = 12.0;
// a rocha aparece quando a normal fica abaixo disto (1 = plano)
uniform float rock_start = 0.86;
uniform float rock_full = 0.7;
// cor da lama sobre a textura de areia, e até que altura a areia da praia fica molhada
uniform vec3 mud_tint = vec3(0.27, 0.19, 0.11);
uniform float wet_sand_m = 0.9;
// Fase 34: hex-tiling (pelo nível gráfico) e até onde da câmera ele vale
uniform bool hex_tiling = true;
uniform float hex_distance_m = 220.0;
// quanto o ruído de 2 e 4 m mexe nas bordas, e a largura da faixa do height-blend
uniform float edge_noise = 0.55;
uniform float blend_depth = 0.25;
// claro e escuro da macro-variação, e a força da grama seca e da verde
uniform vec2 macro_range = vec2(0.76, 1.14);
// de longe a textura se mistura com ela mesma 8x maior e o relevo fino aplaina: a repetição de 12 m some do alto
uniform vec2 far_blend_m = vec2(60.0, 320.0);
uniform float far_scale = 0.125;
uniform float far_mix = 0.65;
// cada efeito da Fase 34 pode ser desligado (medida de custo: tools/terrain_cost.tscn)
uniform bool use_edge_noise = true;
uniform bool use_macro = true;
uniform bool use_far = true;
uniform bool use_triplanar = true;
uniform vec3 dry_tint = vec3(1.1, 1.0, 0.72);
uniform vec3 lush_tint = vec3(0.9, 1.04, 0.86);

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
	return vec2(hash21(p), hash21(p + vec2(17.13, 3.71)));
}

// ruído de valor suave, 0..1
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

// peso da camada b sobre a: a mais alta das duas (altura do alfa + peso) ganha, numa faixa de blend_depth
float height_blend(float weight, float height_a, float height_b) {
	float a = height_a + 1.0 - weight;
	float b = height_b + weight;
	float top = max(a, b) - blend_depth;
	float wa = max(a - top, 0.0);
	float wb = max(b - top, 0.0);
	return wb / (wa + wb + 0.00001);
}

// Hex-tiling: a grade de triângulos do artigo de Mikkelsen. Cada vértice da grade tem um deslocamento e uma rotação
// sorteados; o pixel mistura as três amostras dos vértices do triângulo em que cai, com contraste nos pesos.
void hex_lattice(vec2 uv, out vec2 uv1, out vec2 uv2, out vec2 uv3, out mat2 r1, out mat2 r2, out mat2 r3, out vec3 w) {
	const float SCALE = 3.4641016;
	vec2 skewed = mat2(vec2(1.0, -0.57735027), vec2(0.0, 1.15470054)) * (uv * SCALE);
	vec2 base = floor(skewed);
	vec3 t = vec3(fract(skewed), 0.0);
	t.z = 1.0 - t.x - t.y;
	float s = step(0.0, -t.z);
	float s2 = 2.0 * s - 1.0;
	w = vec3(-t.z * s2, s - t.y * s2, s - t.x * s2);
	vec2 v1 = base + vec2(s, s);
	vec2 v2 = base + vec2(s, 1.0 - s);
	vec2 v3 = base + vec2(1.0 - s, s);
	mat2 unskew = mat2(vec2(1.0, 0.5), vec2(0.0, 0.8660254));
	vec2 c1 = unskew * v1 / SCALE;
	vec2 c2 = unskew * v2 / SCALE;
	vec2 c3 = unskew * v3 / SCALE;
	float a1 = hash21(v1) * 6.2831853;
	float a2 = hash21(v2) * 6.2831853;
	float a3 = hash21(v3) * 6.2831853;
	r1 = mat2(vec2(cos(a1), sin(a1)), vec2(-sin(a1), cos(a1)));
	r2 = mat2(vec2(cos(a2), sin(a2)), vec2(-sin(a2), cos(a2)));
	r3 = mat2(vec2(cos(a3), sin(a3)), vec2(-sin(a3), cos(a3)));
	uv1 = r1 * (uv - c1) + c1 + hash22(v1);
	uv2 = r2 * (uv - c2) + c2 + hash22(v2);
	uv3 = r3 * (uv - c3) + c3 + hash22(v3);
	w = pow(w, vec3(7.0));
	w /= (w.x + w.y + w.z);
}

// normal map (0..1) amostrado num referencial girado por r: o xy volta para o referencial da textura sem giro
vec3 unrotate_normal(vec3 sampled, mat2 r) {
	vec2 xy = transpose(r) * (sampled.xy * 2.0 - 1.0);
	return vec3(xy * 0.5 + 0.5, sampled.z);
}

void fragment() {
	vec2 uv = world_position.xz / texture_meters;
	vec2 cell = (world_position.xz - region_bounds.xy) / region_bounds.zw;
	vec4 kinds = texture(surface_weights, cell);
	vec4 data = texture(terrain_data, cell);
	float rock = smoothstep(rock_start, rock_full, world_normal.y);
	float edge = 0.0;
	if (use_edge_noise) {
		edge = (value_noise(world_position.xz * 0.5) * 0.6 + value_noise(world_position.xz * 0.25) * 0.4 - 0.5) * edge_noise;
	}

	vec4 grass_a = texture(grass_albedo, uv);
	vec4 grass_n = texture(grass_normal, uv);
	vec4 forest_a = texture(forest_albedo, uv);
	vec4 forest_n = texture(forest_normal, uv);
	float camera_distance = distance(CAMERA_POSITION_WORLD, world_position);
	float hex = hex_tiling ? 1.0 - smoothstep(hex_distance_m * 0.8, hex_distance_m, camera_distance) : 0.0;
	if (hex > 0.001) {
		vec2 uv1; vec2 uv2; vec2 uv3; mat2 r1; mat2 r2; mat2 r3; vec3 w;
		hex_lattice(uv, uv1, uv2, uv3, r1, r2, r3, w);
		vec2 dx = dFdx(uv);
		vec2 dy = dFdy(uv);
		vec4 hg = textureGrad(grass_albedo, uv1, r1 * dx, r1 * dy) * w.x + textureGrad(grass_albedo, uv2, r2 * dx, r2 * dy) * w.y
				+ textureGrad(grass_albedo, uv3, r3 * dx, r3 * dy) * w.z;
		vec4 hf = textureGrad(forest_albedo, uv1, r1 * dx, r1 * dy) * w.x + textureGrad(forest_albedo, uv2, r2 * dx, r2 * dy) * w.y
				+ textureGrad(forest_albedo, uv3, r3 * dx, r3 * dy) * w.z;
		vec4 n1 = textureGrad(grass_normal, uv1, r1 * dx, r1 * dy);
		vec4 n2 = textureGrad(grass_normal, uv2, r2 * dx, r2 * dy);
		vec4 n3 = textureGrad(grass_normal, uv3, r3 * dx, r3 * dy);
		vec4 hgn = vec4(unrotate_normal(n1.rgb, r1) * w.x + unrotate_normal(n2.rgb, r2) * w.y + unrotate_normal(n3.rgb, r3) * w.z,
				n1.a * w.x + n2.a * w.y + n3.a * w.z);
		n1 = textureGrad(forest_normal, uv1, r1 * dx, r1 * dy);
		n2 = textureGrad(forest_normal, uv2, r2 * dx, r2 * dy);
		n3 = textureGrad(forest_normal, uv3, r3 * dx, r3 * dy);
		vec4 hfn = vec4(unrotate_normal(n1.rgb, r1) * w.x + unrotate_normal(n2.rgb, r2) * w.y + unrotate_normal(n3.rgb, r3) * w.z,
				n1.a * w.x + n2.a * w.y + n3.a * w.z);
		grass_a = mix(grass_a, hg, hex);
		forest_a = mix(forest_a, hf, hex);
		grass_n = mix(grass_n, hgn, hex);
		forest_n = mix(forest_n, hfn, hex);
	}
	float far = use_far ? smoothstep(far_blend_m.x, far_blend_m.y, camera_distance) * far_mix : 0.0;
	vec4 sand_a = texture(sand_albedo, uv);
	vec4 sand_n = texture(sand_normal, uv);
	if (far > 0.001) {
		vec2 far_uv = uv * far_scale;
		grass_a.rgb = mix(grass_a.rgb, texture(grass_albedo, far_uv).rgb, far);
		forest_a.rgb = mix(forest_a.rgb, texture(forest_albedo, far_uv).rgb, far);
		sand_a.rgb = mix(sand_a.rgb, texture(sand_albedo, far_uv).rgb, far);
		vec3 flat_normal = vec3(0.5, 0.5, 1.0);
		grass_n.rgb = mix(grass_n.rgb, flat_normal, far);
		forest_n.rgb = mix(forest_n.rgb, flat_normal, far);
		sand_n.rgb = mix(sand_n.rgb, flat_normal, far);
	}

	// grama seca nas cristas e onde o ruído de 150 m pede, mais verde perto da água
	float macro_mid = use_macro ? value_noise(world_position.xz / 150.0) : 0.5;
	float dry = clamp((macro_mid - 0.4) * 1.4 + (0.5 - data.g) * 2.0 + (0.6 - data.a) * 0.5, 0.0, 1.0);
	grass_a.rgb *= mix(vec3(1.0), dry_tint, dry * 0.65);
	grass_a.rgb *= mix(vec3(1.0), lush_tint, data.a * 0.6);

	// rocha: triplanar só na encosta (na plana o peso dela é zero e nada é lido)
	vec4 rock_a = vec4(0.0);
	vec4 rock_n = vec4(0.5, 0.5, 1.0, 1.0);
	if (rock > 0.001 && !use_triplanar) {
		rock_a = texture(rock_albedo, uv * 0.7);
		rock_n = texture(rock_normal, uv * 0.7);
	} else if (rock > 0.001) {
		vec3 blend = pow(abs(world_normal), vec3(4.0));
		blend /= (blend.x + blend.y + blend.z);
		vec3 p = world_position / texture_meters * 0.7;
		rock_a = texture(rock_albedo, p.zy) * blend.x + texture(rock_albedo, p.xz) * blend.y + texture(rock_albedo, p.xy) * blend.z;
		rock_n = texture(rock_normal, p.zy) * blend.x + texture(rock_normal, p.xz) * blend.y + texture(rock_normal, p.xy) * blend.z;
	}

	// bordas com ruído e height-blend
	float ragged = texture(rock_albedo, uv * 0.23).a - 0.5;
	float mud = smoothstep(0.3, 0.7, kinds.b + ragged * 1.2 + edge * 0.5);
	float sand_raw = max(kinds.r, step(world_position.y, 0.4));
	float forest = height_blend(smoothstep(0.2, 0.8, kinds.g + edge), grass_a.a, forest_a.a);
	vec4 ground_a = mix(grass_a, forest_a, forest);
	vec4 ground_n = mix(grass_n, forest_n, forest);
	float sand = height_blend(smoothstep(0.2, 0.8, sand_raw + edge), ground_a.a, sand_a.a) * (1.0 - mud);
	forest *= (1.0 - sand) * (1.0 - mud);
	ground_a = mix(ground_a, rock_a, rock * (1.0 - sand));
	ground_n = mix(ground_n, rock_n, rock * (1.0 - sand));
	ground_a = mix(ground_a, sand_a, sand);
	ground_n = mix(ground_n, sand_n, sand);
	vec4 mud_a = vec4(sand_a.rgb * mud_tint * 1.6, sand_a.a);
	ground_a = mix(ground_a, mud_a, mud * (1.0 - rock));
	// lama alisada: o relevo da areia some quase todo
	ground_n = mix(ground_n, vec4(mix(sand_n.rgb, vec3(0.5, 0.5, 1.0), 0.75), 0.3), mud * (1.0 - rock));

	// terra úmida nos vales e macro-variação de claro e escuro (40, 150 e 500 m), só acima do mar
	float land = step(0.0, world_position.y);
	float valley = clamp((data.g - 0.55) * 4.0, 0.0, 1.0) * data.a * (1.0 - sand);
	ground_a.rgb *= mix(1.0, 0.82, valley * land);
	if (use_macro) {
		float macro = value_noise(world_position.xz / 40.0) * 0.25 + macro_mid * 0.4 + value_noise(world_position.xz / 500.0) * 0.35;
		ground_a.rgb *= mix(1.0, mix(macro_range.x, macro_range.y, macro), land);
	}

	// areia molhada na beira d'água (só a da praia, acima do mar)
	float wet_line = sand * (1.0 - smoothstep(0.0, wet_sand_m, world_position.y)) * land;
	ground_a.rgb *= mix(1.0, 0.62, wet_line);
	ground_n.a *= mix(1.0, 0.45, wet_line);
	// o fundo do mar não molha (já está debaixo d'água)
	ALBEDO = wet_albedo(ground_a.rgb, land);
	NORMAL_MAP = ground_n.rgb;
	ROUGHNESS = wet_roughness(ground_n.a, land);
}
