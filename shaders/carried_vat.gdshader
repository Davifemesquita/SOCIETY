// Carga na mão do pedestre (Fase 15): cesto ou saco, andando junto com o boneco do
// shaders/pedestrian_vat.gdshader pela mesma conta (mesmo dado da instância: x = início do trecho no tempo
// visual, y = comprimento, z = velocidade) e, em w, o passo da animação de carregar (m por ciclo), que dá o
// balanço. A peça fica em hold, no referencial do boneco (de frente para −Z). Cor no vértice, em sRGB.
shader_type spatial;
render_mode cull_disabled;

global uniform float visual_time;

uniform vec3 hold = vec3(0.0, 1.0, -0.32);
uniform float sway_m = 0.025;

varying vec3 tint;

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	vec4 data = INSTANCE_CUSTOM;
	float elapsed = max(visual_time - data.x, 0.0);
	float dist = min(elapsed * data.z, data.y);
	// dois balanços por ciclo (um a cada passo)
	float sway = data.w > 0.0 ? sin(dist / data.w * 12.566) * sway_m : 0.0;
	VERTEX += hold + vec3(0.0, sway, 0.0);
	VERTEX.z -= dist;
	tint = srgb_to_linear(COLOR.rgb);
}

void fragment() {
	ALBEDO = tint;
	ROUGHNESS = 0.9;
}
