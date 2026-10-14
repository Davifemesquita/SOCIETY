// Prédios e casas (Fase 9): textura PBR da Poly Haven (CC0) projetada no mundo pelas três faces
// (triplanar: a caixa placeholder não tem UV), no tom da categoria do prédio, com sujeira na
// base, fuligem das indústrias vizinhas e a chuva molhando. Um material só para todas as paredes
// (e outro para os telhados): a camada da textura, o tom e a sujeira são de cada instância.
shader_type spatial;
render_mode cull_back;

#include "res://shaders/wet_surface.gdshaderinc"

uniform sampler2DArray albedo_rough : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray normals : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
// metros por repetição da textura e quanto o tom da categoria pinta a textura
uniform float texture_meters = 3.0;
uniform float tint_strength = 0.55;
// altura (m acima da base) até onde vai a sujeira e quanto ela escurece
uniform float grime_height = 1.4;
uniform float grime_strength = 0.35;

instance uniform vec4 tint : source_color = vec4(1.0);
instance uniform float layer = 0.0;
instance uniform float base_height = 0.0;
// fuligem das chaminés vizinhas (0 a 1)
instance uniform float soot = 0.0;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec4 triplanar(sampler2DArray stack, vec3 position, vec3 weights) {
	vec3 p = position / texture_meters;
	return texture(stack, vec3(p.zy, layer)) * weights.x
			+ texture(stack, vec3(p.xz, layer)) * weights.y
			+ texture(stack, vec3(p.xy, layer)) * weights.z;
}

void fragment() {
	vec3 weights = pow(abs(world_normal), vec3(4.0));
	weights /= weights.x + weights.y + weights.z;
	vec4 surface = triplanar(albedo_rough, world_position, weights);
	vec3 normal_map = triplanar(normals, world_position, weights).rgb;
	float luma = dot(surface.rgb, vec3(0.299, 0.587, 0.114));
	// o tom da categoria pinta a textura sem escurecê-la (a média de brilho das texturas é ~0,38)
	vec3 color = mix(surface.rgb * 1.25, luma / 0.38 * tint.rgb, tint_strength);
	float above = world_position.y - base_height;
	float grime = (1.0 - smoothstep(0.0, grime_height, above)) * grime_strength;
	color *= 1.0 - grime;
	color *= 1.0 - soot * 0.55;
	// telhado e paredes molham por igual; o lado de baixo (beiral) fica seco
	float exposure = clamp(world_normal.y * 0.5 + 0.6, 0.0, 1.0);
	ALBEDO = wet_albedo(color, exposure);
	NORMAL_MAP = normal_map;
	ROUGHNESS = wet_roughness(surface.a, exposure);
}
