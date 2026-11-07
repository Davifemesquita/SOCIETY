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
// Fase 258: a tinta da instância pesa mais que a textura cinza (antes 0,55: o reboco saía cinza-frio)
uniform float tint_strength = 0.68;
// Fase 258: no telhado a tinta pesa ainda mais: telha vermelha misturada com o cinza da textura saía rosa-empoeirado
uniform float roof_tint_strength = 0.85;
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
// Fase 130: o telhado de sapê (as casas dos camponeses), no lugar das telhas da Fase 95
instance uniform float thatch = 0.0;
// Fase 134: o telhado de ardósia (os serviços de pedra), no lugar das telhas
instance uniform float slate = 0.0;
// Fase 138: o telhado de chapa de ferro ondulada (as fábricas pesadas), no lugar das telhas
instance uniform float corrugated = 0.0;
// Fase 303: o telhado de tábuas cinzentas (parte das casas dos operários)
instance uniform float shingle = 0.0;
// Fase 185: a hera nas paredes (0 sem; até 1, quanto ela sobe), posta pela BuildingView
instance uniform float ivy = 0.0;

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

// Fase 130: o sapê — fiadas grossas de thatch_course_m ao longo da água, com a borda de baixo de cada fiada mais escura e
// irregular, os fios de palha descendo a água (ruído esticado) e o tom de palha velha, mais escuro e esverdeado no pé
uniform vec4 thatch_color : source_color = vec4(0.6, 0.5, 0.32, 1.0);
uniform vec4 thatch_old : source_color = vec4(0.38, 0.35, 0.24, 1.0);
uniform float thatch_course_m = 0.55;
uniform float thatch_strand_m = 0.045;

// Fase 134: a ardósia — placas retangulares de slate_width_m em fiadas de slate_row_m desencontradas, a borda de baixo
// reta com a sombra embaixo, a junta fina e um tom cinza-azulado por placa
uniform vec4 slate_color : source_color = vec4(0.27, 0.3, 0.34, 1.0);
uniform float slate_row_m = 0.26;
uniform float slate_width_m = 0.34;

// Fase 138: a chapa ondulada — ondas de corrugation_m descendo a água, chapas de sheet_width_m por sheet_length_m
// sobrepostas, ferro cinza com a ferrugem escorrendo da junta de cima de cada chapa e em manchas
uniform vec4 sheet_color : source_color = vec4(0.5, 0.52, 0.54, 1.0);
uniform vec4 rust_color : source_color = vec4(0.4, 0.23, 0.14, 1.0);
uniform float corrugation_m = 0.12;
uniform float sheet_length_m = 1.6;
uniform float sheet_width_m = 0.9;

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
// Fase 185: a hera — as folhas em dois verdes, até ivy_reach_m de altura nas colunas mais cheias
uniform vec4 ivy_dark : source_color = vec4(0.1, 0.18, 0.07, 1.0);
uniform vec4 ivy_light : source_color = vec4(0.24, 0.36, 0.12, 1.0);
uniform float ivy_reach_m = 7.0;
// Fase 177: as cores dos postigos (uma por prédio, pelo lugar dele) e a largura das réguas da veneziana
uniform vec4 shutter_green : source_color = vec4(0.22, 0.36, 0.24, 1.0);
uniform vec4 shutter_blue : source_color = vec4(0.24, 0.34, 0.46, 1.0);
uniform vec4 shutter_red : source_color = vec4(0.48, 0.18, 0.14, 1.0);
uniform vec4 shutter_ochre : source_color = vec4(0.6, 0.47, 0.27, 1.0);
uniform float shutter_slat_m = 0.09;
// Fase 217: as cores das cortinas (uma por casa, pelo lugar dela) e o passo das pregas
uniform vec4 curtain_lace : source_color = vec4(0.88, 0.87, 0.82, 1.0);
uniform vec4 curtain_cream : source_color = vec4(0.83, 0.74, 0.56, 1.0);
uniform vec4 curtain_rose : source_color = vec4(0.66, 0.36, 0.33, 1.0);
uniform vec4 curtain_sage : source_color = vec4(0.47, 0.55, 0.43, 1.0);
uniform float curtain_pleat_m = 0.05;
// Fase 300: o telhado de telhas gasto: o tom de cada casa entre roof_tone_dark e roof_tone_light (multiplicando a cor), a parte
// das telhas trocadas (roof_swap_share), o musgo (roof_moss) e a sujeira escorrida
uniform vec3 roof_tone_dark = vec3(0.8, 0.76, 0.74);
uniform vec3 roof_tone_light = vec3(1.06, 1.02, 0.96);
uniform float roof_swap_share = 0.05;
uniform vec4 roof_moss : source_color = vec4(0.3, 0.33, 0.17, 1.0);
uniform float roof_moss_strength = 0.45;
uniform float roof_streak_strength = 0.18;
// Fase 302: a parede suja — o respingo de terra no pé (até splash_height_m, com a borda de cima irregular) na cor splash_color, e os
// escorridos de chuva descendo pela parede (riscos verticais de altura sorteada, a partir de ~0,4 m do chão)
uniform vec4 splash_color : source_color = vec4(0.36, 0.3, 0.22, 1.0);
uniform float splash_height_m = 0.7;
uniform float splash_strength = 0.5;
uniform float wall_streak_strength = 0.16;
// Fase 303: as tábuas do telhado — fileiras de shingle_row_m ao longo da água, tábuas de largura sorteada em volta de
// shingle_width_m, num cinza de madeira velha (shingle_color) com um tom por tábua
uniform vec4 shingle_color : source_color = vec4(0.47, 0.44, 0.4, 1.0);
// Fase 350: o tom marrom das tábuas (o parâmetro shingle em 2 escolhe ele; em 1, o cinza)
uniform vec4 shingle_brown : source_color = vec4(0.46, 0.36, 0.27, 1.0);
uniform float shingle_row_m = 0.32;
uniform float shingle_width_m = 0.22;

