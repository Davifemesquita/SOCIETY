// Calçamento em grade dual (Fase 46): o paralelepípedo da Poly Haven (camada 1 das texturas das estradas) projetado no
// mundo, numa malha por ilha (PavedDual). A cor do vértice diz a parte: r = 1 calçamento, menos na sarjeta (mais
// escura e lisa); b = 1 no meio-fio (a mesma pedra, clareada e cinza, projetada de lado nas faces de pé).
shader_type spatial;
render_mode cull_back;

#include "res://shaders/wet_surface.gdshaderinc"

uniform sampler2DArray albedo_rough : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray normals : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float texture_meters = 4.0;
uniform float curb_meters = 1.5;
uniform float gutter_darken = 0.55;
uniform vec3 curb_tint = vec3(0.78, 0.77, 0.74);

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float tone = COLOR.r;
	bool curb = COLOR.b > 0.5;
	bool upright = abs(world_normal.y) < 0.5;
	vec2 plane = upright ? (abs(world_normal.x) > 0.5 ? world_position.zy : world_position.xy) : world_position.xz;
	vec3 uv = vec3(plane / (curb ? curb_meters : texture_meters), 1.0);
	vec4 surface = texture(albedo_rough, uv);
	vec3 color = surface.rgb;
	float roughness = surface.a;
	if (curb) {
		float luma = dot(color, vec3(0.299, 0.587, 0.114));
		color = mix(color, vec3(luma), 0.6) * curb_tint * 1.35;
	} else {
		// a sarjeta: tone abaixo de 1
		float gutter = 1.0 - smoothstep(0.6, 0.99, tone);
		color *= mix(1.0, gutter_darken, gutter);
		roughness = mix(roughness, 0.35, gutter);
	}
	ALBEDO = wet_albedo(color, upright ? 0.4 : 1.0);
	NORMAL_MAP = curb ? vec3(0.5, 0.5, 1.0) : texture(normals, uv).rgb;
	ROUGHNESS = wet_roughness(roughness, upright ? 0.4 : 1.0);
}
