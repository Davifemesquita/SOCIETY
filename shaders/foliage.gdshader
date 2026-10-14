// Árvores (Fase 9): a cor da folhagem ou da madeira, balançando ao vento. O balanço cresce com a
// altura no modelo (o pé fica parado), tem a fase do lugar de cada árvore (não balançam juntas) e
// anda no tempo visual (para na pausa). A chuva escurece e dá brilho.
shader_type spatial;
render_mode cull_disabled;

#include "res://shaders/wet_surface.gdshaderinc"

global uniform float visual_time;

uniform vec4 albedo : source_color = vec4(0.3, 0.45, 0.2, 1.0);
uniform float roughness = 0.95;
// deslocamento máximo (m por m de altura) e a velocidade do balanço
uniform float sway = 0.035;
uniform float sway_speed = 1.3;
// altura do modelo onde o balanço chega ao máximo
uniform float model_height = 6.0;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = origin.x * 0.13 + origin.z * 0.17;
	float lift = clamp(VERTEX.y / model_height, 0.0, 1.0);
	float bend = lift * lift * sway * model_height;
	float gust = sin(visual_time * sway_speed + phase) + 0.4 * sin(visual_time * sway_speed * 2.3 + phase * 1.7);
	VERTEX.x += gust * bend;
	VERTEX.z += 0.5 * cos(visual_time * sway_speed * 0.8 + phase) * bend;
}

void fragment() {
	ALBEDO = wet_albedo(albedo.rgb, 1.0);
	ROUGHNESS = wet_roughness(roughness, 1.0);
}