varying vec3 world_position;
varying vec3 world_normal;
varying float contact;
varying flat float shutter_pick;
varying flat float curtain_pick;
varying flat float roof_pick;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Fase 177: a cor dos postigos pelo lugar do prédio (hash inteiro: sem o sin, que perde precisão longe da origem)
	uint h = uint(int(floor(MODEL_MATRIX[3].x * 0.5))) * 2654435761u ^ uint(int(floor(MODEL_MATRIX[3].z * 0.5))) * 2246822519u;
	h ^= h >> 15u;
	shutter_pick = float(h % 4u);
	curtain_pick = float((h >> 7u) % 4u);
	// Fase 300: o tom e o gasto do telhado, pelo mesmo lugar (outros bits)
	roof_pick = float((h >> 13u) % 1024u) / 1023.0;
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


// Fase 300: as coordenadas da telha no ponto p (normal n): x ao longo da água em fileiras (a mesma conta da roof_tile_shade),
// y de través em telhas, já desencontradas
vec2 roof_tile_at(vec3 p, vec3 n) {
	vec2 down = normalize(n.xz);
	vec2 across = vec2(-down.y, down.x);
	float s = dot(p.xz, down) / max(n.y, 0.2) / tile_row_m;
	return vec2(s, dot(p.xz, across) / tile_width_m + 0.5 * mod(floor(s), 2.0));
}

// Fase 300: o telhado gasto, de 0 a 1 por efeito: x a telha trocada (mais clara e mais viva), y o musgo, z a sujeira escorrida
vec3 roof_wear(vec3 p, vec3 n, float pick) {
	vec2 tile = roof_tile_at(p, n);
	vec2 id = floor(tile);
	float swap = step(1.0 - roof_swap_share, fract(sin(dot(id, vec2(41.31, 17.77))) * 43758.5453));
	// musgo em manchas, mais no lado da sombra fixo (o norte, -z) e mais nas casas de pick alto
	float shade_side = clamp(0.5 - n.z * 1.5, 0.0, 1.0);
	float moss = smoothstep(0.66, 0.88, moss_noise(p.xz * 0.7 + pick * 37.0) * 0.6 + moss_noise(p.xz * 2.3) * 0.4 + shade_side * 0.2 + pick * 0.12);
	// sujeira escorrendo água abaixo: riscos finos de través, compridos ao longo da água
	float streak = smoothstep(0.55, 0.85, moss_noise(vec2(tile.y * 0.9, tile.x * 0.04) + pick * 13.0));
	return vec3(swap, moss, streak);
}


