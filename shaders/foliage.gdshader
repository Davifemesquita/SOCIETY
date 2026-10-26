// Árvores (Fase 9) e, desde a Fase 22, as plantações e o capim: a cor da folhagem ou da madeira (ou a
// cor do vértice, em sRGB), balançando ao vento. O balanço cresce com a altura no modelo (o pé fica
// parado), tem a fase do lugar de cada planta (não balançam juntas) e anda no tempo visual (para na
// pausa). Desde a Fase 22 o vento do WeatherView manda: a planta deita para onde ele sopra
// (wind_direction) e balança mais e mais depressa quanto mais forte ele é (wind_strength); com o ar
// parado sobra a brisa (calm). A chuva escurece e dá brilho.
shader_type spatial;
render_mode cull_disabled;

#include "res://shaders/wet_surface.gdshaderinc"

global uniform float visual_time;
global uniform vec2 wind_direction;
global uniform float wind_strength;

uniform vec4 albedo : source_color = vec4(0.3, 0.45, 0.2, 1.0);
uniform bool use_vertex_color = false;
uniform float roughness = 0.95;
// deslocamento máximo (m por m de altura) e a velocidade do balanço
uniform float sway = 0.035;
uniform float sway_speed = 1.3;
// altura do modelo onde o balanço chega ao máximo
uniform float model_height = 6.0;
// balanço que sobra com o ar parado, quanto o vento cheio deita a planta e quanto apressa o balanço
uniform float calm = 0.3;
uniform float lean = 1.4;
uniform float hurry = 0.8;
// Fase 41: luz de trás nas folhas (o sol atravessando a copa); a madeira (cor sem predomínio do verde) não ganha
uniform float backlight = 0.35;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = origin.x * 0.13 + origin.z * 0.17;
	float lift = clamp(VERTEX.y / model_height, 0.0, 1.0);
	float bend = lift * lift * sway * model_height;
	// o vento no plano, levado para o espaço do modelo (cada instância vem girada)
	mat3 to_model = inverse(mat3(MODEL_MATRIX));
	vec3 along = to_model * vec3(wind_direction.x, 0.0, wind_direction.y);
	vec3 across = to_model * vec3(-wind_direction.y, 0.0, wind_direction.x);
	along.y = 0.0;
	across.y = 0.0;
	along = length(along) > 0.0001 ? normalize(along) : vec3(1.0, 0.0, 0.0);
	across = length(across) > 0.0001 ? normalize(across) : vec3(0.0, 0.0, 1.0);
	float strength = clamp(wind_strength, 0.0, 1.0);
	float t = visual_time * sway_speed * (1.0 + hurry * strength);
	float gust = sin(t + phase) + 0.4 * sin(t * 2.3 + phase * 1.7);
	float breeze = calm + strength;
	// deitada a favor do vento e balançando em volta disso; de lado, menos
	float push = lean * strength * (0.75 + 0.25 * sin(t * 0.37 + phase * 0.5)) + gust * breeze * 0.6;
	float side = 0.35 * cos(t * 0.8 + phase) * breeze;
	VERTEX += (along * push + across * side) * bend;
}

void fragment() {
	vec3 base = albedo.rgb;
	if (use_vertex_color) {
		// a cor do vértice (e da instância) chega em sRGB
		vec3 c = COLOR.rgb;
		base *= mix(pow((c + vec3(0.055)) / vec3(1.055), vec3(2.4)), c / vec3(12.92), lessThan(c, vec3(0.04045)));
	}
	ALBEDO = wet_albedo(base, 1.0);
	ROUGHNESS = wet_roughness(roughness, 1.0);
	float leafy = smoothstep(1.05, 1.35, base.g / max(base.r, 0.001));
	BACKLIGHT = base * backlight * leafy;
}
