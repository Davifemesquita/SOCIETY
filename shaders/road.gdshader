// Estradas (Fase 9): terra batida e paralelepípedo da Poly Haven (CC0), vistas de cima, no
// MultiMesh das estradas. A camada vem do dado da instância (INSTANCE_CUSTOM.r: 0 terra,
// 1 paralelepípedo); a ponte (INSTANCE_CUSTOM.g = 1) fica na cor da instância, de tábua. Fase 14: na
// terra, dois sulcos de roda (INSTANCE_CUSTOM.b: 0 nenhum, 1 ao longo de x, 2 de z, 3 os dois).
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

void fragment() {
	vec3 uv = vec3(world_position.xz / texture_meters, road_layer);
	vec4 surface = texture(albedo_rough, uv);
	vec3 color = mix(surface.rgb, COLOR.rgb, bridge);
	int kind = int(rut_kind + 0.5);
	float ruts = 0.0;
	if (kind == 1 || kind == 3) {
		ruts = max(ruts, rut(local_position.y));
	}
	if (kind == 2 || kind == 3) {
		ruts = max(ruts, rut(local_position.x));
	}
	// só na terra (camada 0, fora da ponte)
	ruts *= (1.0 - road_layer) * (1.0 - bridge);
	color *= mix(1.0, rut_darken, ruts);
	ALBEDO = wet_albedo(color, 1.0);
	NORMAL_MAP = mix(texture(normals, uv).rgb, vec3(0.5, 0.5, 1.0), bridge);
	ROUGHNESS = wet_roughness(mix(mix(surface.a, 0.85, bridge), 0.6, ruts * 0.5), 1.0);
}
