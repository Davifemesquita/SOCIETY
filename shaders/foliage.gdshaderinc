// O corpo da folhagem (Fase 279: saiu do foliage.gdshader para ser dividido com o tree_foliage.gdshader). As árvores (Fase 9)
// e, desde a Fase 22, as plantações e o capim: a cor da folhagem ou da madeira (ou a cor do vértice, em sRGB), balançando ao
// vento. O balanço cresce com a altura no modelo (o pé fica parado), tem a fase do lugar de cada planta (não balançam juntas)
// e anda no tempo visual (para na pausa). Desde a Fase 22 o vento do WeatherView manda: a planta deita para onde ele sopra
// (wind_direction) e balança mais e mais depressa quanto mais forte ele é (wind_strength); com o ar parado sobra a brisa
// (calm). A chuva escurece e dá brilho.
//
// Fase 279: com LEAF_DETAIL definido (só o tree_foliage.gdshader, das copas de perto), as folhas: cachos de folhas em células
// sorteadas no espaço do modelo (leaf_size m), mais claros no meio e escuros nos vãos, e, na borda da copa (onde a superfície
// fica de lado para a câmera), os vãos recortados (discard): a copa perde o contorno liso de bola. Tudo some de
// leaf_far_m * 0,6 a leaf_far_m da câmera (as árvores de longe ficam iguais); o discard fica fora das plantações e do capim.

#include "res://shaders/wet_surface.gdshaderinc"

global uniform float visual_time;
global uniform vec2 wind_direction;
global uniform float wind_strength;

uniform vec4 albedo : source_color = vec4(0.3, 0.45, 0.2, 1.0);
uniform bool use_vertex_color = false;
uniform float roughness = 0.95;
// deslocamento máximo (m por m de altura) e a velocidade do balanço
uniform float sway = 0.035;
uniform float sway_speed = 1.3;
// altura do modelo onde o balanço chega ao máximo
uniform float model_height = 6.0;
// balanço que sobra com o ar parado, quanto o vento cheio deita a planta e quanto apressa o balanço
uniform float calm = 0.3;
uniform float lean = 1.4;
uniform float hurry = 0.8;
// Fase 41: luz de trás nas folhas (o sol atravessando a copa); a madeira (cor sem predomínio do verde) não ganha
uniform float backlight = 0.35;
// Fase 256: luz própria das folhas de dia (o sol atravessando e voltando da copa), em fração da cor. Sem ela o lado da sombra
// de uma mata fechada ficava quase preto. Fase 260: acompanha a altura do sol (sun_direction, para o sol): cheia com ele alto,
// nada com ele no horizonte e de noite (com o sol baixo, a mata acesa brilhava sobre o chão escuro do fim da tarde).
global uniform vec3 sun_direction;
uniform float leaf_fill = 0.0;

// Fase 305: o tom de cada árvore, sorteado pelo lugar dela (hash inteiro da origem da instância): mais escura, oliva, mais
// amarelada ou a de sempre, com um pouco de claro e escuro. Só na folhagem (a madeira fica), na força tree_tint (o TreeModel
// põe 1 nas folhosas e TreeModel.CONIFER_TINT nas coníferas; as plantações e o capim ficam com 0).
uniform float tree_tint = 0.0;
uniform vec3 tint_dark = vec3(0.66, 0.74, 0.66);
uniform vec3 tint_olive = vec3(0.96, 0.88, 0.58);
uniform vec3 tint_yellow = vec3(1.12, 1.08, 0.72);
varying flat float tree_pick;
// Fase 308: as coníferas escurecem e esfriam com a distância da câmera (far_cool, que o TreeModel põe no pinheiro e no abeto):
// de far_cool_from_m a far_cool_to_m, a folhagem vai para far_cool_tint (mais escura e azulada), como a mata de abetos de longe.
uniform float far_cool = 0.0;
uniform float far_cool_from_m = 40.0;
uniform float far_cool_to_m = 240.0;
uniform vec3 far_cool_tint = vec3(0.6, 0.72, 0.88);

#ifdef LEAF_DETAIL
// tamanho do cacho de folhas (m no modelo), o claro e o escuro dele, quanto a normal estufa para fora do meio do cacho (cada
// um ganha o lado da luz e o da sombra), quanto da borda se recorta e até onde vale
uniform float leaf_size = 0.45;
uniform float leaf_light = 1.06;
uniform float leaf_dark = 0.84;
uniform float leaf_bulge = 0.45;
uniform float leaf_cut = 0.75;
uniform float leaf_far_m = 90.0;
varying vec3 leaf_pos;

// sorteio inteiro de uma célula (as coordenadas são pequenas, mas sem sin: Fase 125)
vec3 leaf_hash(ivec3 c) {
	uvec3 v = uvec3(c) * uvec3(1597334673u, 3812015801u, 2798796415u);
	uint n = (v.x ^ v.y ^ v.z) * 1597334677u;
	uvec3 r = uvec3(n, n * 16807u, n * 48271u);
	return vec3(r >> uvec3(8u)) / 16777216.0;
}

