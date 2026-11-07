// Fase 309: a névoa nos vales (ValleyMistView). Um plano deitado por camada: a borda mole (redonda), o miolo rasgado por um ruído
// no mundo que anda com o vento, o pé esmaecido onde encosta no chão ou nas árvores (como o proximity fade do StandardMaterial)
// e perto da câmera; a força toda pela hora (amount, posta pela vista a cada quadro).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

global uniform float visual_time;
global uniform vec2 wind_direction;

uniform float amount = 0.0;
uniform vec3 mist_color : source_color = vec3(0.8, 0.82, 0.84);
uniform float opacity = 0.32;
// o tamanho dos rasgos (m), quanto eles andam com o vento (m/s) e a faixa do esmaecido contra o chão (m)
uniform float tear_m = 9.0;
uniform float drift = 0.35;
uniform float softness_m = 3.5;
uniform vec2 near_fade_m = vec2(6.0, 24.0);
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

varying vec3 world_pos;

float mist_hash(vec2 p) {
	// sem sin (Fase 125): o hash inteiro da célula
	uvec2 v = uvec2(ivec2(floor(p))) * uvec2(1597334673u, 3812015801u);
	uint n = (v.x ^ v.y) * 1597334677u;
	return float(n >> 8u) / 16777216.0;
}

float mist_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mist_hash(i), mist_hash(i + vec2(1.0, 0.0)), u.x),
			mix(mist_hash(i + vec2(0.0, 1.0)), mist_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float round_edge = 1.0 - smoothstep(0.0, 1.0, length(centered));
	vec2 flow = world_pos.xz - wind_direction * visual_time * drift;
	float tear = mist_noise(flow / tear_m) * 0.65 + mist_noise(flow / (tear_m * 0.35) + 13.0) * 0.35;
	float body = smoothstep(0.2, 0.85, tear);
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	behind.xyz /= behind.w;
	float soft = clamp((VERTEX.z - behind.z) / softness_m, 0.0, 1.0);
	float near = smoothstep(near_fade_m.x, near_fade_m.y, length(VERTEX));
	ALBEDO = mist_color;
	ALPHA = clamp(amount * opacity * round_edge * body * soft * near, 0.0, 1.0);
}
