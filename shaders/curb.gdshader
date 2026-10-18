// Meio-fio de pedra (Fase 19): a textura do paralelepípedo (camada 1 da textura das estradas) quase sem cor,
// clareada, projetada no mundo pela face (de cima ou de lado), com a junta entre os blocos ao longo do
// meio-fio (o comprimento da peça fica em z).
shader_type spatial;
render_mode cull_back;

#include "res://shaders/wet_surface.gdshaderinc"

uniform sampler2DArray albedo_rough : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray normals : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float texture_meters = 1.6;
uniform vec3 tint = vec3(1.2, 1.17, 1.1);
// quanto da cor da textura fica (0 = cinza)
uniform float saturation = 0.35;
// comprimento do bloco e largura da junta (fração do bloco)
uniform float block_m = 1.0;
uniform float joint = 0.025;

varying vec3 world_position;
varying vec3 world_normal;
varying float along;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	along = VERTEX.z;
}

void fragment() {
	vec3 facing = abs(world_normal);
	vec2 plane = facing.y > 0.5 ? world_position.xz : (facing.x > facing.z ? world_position.zy : world_position.xy);
	vec3 uv = vec3(plane / texture_meters, 1.0);
	vec4 stone = texture(albedo_rough, uv);
	float light = dot(stone.rgb, vec3(0.3, 0.59, 0.11));
	vec3 color = mix(vec3(light), stone.rgb, saturation) * tint;
	float f = fract(along / block_m + 0.5);
	color *= mix(0.5, 1.0, smoothstep(0.0, joint, f) * smoothstep(0.0, joint, 1.0 - f));
	ALBEDO = wet_albedo(color, 1.0);
	NORMAL_MAP = texture(normals, uv).rgb;
	ROUGHNESS = wet_roughness(stone.a, 1.0);
}
