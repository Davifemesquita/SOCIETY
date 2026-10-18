// Estradas (Fase 9): terra batida e paralelepípedo da Poly Haven (CC0), vistas de cima, no
// MultiMesh das estradas. A camada vem do dado da instância (INSTANCE_CUSTOM.r: 0 terra,
// 1 paralelepípedo); a ponte (INSTANCE_CUSTOM.g = 1) fica na cor da instância, de tábua. Fase 14: na
// terra, dois sulcos de roda (INSTANCE_CUSTOM.b: 0 nenhum, 1 ao longo de x, 2 de z, 3 os dois, 4 e 5 nas duas
// diagonais, Fase 17), e na ponte,
// tábuas de través pela mesma direção, cada uma num tom, com a fresta escura entre elas. Fase 19: o
// ladrilho inclinado leva a torção da célula (INSTANCE_CUSTOM.a, o quanto os cantos saem do plano) e passa
// pelos quatro cantos como o terreno, sem degrau entre células na ladeira; na terra, os lados abertos (bits
// em INSTANCE_CUSTOM.b acima dos sulcos, b = sulcos + 8 × bits; 1 +x, 2 −x, 4 +z, 8 −z) têm a borda
// recortada, com o capim do terreno aparecendo e a terra esverdeando junto dela; no paralelepípedo, os
// mesmos lados (os do meio-fio) têm a sarjeta: canaleta rasa, escura e lisa, junto do meio-fio. (A cor da instância entra
// na cor final; por isso nada vai nela.)
shader_type spatial;
render_mode cull_back;

#include "res://shaders/wet_surface.gdshaderinc"

uniform sampler2DArray albedo_rough : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray normals : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float texture_meters = 4.0;
// Sulcos: distância do meio da rua, largura, quanto escurecem e quanto ficam mais lisos.
uniform float rut_offset_m = 0.42;
uniform float rut_width_m = 0.14;
uniform float rut_darken = 0.68;
// Tábuas da ponte: largura, fresta (fração da tábua) e quanto o tom varia de uma para outra.
uniform float plank_width_m = 0.3;
uniform float plank_gap = 0.08;
uniform float plank_tone = 0.25;
// Lado da célula, fundo da borda recortada e a faixa de terra esverdeada além dela.
uniform float cell_m = 2.0;
uniform float verge_m = 0.38;
uniform float verge_tint_m = 0.3;
// Sarjeta: onde começa (largura do meio-fio), a largura dela, quanto escurece e a fundura (no relevo).
uniform float gutter_start_m = 0.22;
uniform float gutter_width_m = 0.3;
uniform float gutter_darken = 0.5;
uniform float gutter_depth = 0.5;

varying vec3 world_position;
varying flat float road_layer;
varying flat float bridge;
varying flat float rut_kind;
varying vec2 local_position;
varying flat float open_edges;
varying vec3 local_normal;

