// Estradas (Fase 9): terra batida e paralelepípedo da Poly Haven (CC0), vistas de cima, no
// MultiMesh das estradas. A camada vem do dado da instância (INSTANCE_CUSTOM.r: 0 terra,
// 1 paralelepípedo); a ponte (INSTANCE_CUSTOM.g = 1) fica na cor da instância, de tábua. Fase 14: na
// terra, dois sulcos de roda (INSTANCE_CUSTOM.b: 0 nenhum, 1 ao longo de x, 2 de z, 3 os dois, 4 e 5 nas duas
// diagonais, Fase 17), e na ponte,
// tábuas de través pela mesma direção, cada uma num tom, com a fresta escura entre elas.
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

varying vec3 world_position;
varying flat float road_layer;
varying flat float bridge;
varying flat float rut_kind;
varying vec2 local_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	road_layer = INSTANCE_CUSTOM.r;
	bridge = INSTANCE_CUSTOM.g;
	rut_kind = INSTANCE_CUSTOM.b;
	local_position = VERTEX.xz;
}

// 1 no meio do sulco, 0 fora dele (a distância é do meio da rua, de través)
float rut(float across) {
	float edge = abs(abs(across) - rut_offset_m);
	return 1.0 - smoothstep(rut_width_m * 0.35, rut_width_m * 0.5, edge);
}

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
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
	vec3 uv = vec3(world_position.xz / texture_meters, road_layer);
	vec4 surface = texture(albedo_rough, uv);
	int kind = int(rut_kind + 0.5);
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
	ALBEDO = wet_albedo(color, 1.0);
	NORMAL_MAP = mix(texture(normals, uv).rgb, vec3(0.5, 0.5, 1.0), bridge);
	ROUGHNESS = wet_roughness(mix(mix(surface.a, 0.85, bridge), 0.6, ruts * 0.5), 1.0);
}
