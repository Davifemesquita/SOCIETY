// Fase 35: as ondas que chegam à praia, a mesma conta na água (espuma) e no terreno (areia molhada e espraiado), com
// o mesmo TIME: a crista anda para a costa e continua areia acima até morrer. coast é a distância até a costa com
// sinal (CoastField: positiva na terra, negativa na água), em metros.
const float COAST_WAVE_SPACING_M = 7.0;
const float COAST_WAVE_SPEED = 0.9;

float coast_phase(float coast, float time) {
	return -coast * 6.2831853 / COAST_WAVE_SPACING_M + time * COAST_WAVE_SPEED;
}
