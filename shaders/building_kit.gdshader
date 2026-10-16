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

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
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
	if (cell == ivec2(4, 3)) {
		color = kit_luma / 0.55 * mix(trim_wood.rgb, tint.rgb * 0.6, 0.35);
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
	float roughness = 0.85;
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
	}
	float above = world_position.y - base_height;
	color *= 1.0 - (1.0 - smoothstep(0.0, grime_height, above)) * grime_strength;
	color *= 1.0 - soot * 0.55;
	float exposure = clamp(world_normal.y * 0.5 + 0.6, 0.0, 1.0);
	ALBEDO = wet_albedo(color, exposure);
	ROUGHNESS = wet_roughness(roughness, exposure);
}