// Fase 303: a cor das tábuas do telhado no ponto p (normal n): a sombra da borda de baixo de cada fileira, a fresta entre as
// tábuas, um tom por tábua e o veio ao longo da água; near apaga o desenho de longe (sobra o tom médio)
vec3 shingle_shade(vec3 p, vec3 n, float near, vec3 base) {
	vec2 down = normalize(n.xz);
	vec2 across = vec2(-down.y, down.x);
	float s = dot(p.xz, down) / max(n.y, 0.2) / shingle_row_m;
	float row = floor(s);
	float f = fract(s);
	// largura sorteada por fileira: as frestas não se alinham
	float width = shingle_width_m * (0.75 + 0.5 * fract(sin(row * 12.9898) * 43758.5453));
	float c = dot(p.xz, across) / width + fract(row * 0.618);
	float board = floor(c);
	float cf = fract(c);
	float tone = fract(sin(dot(vec2(row, board), vec2(12.9898, 78.233))) * 43758.5453);
	vec3 wood = base * (0.78 + 0.4 * tone);
	float grain = moss_noise(vec2(c * 3.0, s * 9.0));
	wood *= 0.92 + 0.12 * grain;
	float gap = smoothstep(0.06, 0.0, cf) + smoothstep(0.94, 1.0, cf);
	float under = smoothstep(0.82, 1.0, f);
	vec3 drawn = wood * (1.0 - clamp(gap, 0.0, 1.0) * 0.45) * (1.0 - under * 0.4);
	return mix(base * 0.95, drawn, near);
}

