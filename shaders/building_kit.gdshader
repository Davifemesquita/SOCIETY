// Prédios de modelo (peças do Kenney Fantasy Town Kit, CC0): a cor vem da paleta do kit pela UV, e
// os pedaços que são parede ou telhado (reconhecidos pela célula da paleta) ganham a textura PBR
// projetada no mundo, no tom do prédio, como as caixas de antes (building.gdshader). Madeiramento,
// janelas e porta ficam nas cores do kit. Sujeira na base, fuligem e chuva valem para tudo.
shader_type spatial;
render_mode cull_back;

#include "res://shaders/wet_surface.gdshaderinc"

uniform sampler2D colormap : source_color, filter_nearest_mipmap, repeat_disable;
uniform sampler2DArray wall_albedo_rough : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray wall_normals : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray roof_albedo_rough : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray roof_normals : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float wall_meters = 3.0;
uniform float roof_meters = 2.5;
uniform float tint_strength = 0.55;
uniform float grime_height = 1.4;
uniform float grime_strength = 0.35;
uniform float trim_desaturate = 0.3;
uniform float trim_darken = 0.85;
uniform vec4 trim_wood : source_color = vec4(0.36, 0.25, 0.17, 1.0);
// folhagem da sebe e da floreira (célula (3, 3), Fase 13): o turquesa do kit vira verde, com flores
uniform vec4 foliage : source_color = vec4(0.2, 0.34, 0.14, 1.0);
uniform float flower_share = 0.22;

instance uniform vec4 tint : source_color = vec4(1.0);
instance uniform float layer = 0.0;
instance uniform vec4 roof_tint : source_color = vec4(0.5, 0.3, 0.25, 1.0);
instance uniform float roof_layer = 0.0;
instance uniform float base_height = 0.0;
instance uniform float soot = 0.0;
// Fase 39: caixilho e madeiramento pintados de claro (a paleta "invertida") e a sombra de contato de cada fachada do
// referencial canônico (frente −Z, +X, fundo +Z, −X), de 0 a 1 pela parte da divisa ocupada por prédio vizinho
instance uniform float trim_paint = 0.0;
instance uniform vec4 side_shade = vec4(0.0);

// Fase 39: vidro (célula (0, 1), que o kit não usa): escuro, liso, com o céu refletido no ângulo raso
uniform vec4 glass_color : source_color = vec4(0.17, 0.21, 0.25, 1.0);
uniform vec4 glass_sky : source_color = vec4(0.62, 0.72, 0.82, 1.0);
uniform vec4 trim_paint_color : source_color = vec4(0.86, 0.83, 0.74, 1.0);
uniform float contact_height = 2.4;
uniform float contact_strength = 0.4;
// musgo e limo na faixa de baixo das paredes e do alicerce, em manchas pelo ruído
uniform vec4 moss_color : source_color = vec4(0.27, 0.31, 0.16, 1.0);
uniform float moss_height = 0.9;
uniform float moss_strength = 0.45;

// Fase 95: as telhas nas águas do telhado (célula (0, 3); a capa da cumeeira e o beiral, na (1, 3), ficam lisos):
// fileiras de tile_row_m ao longo da água, telhas de tile_width_m desencontradas fileira a fileira, a borda de baixo
// arredondada com a sombra embaixo, a junta entre as telhas e um tom por telha; some de tile_fade_far / 2 a tile_fade_far
// (de longe as linhas cintilavam)
uniform float tile_row_m = 0.34;
uniform float tile_width_m = 0.27;
uniform float tile_strength = 0.38;
uniform float tile_fade_far = 80.0;

// Fase 97: a pátina do cobre (cúpulas e torreões)
uniform vec4 copper_dark : source_color = vec4(0.22, 0.42, 0.38, 1.0);
uniform vec4 copper_light : source_color = vec4(0.42, 0.66, 0.58, 1.0);
// Fase 101: as cores da lona dos toldos
uniform vec4 awning_red : source_color = vec4(0.62, 0.17, 0.14, 1.0);
uniform vec4 awning_green : source_color = vec4(0.2, 0.4, 0.26, 1.0);
uniform vec4 awning_blue : source_color = vec4(0.2, 0.3, 0.5, 1.0);
uniform vec4 awning_cream : source_color = vec4(0.88, 0.84, 0.72, 1.0);
// Fase 104: o tijolo da chaminé
uniform vec4 brick_dark : source_color = vec4(0.42, 0.18, 0.13, 1.0);
uniform vec4 brick_light : source_color = vec4(0.62, 0.3, 0.21, 1.0);
uniform vec4 brick_mortar : source_color = vec4(0.66, 0.63, 0.57, 1.0);