// o ponto sorteado mais perto (células de lado 1, oito em volta): xyz = de lá até p, w = a distância
vec4 leaf_cells(vec3 p) {
	vec3 base = floor(p - 0.5);
	vec4 best = vec4(0.0, 1.0, 0.0, 8.0);
	for (int z = 0; z <= 1; z++) {
		for (int y = 0; y <= 1; y++) {
			for (int x = 0; x <= 1; x++) {
				vec3 cell = base + vec3(float(x), float(y), float(z));
				vec3 away = p - (cell + 0.15 + 0.7 * leaf_hash(ivec3(cell)));
				float d = length(away);
				if (d < best.w) {
					best = vec4(away, d);
				}
			}
		}
	}
	return best;
}
#endif

void vertex() {
	// Fase 305: o sorteio do tom, pela célula de 25 cm da origem (a mesma em todos os vértices da árvore)
	uvec3 spot = uvec3(ivec3(floor(MODEL_MATRIX[3].xyz * 4.0)));
	uint mixed = ((spot.x * 73856093u) ^ (spot.y * 19349663u) ^ (spot.z * 83492791u)) * 1597334677u;
	tree_pick = float(mixed >> 8u) / 16777216.0;
#ifdef LEAF_DETAIL
	// o padrão das folhas preso no modelo (antes do balanço), diferente em cada árvore
	leaf_pos = VERTEX / leaf_size + fract(MODEL_MATRIX[3].xyz * 0.137) * 17.0;
#endif
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = origin.x * 0.13 + origin.z * 0.17;
	float lift = clamp(VERTEX.y / model_height, 0.0, 1.0);
	float bend = lift * lift * sway * model_height;
	// o vento no plano, levado para o espaço do modelo (cada instância vem girada)
	mat3 to_model = inverse(mat3(MODEL_MATRIX));
	vec3 along = to_model * vec3(wind_direction.x, 0.0, wind_direction.y);
	vec3 across = to_model * vec3(-wind_direction.y, 0.0, wind_direction.x);
	along.y = 0.0;
	across.y = 0.0;
	along = length(along) > 0.0001 ? normalize(along) : vec3(1.0, 0.0, 0.0);
	across = length(across) > 0.0001 ? normalize(across) : vec3(0.0, 0.0, 1.0);
	float strength = clamp(wind_strength, 0.0, 1.0);
	float t = visual_time * sway_speed * (1.0 + hurry * strength);
	float gust = sin(t + phase) + 0.4 * sin(t * 2.3 + phase * 1.7);
	float breeze = calm + strength;
	// deitada a favor do vento e balançando em volta disso; de lado, menos
	float push = lean * strength * (0.75 + 0.25 * sin(t * 0.37 + phase * 0.5)) + gust * breeze * 0.6;
	float side = 0.35 * cos(t * 0.8 + phase) * breeze;
	VERTEX += (along * push + across * side) * bend;
}

void fragment() {
	vec3 base = albedo.rgb;
	if (use_vertex_color) {
		// a cor do vértice (e da instância) chega em sRGB
		vec3 c = COLOR.rgb;
		base *= mix(pow((c + vec3(0.055)) / vec3(1.055), vec3(2.4)), c / vec3(12.92), lessThan(c, vec3(0.04045)));
	}
	float leafy = smoothstep(1.05, 1.35, base.g / max(base.r, 0.001));
	if (tree_tint > 0.0) {
		float quarter = floor(tree_pick * 4.0);
		vec3 tone = quarter < 1.0 ? tint_dark : (quarter < 2.0 ? tint_olive : (quarter < 3.0 ? tint_yellow : vec3(1.0)));
		tone *= 0.9 + 0.2 * fract(tree_pick * 4.0);
		base *= mix(vec3(1.0), tone, tree_tint * leafy);
	}
	if (far_cool > 0.0) {
		float away = smoothstep(far_cool_from_m, far_cool_to_m, length(VERTEX));
		base *= mix(vec3(1.0), far_cool_tint, far_cool * away * leafy);
	}
#ifdef LEAF_DETAIL
	float near = (1.0 - smoothstep(leaf_far_m * 0.6, leaf_far_m, length(VERTEX))) * leafy;
	if (near > 0.0) {
		vec4 cell = leaf_cells(leaf_pos);
		float blob = 1.0 - smoothstep(0.3, 0.75, cell.w);
		// a borda da copa: a superfície de lado para a câmera (pela normal da copa, antes do estufado)
		float grazing = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
		if (blob < smoothstep(0.5, 0.9, grazing) * leaf_cut * near) {
			discard;
		}
		base *= mix(1.0, mix(leaf_dark, leaf_light, blob), near);
		vec3 bulge = (VIEW_MATRIX * MODEL_MATRIX * vec4(cell.xyz, 0.0)).xyz;
		if (dot(bulge, bulge) > 1e-6) {
			NORMAL = normalize(mix(NORMAL, normalize(bulge), leaf_bulge * near));
		}
	}
#endif
	ALBEDO = wet_albedo(base, 1.0);
	ROUGHNESS = wet_roughness(roughness, 1.0);
	BACKLIGHT = base * backlight * leafy;
	EMISSION = base * leaf_fill * leafy * smoothstep(0.0, 0.5, sun_direction.y);
}
