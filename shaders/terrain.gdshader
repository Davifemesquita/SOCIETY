// Terreno das ilhas (seção 7): grama no plano e rocha na encosta (pela inclinação), areia na praia
// e no fundo do mar, chão de floresta onde há árvores. O tipo de chão vem de uma textura por
// região (surface_weights: r = areia, g = floresta), de 2 em 2 m, filtrada (transição suave).
// Texturas da Poly Haven (CC0) empacotadas: cor + altura (a) e normal OpenGL + aspereza (a).
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
// canto da região no mundo (x, z) e o tamanho dela, em metros
uniform vec4 region_bounds = vec4(0.0, 0.0, 512.0, 512.0);
// metros por repetição da textura
uniform float texture_meters = 12.0;
// a rocha aparece quando a normal fica abaixo disto (1 = plano)
uniform float rock_start = 0.86;
uniform float rock_full = 0.7;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = world_position.xz / texture_meters;
	vec2 cell = (world_position.xz - region_bounds.xy) / region_bounds.zw;
	vec4 kinds = texture(surface_weights, cell);
	float rock = smoothstep(rock_start, rock_full, world_normal.y);
	float sand = max(kinds.r, step(world_position.y, 0.4));
	float forest = kinds.g * (1.0 - sand);
	vec4 grass_a = texture(grass_albedo, uv);
	vec4 rock_a = texture(rock_albedo, uv * 0.7);
	vec4 sand_a = texture(sand_albedo, uv);
	vec4 forest_a = texture(forest_albedo, uv);
	vec4 grass_n = texture(grass_normal, uv);
	vec4 rock_n = texture(rock_normal, uv * 0.7);
	vec4 sand_n = texture(sand_normal, uv);
	vec4 forest_n = texture(forest_normal, uv);
	vec4 ground_a = mix(mix(grass_a, forest_a, forest), rock_a, rock * (1.0 - sand));
	vec4 ground_n = mix(mix(grass_n, forest_n, forest), rock_n, rock * (1.0 - sand));
	ground_a = mix(ground_a, sand_a, sand);
	ground_n = mix(ground_n, sand_n, sand);
	// o fundo do mar não molha (já está debaixo d'água)
	float exposure = step(0.0, world_position.y);
	ALBEDO = wet_albedo(ground_a.rgb, exposure);
	NORMAL_MAP = ground_n.rgb;
	ROUGHNESS = wet_roughness(ground_n.a, exposure);
}