varying vec3 world_position;
varying vec3 world_normal;
varying float contact;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// a fachada pela normal no referencial do prédio
	contact = 0.0;
	if (abs(NORMAL.y) < 0.5) {
		if (abs(NORMAL.z) >= abs(NORMAL.x)) {
			contact = NORMAL.z < 0.0 ? side_shade.x : side_shade.z;
		} else {
			contact = NORMAL.x > 0.0 ? side_shade.y : side_shade.w;
		}
	}
}

float moss_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453);
	float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
	float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fase 95: quanto a cor da água do telhado escurece no ponto p (normal n), de 0 a 1: a sombra sob a borda redonda de
// cada telha, a junta entre elas, a parte de cima coberta pela fileira de cima e um tom sorteado por telha
float roof_tile_shade(vec3 p, vec3 n) {
	vec2 down = normalize(n.xz);
	vec2 across = vec2(-down.y, down.x);
	// a distância ao longo da água: a do chão dividida pelo cosseno da inclinação (n.y)
	float s = dot(p.xz, down) / max(n.y, 0.2) / tile_row_m;
	float row = floor(s);
	float f = fract(s);
	float c = dot(p.xz, across) / tile_width_m + 0.5 * mod(row, 2.0);
	float cf = fract(c) - 0.5;
	// a borda de baixo arredondada: o meio da telha desce mais que as juntas
	float edge = 0.8 + 0.17 * (1.0 - 4.0 * cf * cf);
	float under = smoothstep(edge - 0.06, edge, f);
	float seam = smoothstep(0.38, 0.5, abs(cf));
	float covered = 1.0 - smoothstep(0.0, 0.35, f);
	float tone = fract(sin(dot(vec2(row, floor(c)), vec2(12.9898, 78.233))) * 43758.5453);
	return clamp(under * 0.9 + seam * 0.45 + covered * 0.25 + (tone - 0.5) * 0.35, 0.0, 1.0);
}

vec4 triplanar(sampler2DArray stack, vec3 position, vec3 weights, float meters, float index) {
	vec3 p = position / meters;
	return texture(stack, vec3(p.zy, index)) * weights.x
			+ texture(stack, vec3(p.xz, index)) * weights.y
			+ texture(stack, vec3(p.xy, index)) * weights.z;
}

