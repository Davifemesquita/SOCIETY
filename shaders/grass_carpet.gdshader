// Fase 286: o tapete de capim perto da câmera (GrassCarpetView). Cada tufo cresce nas manchas do prado da Fase 285 (o mesmo
// ruído do terreno: mais alto e escuro no capim alto, baixo e claro no baixo), balança com o vento como a folhagem (só a ponta das
// folhas) e encolhe até sumir de fade_from_m a fade_to_m da câmera (o tapete acaba sem borda). A cor do vértice chega em sRGB.
shader_type spatial;
render_mode cull_disabled;

#include "res://shaders/wet_surface.gdshaderinc"

global uniform float visual_time;
global uniform vec2 wind_direction;
global uniform float wind_strength;

// deslocamento da ponta da folha (m) com o ar parado e com o vento cheio, e a velocidade
uniform float sway_calm = 0.03;
uniform float sway_wind = 0.12;
uniform float sway_speed = 2.2;
uniform float fade_from_m = 55.0;
uniform float fade_to_m = 95.0;
// as manchas do prado (iguais às do terrain.gdshader) e o que elas fazem no tufo
uniform float meadow_patch_m = 9.0;
uniform vec3 tall_tint = vec3(0.64, 0.79, 0.58);
uniform vec3 short_tint = vec3(1.22, 1.15, 0.8);
uniform float tall_height = 1.7;
uniform float short_height = 0.55;
uniform float backlight = 0.3;

varying vec3 patch_tint;

// o mesmo ruído de valor do terrain.gdshader (as manchas batem com o chão)
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float patch = value_noise(origin.xz / meadow_patch_m) * 0.7 + value_noise(origin.xz / (meadow_patch_m * 0.37)) * 0.3;
	float tall = smoothstep(0.52, 0.62, patch);
	float short_grass = 1.0 - smoothstep(0.38, 0.48, patch);
	patch_tint = mix(vec3(1.0), tall_tint, tall) * mix(vec3(1.0), short_tint, short_grass);
	float keep = 1.0 - smoothstep(fade_from_m, fade_to_m, distance(CAMERA_POSITION_WORLD, origin));
	float lift = clamp(VERTEX.y / 0.75, 0.0, 1.0);
	VERTEX.y *= mix(1.0, tall_height, tall) * mix(1.0, short_height, short_grass) * keep;
	VERTEX.xz *= mix(0.2, 1.0, keep);
	// o vento no espaço do modelo (cada tufo vem girado), só na ponta
	mat3 to_model = inverse(mat3(MODEL_MATRIX));
	vec3 along = to_model * vec3(wind_direction.x, 0.0, wind_direction.y);
	along.y = 0.0;
	along = length(along) > 0.0001 ? normalize(along) : vec3(1.0, 0.0, 0.0);
	float strength = clamp(wind_strength, 0.0, 1.0);
	float phase = origin.x * 0.31 + origin.z * 0.23;
	float t = visual_time * sway_speed * (1.0 + strength);
	float push = mix(sway_calm, sway_wind, strength) * (0.6 + 0.4 * sin(t + phase)) + strength * sway_wind * 0.5;
	VERTEX += along * push * lift * lift * keep;
}

void fragment() {
	vec3 c = COLOR.rgb;
	vec3 base = mix(pow((c + vec3(0.055)) / vec3(1.055), vec3(2.4)), c / vec3(12.92), lessThan(c, vec3(0.04045))) * patch_tint;
	ALBEDO = wet_albedo(base, 1.0);
	ROUGHNESS = wet_roughness(0.92, 1.0);
	BACKLIGHT = base * backlight;
}
