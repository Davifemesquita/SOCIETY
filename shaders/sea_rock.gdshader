// Fase 184: a rocha do mar — a mesma textura de rocha do terreno, triplanar no mundo (como o RockView.material), e junto da
// linha d'água a faixa de limo e alga: verde-oliva escuro em manchas até weed_top_m acima do mar, com a borda de cima recortada
// por ruído, e acima dela a pedra ainda molhada (mais escura e lisa) até wet_top_m. Abaixo do mar a água cobre: tanto faz.
// A chuva molha o resto, como nos outros shaders (wet_surface.gdshaderinc).
shader_type spatial;
render_mode cull_back;

#include "res://shaders/wet_surface.gdshaderinc"

uniform sampler2D albedo_height : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_roughness : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(0.78, 0.74, 0.7, 1.0);
uniform float texture_m = 4.0;
uniform vec4 weed_light : source_color = vec4(0.26, 0.2, 0.06, 1.0);
uniform vec4 weed_dark : source_color = vec4(0.04, 0.05, 0.02, 1.0);
uniform float weed_top_m = 1.05;
uniform float edge_m = 0.3;
uniform float wet_top_m = 2.0;
// a linha da maré: a crosta clara de sal e cracas logo acima do limo
uniform vec4 crust : source_color = vec4(0.58, 0.56, 0.5, 1.0);
uniform float crust_m = 0.22;
// Fase 261: a pedra puxa o matiz para este cinza (proporção linear), guardando o claro e o escuro da textura, e clareia
// stone_light vezes: a textura amarronzada, multiplicada pelo tint, saía marrom-oliva (stone_grey_mix 0 deixa como estava).
uniform vec3 stone_grey = vec3(0.86, 0.92, 1.0);
uniform float stone_grey_mix = 0.0;
uniform float stone_light = 1.0;
// Fase 261: a faixa da maré (limo, crosta e pedra molhada) só na rocha do mar; as pedras dos barrancos e das jazidas, longe da
// água, usam o mesmo shader sem ela
uniform bool sea = true;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// Ruído de valor com hash aritmético (sem o sin, que perde precisão longe da origem).
float hash2(vec2 p) {
	uvec2 q = uvec2(ivec2(floor(p)));
	uint h = q.x * 1597334677u ^ q.y * 3812015801u;
	h ^= h >> 16u;
	h *= 2654435769u;
	return float(h >> 8u) / 16777216.0;
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x),
			f.y);
}

void fragment() {
	vec3 weights = pow(abs(world_normal), vec3(4.0));
	weights /= weights.x + weights.y + weights.z;
	vec3 p = world_position / texture_m;
	vec4 albedo = texture(albedo_height, p.zy) * weights.x + texture(albedo_height, p.xz) * weights.y
			+ texture(albedo_height, p.xy) * weights.z;
	vec4 normal = texture(normal_roughness, p.zy) * weights.x + texture(normal_roughness, p.xz) * weights.y
			+ texture(normal_roughness, p.xy) * weights.z;
	vec3 color = albedo.rgb * tint.rgb;
	vec3 grey = stone_grey * (dot(color, vec3(0.299, 0.587, 0.114)) / dot(stone_grey, vec3(0.299, 0.587, 0.114)));
	color = mix(color, grey, stone_grey_mix) * stone_light;
	float roughness = 0.92;
	if (sea) {
		// a borda de cima da faixa sobe e desce pelo ruído ao longo da costa
		vec2 around = world_position.xz;
		float edge = weed_top_m + edge_m * (value_noise(around * 0.9) - 0.5) * 2.0;
		float weed = 1.0 - smoothstep(edge - 0.12, edge + 0.04, world_position.y);
		// a alga em manchas mais claras e mais escuras, mais onde a pedra é funda (o alfa da textura é a altura)
		float patches = value_noise(around * 4.0 + vec2(world_position.y * 3.0));
		vec3 algae = mix(weed_dark.rgb, weed_light.rgb, patches) * (0.8 + 0.4 * albedo.a);
		color = mix(color, algae, weed * 0.95);
		float above = world_position.y - edge;
		float line = smoothstep(-0.05, 0.06, above) * (1.0 - smoothstep(crust_m * 0.25, crust_m, above));
		// em manchas, não uma faixa contínua
		line *= smoothstep(0.3, 0.7, value_noise(around * 2.3 + vec2(7.1, 3.3)));
		color = mix(color, crust.rgb * (0.85 + 0.3 * patches), line * 0.38);
		float wet = 1.0 - smoothstep(edge, wet_top_m, world_position.y);
		color *= 1.0 - 0.45 * wet * (1.0 - weed) * (1.0 - line);
		roughness = mix(roughness, 0.3, max(wet * 0.7, weed * 0.6));
	}
	ALBEDO = wet_albedo(color, 1.0);
	ROUGHNESS = wet_roughness(roughness, 1.0);
	NORMAL_MAP = normal.rgb;
}