void fragment() {
	// célula da paleta: 8 colunas × 4 linhas
	ivec2 cell = ivec2(floor(UV * vec2(8.0, 4.0)));
	bool wall = (cell == ivec2(1, 2)) || (cell == ivec2(5, 3));
	bool roof = cell.y == 3 && cell.x <= 1;
	vec3 weights = pow(abs(world_normal), vec3(4.0));
	weights /= weights.x + weights.y + weights.z;
	vec3 color = texture(colormap, UV).rgb;
	// madeiramento e caixilhos (célula (4, 3)): a paleta do kit é viva demais; vira madeira escura
	// puxada para o tom do prédio. As outras cores do kit (vidro, porta) só perdem um pouco da cor.
	float kit_luma = dot(color, vec3(0.299, 0.587, 0.114));
	bool glass = cell == ivec2(0, 1);
	if (glass) {
		color = glass_color.rgb;
	} else if (cell == ivec2(2, 1)) {
		// Fase 97: cobre velho (célula (2, 1), que o kit não usa): o verde-azulado da pátina, com escorrimentos mais
		// claros e mais escuros descendo pela cúpula e pelo torreão
		float streak = moss_noise(vec2(atan(world_position.z, world_position.x) * 9.0 + world_position.x * 1.3,
				world_position.y * 0.6));
		color = mix(copper_dark.rgb, copper_light.rgb, smoothstep(0.25, 0.85, streak));
	} else if (cell.y == 1 && cell.x >= 3 && cell.x <= 6) {
		// Fase 101: a lona dos toldos (células (3..6, 1), que o kit não usa): três cores de listra e o creme, com a trama
		color = cell.x == 3 ? awning_red.rgb : (cell.x == 4 ? awning_green.rgb
				: (cell.x == 5 ? awning_blue.rgb : awning_cream.rgb));
		color *= 0.9 + 0.2 * moss_noise(world_position.xz * 6.0 + world_position.y * 3.0);
	} else if (cell == ivec2(7, 1)) {
		// Fase 104: o tijolo da chaminé (célula (7, 1), que o kit não usa): fiadas desencontradas pela face, um tom por
		// tijolo e a argamassa clara
		vec2 face = abs(world_normal.y) > 0.7 ? world_position.xz
				: (abs(world_normal.x) > abs(world_normal.z) ? world_position.zy : world_position.xy);
		vec2 course = face / vec2(0.22, 0.075);
		course.x += mod(floor(course.y), 2.0) * 0.5;
		vec2 inside = fract(course);
		float mortar = clamp(step(inside.x, 0.07) + step(inside.y, 0.14), 0.0, 1.0);
		float tone = fract(sin(dot(floor(course), vec2(12.9898, 78.233))) * 43758.5453);
		color = mix(mix(brick_dark.rgb, brick_light.rgb, tone), brick_mortar.rgb, mortar);
	} else if (cell == ivec2(4, 3)) {
		color = kit_luma / 0.55 * mix(mix(trim_wood.rgb, tint.rgb * 0.6, 0.35), trim_paint_color.rgb, trim_paint);
	} else if (cell == ivec2(3, 3)) {
		// um sorteio por bolinha de ~12 cm, pela posição no mundo: folha mais clara ou mais escura, ou flor
		vec3 blob = floor(world_position * 8.0);
		float pick = fract(sin(dot(blob, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
		color = foliage.rgb * (0.75 + 0.5 * fract(pick * 7.13));
		if (pick < flower_share) {
			float hue = fract(pick * 31.7);
			color = hue < 0.35 ? vec3(0.75, 0.12, 0.12) : (hue < 0.6 ? vec3(0.85, 0.7, 0.2)
					: (hue < 0.85 ? vec3(0.8, 0.45, 0.6) : vec3(0.85, 0.85, 0.8)));
		}
	} else {
		color = mix(color, vec3(kit_luma), trim_desaturate) * trim_darken;
	}
	float roughness = cell == ivec2(2, 1) ? 0.5 : 0.85;
	if (wall || roof) {
		vec4 surface = wall
				? triplanar(wall_albedo_rough, world_position, weights, wall_meters, layer)
				: triplanar(roof_albedo_rough, world_position, weights, roof_meters, roof_layer);
		vec3 shade = wall ? tint.rgb : roof_tint.rgb;
		float luma = dot(surface.rgb, vec3(0.299, 0.587, 0.114));
		color = mix(surface.rgb * 1.25, luma / 0.38 * shade, tint_strength);
		roughness = surface.a;
		NORMAL_MAP = wall
				? triplanar(wall_normals, world_position, weights, wall_meters, layer).rgb
				: triplanar(roof_normals, world_position, weights, roof_meters, roof_layer).rgb;
		// Fase 95: as telhas, só nas águas viradas para cima (não na capa, no beiral nem embaixo do telhado)
		if (roof && cell.x == 0 && world_normal.y > 0.25 && world_normal.y < 0.97) {
			float near = 1.0 - smoothstep(tile_fade_far * 0.5, tile_fade_far, length(VERTEX));
			color *= 1.0 - roof_tile_shade(world_position, world_normal) * tile_strength * near;
		}
	}
	float above = world_position.y - base_height;
	if (glass) {
		// de dia o vão não é buraco preto: no ângulo raso o vidro mostra o céu
		float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
		float fresnel = 0.3 + 0.7 * pow(1.0 - facing, 3.0);
		ALBEDO = mix(color, glass_sky.rgb * 0.75, fresnel);
		ROUGHNESS = 0.06;
		SPECULAR = 0.9;
	} else {
		color *= 1.0 - (1.0 - smoothstep(0.0, grime_height, above)) * grime_strength;
		// musgo em manchas na faixa de baixo das paredes viradas para o lado (não no telhado)
		float moss = (1.0 - smoothstep(0.0, moss_height, above)) * smoothstep(0.45, 0.75,
				moss_noise(world_position.xz * 1.7 + world_position.y * 0.9)) * (1.0 - abs(world_normal.y));
		color = mix(color, moss_color.rgb * (0.7 + 0.6 * kit_luma), moss * moss_strength);
		// sombra de contato: a fachada que dá para o prédio vizinho escurece de baixo para cima
		color *= 1.0 - contact * contact_strength * (1.0 - smoothstep(0.0, contact_height, above));
		color *= 1.0 - soot * 0.55;
		float exposure = clamp(world_normal.y * 0.5 + 0.6, 0.0, 1.0);
		ALBEDO = wet_albedo(color, exposure);
		ROUGHNESS = wet_roughness(roughness, exposure);
	}
}
