// Estradas (Fase 9): terra batida e paralelepípedo da Poly Haven (CC0), vistas de cima, no
// MultiMesh das estradas. A camada vem do dado da instância (INSTANCE_CUSTOM.r: 0 terra,
// 1 paralelepípedo); a ponte (INSTANCE_CUSTOM.g = 1) fica na cor da instância, de tábua.
shader_type spatial;
render_mode cull_back;

#include "res://shaders/wet_surface.gdshaderinc"

uniform sampler2DArray albedo_rough : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray normals : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float texture_meters = 4.0;

varying vec3 world_position;
varying flat float road_layer;
varying flat float bridge;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	road_layer = INSTANCE_CUSTOM.r;
	bridge = INSTANCE_CUSTOM.g;
}

void fragment() {
	vec3 uv = vec3(world_position.xz / texture_meters, road_layer);
	vec4 surface = texture(albedo_rough, uv);
	vec3 color = mix(surface.rgb, COLOR.rgb, bridge);
	ALBEDO = wet_albedo(color, 1.0);
	NORMAL_MAP = mix(texture(normals, uv).rgb, vec3(0.5, 0.5, 1.0), bridge);
	ROUGHNESS = wet_roughness(mix(surface.a, 0.85, bridge), 1.0);
}