void vertex() {
	road_layer = INSTANCE_CUSTOM.r;
	bridge = INSTANCE_CUSTOM.g;
	rut_kind = mod(INSTANCE_CUSTOM.b, 8.0);
	open_edges = floor(INSTANCE_CUSTOM.b / 8.0 + 0.01);
	local_position = VERTEX.xz;
	local_normal = NORMAL;
	vec2 t = clamp(VERTEX.xz / cell_m, -0.5, 0.5);
	VERTEX.y += INSTANCE_CUSTOM.a * t.x * t.y;
	if (NORMAL.y > 0.5) {
		NORMAL = normalize(NORMAL - vec3(INSTANCE_CUSTOM.a * t.y, 0.0, INSTANCE_CUSTOM.a * t.x) / cell_m);
	}
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

// Ruído de um eixo (0 a 1), suave, em duas oitavas: o recorte da borda ao longo dela.
float edge_noise(float along) {
	float s = along * 2.2;
	float a = mix(hash(floor(s)), hash(floor(s) + 1.0), smoothstep(0.0, 1.0, fract(s)));
	float t = along * 6.1 + 17.0;
	float b = mix(hash(floor(t)), hash(floor(t) + 1.0), smoothstep(0.0, 1.0, fract(t)));
	return a * 0.7 + b * 0.3;
}

// Quanto falta (m) até a borda recortada do lado aberto mais perto; negativo já é capim. A borda entra de
// 0,15 a 1 × verge_m pelo ruído ao longo do lado (no mundo, para emendar de uma célula para a outra).
float open_distance(int bits) {
	float half_cell = cell_m * 0.5;
	float d = 1000.0;
	if ((bits & 1) != 0) { d = min(d, half_cell - local_position.x - verge_m * (0.15 + 0.85 * edge_noise(world_position.z))); }
	if ((bits & 2) != 0) { d = min(d, half_cell + local_position.x - verge_m * (0.15 + 0.85 * edge_noise(world_position.z + 41.0))); }
	if ((bits & 4) != 0) { d = min(d, half_cell - local_position.y - verge_m * (0.15 + 0.85 * edge_noise(world_position.x + 83.0))); }
	if ((bits & 8) != 0) { d = min(d, half_cell + local_position.y - verge_m * (0.15 + 0.85 * edge_noise(world_position.x + 127.0))); }
	return d;
}

// Distância (m) até o lado aberto mais perto, reta (a sarjeta segue o meio-fio), e para que lado ele fica.
vec3 open_side(int bits) {
	float half_cell = cell_m * 0.5;
	vec3 best = vec3(1000.0, 0.0, 0.0);
	if ((bits & 1) != 0 && half_cell - local_position.x < best.x) { best = vec3(half_cell - local_position.x, 1.0, 0.0); }
	if ((bits & 2) != 0 && half_cell + local_position.x < best.x) { best = vec3(half_cell + local_position.x, -1.0, 0.0); }
	if ((bits & 4) != 0 && half_cell - local_position.y < best.x) { best = vec3(half_cell - local_position.y, 0.0, 1.0); }
	if ((bits & 8) != 0 && half_cell + local_position.y < best.x) { best = vec3(half_cell + local_position.y, 0.0, -1.0); }
	return best;
}

// A face de lado do ladrilho que dá para um lado aberto (some com a borda recortada).
bool open_side_face(int bits) {
	return ((bits & 1) != 0 && local_normal.x > 0.5) || ((bits & 2) != 0 && local_normal.x < -0.5)
			|| ((bits & 4) != 0 && local_normal.z > 0.5) || ((bits & 8) != 0 && local_normal.z < -0.5);
}

// 1 no meio do sulco, 0 fora dele (a distância é do meio da rua, de través)
float rut(float across) {
	float edge = abs(abs(across) - rut_offset_m);
	return 1.0 - smoothstep(rut_width_m * 0.35, rut_width_m * 0.5, edge);
}

// Fator de cor da ponte: tom da tábua e a fresta. As tábuas ficam de través da direção da rua, alinhadas
// no mundo para emendar de uma célula para a outra.
float planks(int kind) {
	bool along_z = kind == 2;
	float travel = (along_z ? world_position.z : world_position.x) / plank_width_m;
	float across = floor((along_z ? world_position.x : world_position.z) * 0.5);
	float f = fract(travel);
	float gap = smoothstep(0.0, plank_gap, f) * smoothstep(0.0, plank_gap, 1.0 - f);
	float tone = 1.0 + (hash(floor(travel) + across * 31.0) - 0.5) * plank_tone;
	return tone * mix(0.45, 1.0, gap);
}

void fragment() {
	// a face de lado do ladrilho projeta a textura de lado (de cima ela esticava em listras)
	vec2 plane = local_normal.y > 0.5 ? world_position.xz
			: (abs(local_normal.x) > 0.5 ? world_position.zy : world_position.xy);
	vec3 uv = vec3(plane / texture_meters, road_layer);
	vec4 surface = texture(albedo_rough, uv);
	int kind = int(rut_kind + 0.5);
	// borda recortada da terra
	int bits = int(open_edges + 0.5) * int(road_layer < 0.5 && bridge < 0.5);
	int curbed = int(open_edges + 0.5) * int(road_layer > 0.5 && bridge < 0.5);
	float verge = 0.0;
	float gutter = 0.0;
	vec2 gutter_tilt = vec2(0.0);
	if (curbed != 0) {
		vec3 side = open_side(curbed);
		float across = (side.x - gutter_start_m) / gutter_width_m;
		gutter = step(0.0, across) * (1.0 - smoothstep(0.7, 1.0, across));
		// a canaleta desce do calçamento para o meio-fio: a normal pende para o lado do meio-fio no fundo
		gutter_tilt = side.yz * gutter_depth * gutter * (across < 0.5 ? -1.0 : 1.0);
	}
	if (bits != 0) {
		if (open_side_face(bits)) {
			discard;
		}
		float d = open_distance(bits);
		if (d < 0.0) {
			discard;
		}
		verge = 1.0 - smoothstep(0.0, verge_tint_m, d);
	}
	// a cor da instância chega em sRGB (a da tábua ficava desbotada)
	vec3 wood = pow(COLOR.rgb, vec3(2.2));
	vec3 color = mix(surface.rgb, wood * planks(kind), bridge);
	float ruts = 0.0;
	if (kind == 1 || kind == 3) {
		ruts = max(ruts, rut(local_position.y));
	}
	if (kind == 2 || kind == 3) {
		ruts = max(ruts, rut(local_position.x));
	}
	// Fase 17: na célula da escada diagonal, ao longo de (+x, +z) (4) ou de (+x, −z) (5)
	if (kind == 4) {
		ruts = max(ruts, rut((local_position.x - local_position.y) * 0.70710678));
	}
	if (kind == 5) {
		ruts = max(ruts, rut((local_position.x + local_position.y) * 0.70710678));
	}
	// só na terra (camada 0, fora da ponte)
	ruts *= (1.0 - road_layer) * (1.0 - bridge);
	color *= mix(1.0, rut_darken, ruts);
	color = mix(color, color * vec3(0.78, 0.9, 0.55), verge * 0.7);
	color *= mix(1.0, gutter_darken, gutter);
	ALBEDO = wet_albedo(color, 1.0);
	vec3 normal_map = mix(texture(normals, uv).rgb, vec3(0.5, 0.5, 1.0), max(bridge, gutter * 0.6));
	NORMAL_MAP = normalize(normal_map + vec3(gutter_tilt.x, -gutter_tilt.y, 0.0) * 0.5);
	ROUGHNESS = wet_roughness(mix(mix(mix(surface.a, 0.85, bridge), 0.6, ruts * 0.5), 0.35, gutter), 1.0);
}