// Fase 130: ruído de valor com hash sem seno (com coordenadas de mundo grandes o fract(sin(...)) sai em escada na GPU).
float thatch_hash(vec2 p) {
	vec3 q = fract(vec3(mod(p, 1024.0).xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(thatch_hash(i), thatch_hash(i + vec2(1.0, 0.0)), f.x),
			mix(thatch_hash(i + vec2(0.0, 1.0)), thatch_hash(i + vec2(1.0)), f.x), f.y);
}

// Fase 130: a cor do sapê no ponto p (normal n): as fiadas, os fios e o pé envelhecido; a base é a cor do telhado.
vec3 thatch_shade(vec3 base, vec3 p, vec3 n) {
	vec2 down = normalize(n.xz);
	vec2 across = vec2(-down.y, down.x);
	float s = dot(p.xz, down) / max(n.y, 0.2);
	float a = dot(p.xz, across);
	// a borda de cada fiada ondula um pouco ao longo da água
	float wave = (value_noise(vec2(a * 1.7, floor(s / thatch_course_m) * 3.1)) - 0.5) * 0.25;
	float f = fract(s / thatch_course_m + wave);
	float lip = smoothstep(0.72, 0.98, f);
	// os fios: ruído fino de través, esticado ao longo da água
	float strand = value_noise(vec2(a / thatch_strand_m, s * 2.0));
	vec3 straw = mix(thatch_color.rgb, thatch_old.rgb, 0.35 + 0.4 * value_noise(p.xz * 0.6));
	straw = mix(straw, base, 0.25);
	straw *= 0.72 + 0.48 * strand;
	straw *= 1.0 - lip * 0.45;
	return straw;
}

// Fase 134: a cor da ardósia no ponto p (normal n): placas retangulares, a sombra sob a borda reta, a junta e o tom de
// cada placa; near apaga o desenho de longe.
vec3 slate_shade(vec3 p, vec3 n, float near) {
	vec2 down = normalize(n.xz);
	vec2 across = vec2(-down.y, down.x);
	float s = dot(p.xz, down) / max(n.y, 0.2) / slate_row_m;
	float row = floor(s);
	float f = fract(s);
	float c = dot(p.xz, across) / slate_width_m + 0.5 * mod(row, 2.0);
	float cf = fract(c) - 0.5;
	float under = smoothstep(0.86, 0.93, f);
	float seam = smoothstep(0.44, 0.5, abs(cf));
	float tone = thatch_hash(vec2(row, floor(c)));
	vec3 color = slate_color.rgb * (0.82 + 0.36 * tone);
	color = mix(color, color * vec3(0.92, 0.96, 1.08), step(0.7, tone));
	return color * (1.0 - (under * 0.55 + seam * 0.4) * near);
}

// Fase 138: a cor da chapa ondulada no ponto p (normal n) em rgb e a ferrugem em a: a crista clara e o vale escuro de cada
// onda, o tom de cada chapa, a sombra na junta de baixo e a ferrugem; near apaga o desenho de longe.
vec4 iron_sheet_shade(vec3 p, vec3 n, float near) {
	vec2 down = normalize(n.xz);
	vec2 across = vec2(-down.y, down.x);
	float s = dot(p.xz, down) / max(n.y, 0.2);
	float c = dot(p.xz, across);
	float wave = sin(c / corrugation_m * 6.2831853);
	float row = floor(s / sheet_length_m);
	float f = fract(s / sheet_length_m);
	float column = floor(c / sheet_width_m + 0.37 * mod(row, 2.0));
	float tone = thatch_hash(vec2(row, column));
	vec3 color = sheet_color.rgb * (0.84 + 0.24 * tone);
	float streak = (1.0 - smoothstep(0.0, 0.6, f)) * smoothstep(0.4, 0.8, value_noise(vec2(c * 3.0, row * 7.0)));
	float patches = smoothstep(0.55, 0.85, value_noise(p.xz * 0.45 + vec2(row * 0.7)));
	float rust = clamp(streak * 0.6 + patches * 0.5 + tone * 0.2 - 0.1, 0.0, 0.85);
	color = mix(color, rust_color.rgb * (0.8 + 0.3 * tone), rust);
	float lap = smoothstep(0.94, 0.99, f);
	return vec4(color * (1.0 + 0.18 * wave * near) * (1.0 - lap * 0.4 * near), rust);
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
	} else if (cell == ivec2(0, 0)) {
		// Fase 217: as cortinas (célula (0, 0), que o kit não usa): o pano numa das quatro cores pela casa, as pregas descendo
		// (a sombra entre elas, sumindo de longe como as telhas)
		vec3 cloth = curtain_pick < 0.5 ? curtain_lace.rgb : (curtain_pick < 1.5 ? curtain_cream.rgb
				: (curtain_pick < 2.5 ? curtain_rose.rgb : curtain_sage.rgb));
		float along = dot(world_position.xz, normalize(vec2(-world_normal.z, world_normal.x) + vec2(1e-5)));
		float near = 1.0 - smoothstep(tile_fade_far * 0.25, tile_fade_far * 0.5, length(VERTEX));
		float pleat = 0.5 + 0.5 * sin(along / curtain_pleat_m * TAU);
		color = cloth * mix(1.0, 0.78 + 0.22 * pleat, near);
	} else if (cell == ivec2(1, 1)) {
		// Fase 177: os postigos (célula (1, 1), que o kit não usa): a tinta numa das quatro cores pelo prédio, as réguas da
		// veneziana atravessadas (a sombra embaixo de cada uma) e a madeira aparecendo onde a tinta gastou
		vec3 paint = shutter_pick < 0.5 ? shutter_green.rgb : (shutter_pick < 1.5 ? shutter_blue.rgb
				: (shutter_pick < 2.5 ? shutter_red.rgb : shutter_ochre.rgb));
		float slat = fract(world_position.y / shutter_slat_m);
		float louver = 0.78 + 0.22 * smoothstep(0.0, 0.4, slat) - 0.18 * smoothstep(0.82, 1.0, slat);
		float wear = moss_noise(world_position.xz * 9.0 + vec2(world_position.y * 6.0));
		color = mix(paint, trim_wood.rgb, smoothstep(0.72, 0.95, wear) * 0.55) * louver;
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
		color = mix(surface.rgb * 1.25, luma / 0.38 * shade, wall ? tint_strength : roof_tint_strength);
		roughness = surface.a;
		NORMAL_MAP = wall
				? triplanar(wall_normals, world_position, weights, wall_meters, layer).rgb
				: triplanar(roof_normals, world_position, weights, roof_meters, roof_layer).rgb;
		// Fase 95: as telhas, só nas águas viradas para cima (não na capa, no beiral nem embaixo do telhado)
		if (roof && cell.x == 0 && world_normal.y > 0.25 && world_normal.y < 0.97) {
			float near = 1.0 - smoothstep(tile_fade_far * 0.5, tile_fade_far, length(VERTEX));
			if (thatch > 0.5) {
				// Fase 130: o sapê, de perto com as fiadas e os fios, de longe só o tom de palha
				vec3 straw = thatch_shade(color, world_position, world_normal);
				vec3 far_straw = mix(thatch_color.rgb, thatch_old.rgb, 0.5);
				color = mix(far_straw * 0.9, straw, near);
				roughness = 0.95;
			} else if (slate > 0.5) {
				// Fase 134: a ardósia, lisa e um pouco brilhante
				color = slate_shade(world_position, world_normal, near);
				roughness = 0.55;
			} else if (shingle > 0.5) {
				// Fase 303: as tábuas cinzentas, foscas
				color = shingle_shade(world_position, world_normal, near, shingle > 1.5 ? shingle_brown.rgb : shingle_color.rgb);
				// sem o relevo das telhas do mapa de normais
				NORMAL_MAP = vec3(0.5, 0.5, 1.0);
				roughness = 0.9;
			} else if (corrugated > 0.5) {
				// Fase 138: a chapa ondulada, mais lisa onde não enferrujou
				vec4 sheet = iron_sheet_shade(world_position, world_normal, near);
				color = sheet.rgb;
				roughness = mix(0.42, 0.85, sheet.a);
				// a chapa é lisa: sem o relevo das telhas do mapa de normais
				NORMAL_MAP = vec3(0.5, 0.5, 1.0);
			} else {
				color *= 1.0 - roof_tile_shade(world_position, world_normal) * tile_strength * near;
				// Fase 300: o telhado gasto — um tom por casa, telhas trocadas, musgo e sujeira escorrida
				color *= mix(roof_tone_dark, roof_tone_light, roof_pick);
				vec3 wear = roof_wear(world_position, world_normal, roof_pick);
				color = mix(color, color * vec3(1.25, 1.12, 0.95), wear.x * near);
				color = mix(color, roof_moss.rgb * (0.7 + 0.5 * dot(color, vec3(0.33))), wear.y * roof_moss_strength);
				color *= 1.0 - wear.z * roof_streak_strength;
			}
		} else if (roof && thatch > 0.5) {
			// a capa da cumeeira e o beiral do sapê: palha mais escura e lisa
			color = mix(thatch_old.rgb, color, 0.3) * 0.85;
			roughness = 0.95;
		} else if (roof && slate > 0.5) {
			// a capa, o beiral redondo e o telhado plano da ardósia: a cor dela, lisa
			color = slate_color.rgb * 0.9;
		} else if (roof && shingle > 0.5) {
			// Fase 303: a capa e o beiral das tábuas: madeira cinzenta mais escura
			color = (shingle > 1.5 ? shingle_brown.rgb : shingle_color.rgb) * 0.75;
			roughness = 0.9;
		} else if (roof && corrugated > 0.5) {
			// a capa, o beiral e o telhado plano da chapa: o ferro escurecido
			color = mix(sheet_color.rgb, rust_color.rgb, 0.3) * 0.85;
			roughness = 0.6;
			NORMAL_MAP = vec3(0.5, 0.5, 1.0);
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
		if (wall && abs(world_normal.y) < 0.5) {
			// Fase 302: o respingo de terra no pé da parede e os escorridos de chuva
			float wall_along = dot(world_position.xz, normalize(vec2(-world_normal.z, world_normal.x)));
			float splash_top = splash_height_m * (0.55 + 0.9 * moss_noise(vec2(wall_along * 1.3, 2.0)));
			float splash = (1.0 - smoothstep(splash_top * 0.4, splash_top, above))
					* (0.55 + 0.45 * moss_noise(vec2(wall_along * 7.0, above * 7.0)));
			color = mix(color, splash_color.rgb * (0.75 + 0.5 * kit_luma), splash * splash_strength);
			float wall_streak = smoothstep(0.6, 0.85, moss_noise(vec2(wall_along * 2.4, world_position.y * 0.11)));
			color *= 1.0 - wall_streak * smoothstep(0.4, 1.6, above) * wall_streak_strength;
		}
		// musgo em manchas na faixa de baixo das paredes viradas para o lado (não no telhado)
		float moss = (1.0 - smoothstep(0.0, moss_height, above)) * smoothstep(0.45, 0.75,
				moss_noise(world_position.xz * 1.7 + world_position.y * 0.9)) * (1.0 - abs(world_normal.y));
		color = mix(color, moss_color.rgb * (0.7 + 0.6 * kit_luma), moss * moss_strength);
		if (ivy > 0.0 && wall && abs(world_normal.y) < 0.5) {
			// Fase 185: a hera sobe do chão em colunas de altura sorteada ao longo da parede, com a borda de cima recortada e as
			// folhas em manchas de dois verdes
			float along = dot(world_position.xz, normalize(vec2(-world_normal.z, world_normal.x)));
			float reach = ivy * ivy_reach_m * smoothstep(0.3, 0.85, moss_noise(vec2(along * 0.32, 4.7)));
			float ragged = reach + 0.6 * (moss_noise(vec2(along * 2.6, world_position.y * 1.3)) - 0.5);
			float leaf = moss_noise(vec2(along, world_position.y) * 8.0);
			float cover = (1.0 - smoothstep(ragged - 0.35, ragged, above)) * step(0.2, reach)
					* smoothstep(0.15, 0.4, leaf + 0.2);
			color = mix(color, mix(ivy_dark.rgb, ivy_light.rgb, leaf), cover * 0.94);
			roughness = mix(roughness, 0.7, cover);
		}
		// sombra de contato: a fachada que dá para o prédio vizinho escurece de baixo para cima
		color *= 1.0 - contact * contact_strength * (1.0 - smoothstep(0.0, contact_height, above));
		color *= 1.0 - soot * 0.55;
		float exposure = clamp(world_normal.y * 0.5 + 0.6, 0.0, 1.0);
		ALBEDO = wet_albedo(color, exposure);
		ROUGHNESS = wet_roughness(roughness, exposure);
	}
}
