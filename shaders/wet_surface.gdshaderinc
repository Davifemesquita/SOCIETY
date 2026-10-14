// Chão e paredes molhados pela chuva (Fase 9): o uniforme global wetness (0 a 1) vem do
// WeatherView. Molhado escurece a cor e deixa a superfície lisa e brilhante.
global uniform float wetness;

vec3 wet_albedo(vec3 albedo, float exposure) {
	return albedo * mix(1.0, 0.62, wetness * exposure);
}

float wet_roughness(float roughness, float exposure) {
	return roughness * mix(1.0, 0.3, wetness * exposure);
}
