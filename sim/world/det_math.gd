class_name DetMath
extends RefCounted
## Contas que dão o mesmo resultado, bit a bit, no Windows e no Linux (Fase 46, achado pelo CI): o seno, o cosseno e
## a potência do C variam no último bit de uma biblioteca para outra, e o terreno v2 guarda o hash das alturas cruas
## (um save v2 feito no Windows abriria com terrain_mismatch no Linux). Aqui só entram soma, subtração, multiplicação,
## divisão e fposmod, que o IEEE 754 obriga a arredondar igual em toda máquina; o resto é série com termos de sobra.

const LN2 := 0.6931471805599453
const HALF_PI := PI * 0.5


## Vector2(cos, sin) do ângulo (radianos).
static func sin_cos(angle: float) -> Vector2:
	var a := fposmod(angle + PI, TAU) - PI
	var quarter := roundi(a / HALF_PI)
	var r := a - quarter * HALF_PI
	var r2 := r * r
	# séries de Taylor até r^17 e r^18: |r| <= pi/4, o erro fica abaixo de 1e-19
	var s := r
	var c := 1.0
	var term_s := r
	var term_c := 1.0
	for k: int in range(1, 10):
		term_s *= -r2 / float((2 * k) * (2 * k + 1))
		term_c *= -r2 / float((2 * k - 1) * (2 * k))
		s += term_s
		c += term_c
	match posmod(quarter, 4):
		1:
			return Vector2(-s, c)
		2:
			return Vector2(-c, -s)
		3:
			return Vector2(s, -c)
	return Vector2(c, s)


## Gira o ponto pelo ângulo cujo Vector2(cos, sin) é "turn" (sem chamar seno de novo a cada ponto).
static func rotate(point: Vector2, turn: Vector2) -> Vector2:
	return Vector2(point.x * turn.x - point.y * turn.y, point.x * turn.y + point.y * turn.x)


## x elevado a y, para x >= 0 (0 dá 0).
static func power(x: float, y: float) -> float:
	if x <= 0.0:
		return 0.0
	return exp_of(y * ln(x))


## Logaritmo natural de x > 0: x = m × 2^e com m perto de 1, e ln(m) = 2 atanh((m − 1) / (m + 1)).
static func ln(x: float) -> float:
	var m := x
	var e := 0
	while m > 1.4142135623730951:
		m *= 0.5
		e += 1
	while m < 0.7071067811865476:
		m *= 2.0
		e -= 1
	var z := (m - 1.0) / (m + 1.0)
	var z2 := z * z
	var term := z
	var sum := z
	# |z| <= 0,1716: z^2 < 0,03, 18 termos passam muito da precisão do double
	for k: int in range(1, 18):
		term *= z2
		sum += term / float(2 * k + 1)
	return 2.0 * sum + e * LN2


## e elevado a t: t = k ln2 + r com |r| <= ln2/2, e^r pela série, e o 2^k por multiplicações exatas.
static func exp_of(t: float) -> float:
	var k := roundi(t / LN2)
	var r := t - k * LN2
	var term := 1.0
	var sum := 1.0
	for n: int in range(1, 22):
		term *= r / float(n)
		sum += term
	var scale := 2.0 if k > 0 else 0.5
	for i: int in absi(k):
		sum *= scale
	return sum
