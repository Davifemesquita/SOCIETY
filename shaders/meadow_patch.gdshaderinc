// Fase 325: as manchas do prado (Fase 285), as mesmas no terreno e no tapete de capim (Fase 286). Antes eram duas oitavas de ruído
// de valor: os nós dele ficam numa grade alinhada com os eixos, cada nó vira um quadrado de cantos redondos e, dentro da célula, as
// curvas de nível são quase retas; com o corte estreito das manchas (o smoothstep do capim alto e do baixo), o prado ficava em
// quadrados claros e escuros (e, de longe, em facetas). Aqui a oitava larga é ruído de gradiente (curvas de nível curvas), lido
// girado (MEADOW_TURN_RAD) sobre as coordenadas torcidas por um ruído largo (MEADOW_WARP vezes o tamanho da mancha), com a mesma
// média e mais ou menos o mesmo espalhamento de antes (MEADOW_GRADIENT_GAIN): as manchas cobrem o mesmo tanto do prado. A oitava
// fina segue de valor, girada mais uma vez. Quem inclui define antes o hash21 e o value_noise (os mesmos nos dois shaders).
const float MEADOW_TURN_RAD = 0.61;
const float MEADOW_WARP = 1.0;
const float MEADOW_WARP_SCALE = 2.6;
const float MEADOW_GRADIENT_GAIN = 0.8;

mat2 meadow_turn(float angle) {
	return mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
}

float meadow_corner(vec2 node, vec2 offset) {
	float angle = hash21(node + vec2(13.1, 71.7)) * 6.2831853;
	return dot(vec2(cos(angle), sin(angle)), offset);
}

// ruído de gradiente (Perlin) de -0,7 a 0,7, com a curva de quinto grau entre os nós
float meadow_gradient(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(meadow_corner(i, f), meadow_corner(i + vec2(1.0, 0.0), f - vec2(1.0, 0.0)), u.x),
			mix(meadow_corner(i + vec2(0.0, 1.0), f - vec2(0.0, 1.0)), meadow_corner(i + vec2(1.0, 1.0), f - vec2(1.0, 1.0)), u.x), u.y);
}

float meadow_patch(vec2 xz, float patch_m) {
	vec2 wide = xz / (patch_m * MEADOW_WARP_SCALE);
	vec2 warp = vec2(value_noise(wide), value_noise(wide + vec2(31.7, 11.3))) - 0.5;
	vec2 a = meadow_turn(MEADOW_TURN_RAD) * ((xz + warp * patch_m * MEADOW_WARP) / patch_m);
	float broad = 0.5 + meadow_gradient(a) * MEADOW_GRADIENT_GAIN;
	// Fase 334: a oitava fina também de gradiente (de valor, as curvas de nível dentro de cada célula eram quase retas e, com o
	// capim alto mais escuro, as manchas saíam em facetas de bordas retas)
	float fine = 0.5 + meadow_gradient(meadow_turn(MEADOW_TURN_RAD) * a / 0.37 + vec2(5.3, 9.1)) * MEADOW_GRADIENT_GAIN;
	return broad * 0.7 + fine * 0.3;
}
