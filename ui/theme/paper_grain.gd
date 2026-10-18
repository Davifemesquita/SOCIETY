class_name PaperGrain
extends RefCounted
## Grão do papel envelhecido (Fase 21), gerado no código e determinístico pela semente: as linhas do papel
## vergê (as finas, de LAID_PX em LAID_PX, e as de corrente, de CHAIN_PX em CHAIN_PX), as manchas de ferrugem
## (uma no máximo por quadro de FOX_CELL_PX, com a borda mais escura que o meio) e a borda gasta, escurecida
## por um ruído que a deixa recortada. O papel da interface (`ThemeBuilder.paper_image`) passa cada pixel por
## `age`; a carta do arquipélago desenha `overlay` por cima, na escala da tela (a carta gravada é reduzida ao
## ser desenhada e o grão dela sumiria).

const LAID_PX := 4
const LAID_DARK := 0.02
const CHAIN_PX := 38
const CHAIN_DARK := 0.03
const FOX_CELL_PX := 26
const FOX_CHANCE := 0.14
const FOX_RADIUS_PX := Vector2(2.5, 5.0)
const FOX_COLOR := Color("9c6a3a")
const FOX_STRENGTH := 0.5
## Borda gasta: até onde ela escurece (fração do lado), quanto, e o tom.
const WORN_REACH := 0.07
const WORN_DARK := 0.55
const WORN_COLOR := Color("8a6a40")


## A cor do papel no pixel (x, y), envelhecida: as linhas do vergê e a mancha de ferrugem, se houver.
static func age(color: Color, x: int, y: int, seed_value: int) -> Color:
	var aged := color.darkened(lines(x, y))
	var fox := foxing(x, y, seed_value)
	if fox > 0.0:
		aged = aged.lerp(FOX_COLOR, fox * FOX_STRENGTH)
	return aged


## Quanto as linhas do vergê escurecem o pixel (x, y): cada linha fina com a força dela (o papel feito à mão
## não as marca por igual), que ainda falha ao longo da linha, e as de corrente por cima.
static func lines(x: int, y: int) -> float:
	var dark := 0.0
	if y % LAID_PX == 0:
		var row := fposmod(y * 0.618, 1.0)
		dark = LAID_DARK * (0.4 + 0.6 * row) * (0.6 + 0.4 * sin(x * 0.13 + row * TAU))
	if x % CHAIN_PX == 0:
		dark += CHAIN_DARK
	return dark


## Quanto da mancha de ferrugem cai no pixel (x, y), de 0 a 1: no quadro de FOX_CELL_PX dele, com a chance
## FOX_CHANCE, uma mancha redonda de raio entre FOX_RADIUS_PX, mais forte na borda (a ferrugem espalha para fora).
static func foxing(x: int, y: int, seed_value: int) -> float:
	var cell := Vector2i(floori(float(x) / FOX_CELL_PX), floori(float(y) / FOX_CELL_PX))
	var roll := absi(hash([seed_value, &"fox", cell.x, cell.y]))
	if float(roll % 1000) / 1000.0 >= FOX_CHANCE:
		return 0.0
	var margin := ceili(FOX_RADIUS_PX.y)
	var room := FOX_CELL_PX - margin * 2
	var center := Vector2(cell * FOX_CELL_PX) + Vector2(margin + (roll >> 10) % room, margin + (roll >> 18) % room)
	var radius := lerpf(FOX_RADIUS_PX.x, FOX_RADIUS_PX.y, float((roll >> 4) % 64) / 63.0)
	var gap := Vector2(x + 0.5, y + 0.5).distance_to(center)
	if gap >= radius:
		return 0.0
	var spot := 1.0 - smoothstep(radius * 0.55, radius, gap)
	var rim := 1.0 - absf(gap / radius - 0.75) * 4.0
	return clampf(maxf(spot * 0.6, rim), 0.0, 1.0)


## A camada de grão para pôr por cima de um papel liso de side × side: cor da mancha ou da linha e, no alfa,
## o quanto escurece; nas bordas, a borda gasta.
static func overlay(side: int, seed_value: int) -> Image:
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	var ragged := FastNoiseLite.new()
	ragged.seed = seed_value
	ragged.frequency = 0.05
	var reach := side * WORN_REACH
	for y: int in side:
		for x: int in side:
			var color := Color(WORN_COLOR, lines(x, y) * 2.0)
			var fox := foxing(x, y, seed_value)
			if fox > 0.0:
				color = Color(FOX_COLOR, maxf(color.a, fox * FOX_STRENGTH))
			var edge := float(mini(mini(x, y), mini(side - 1 - x, side - 1 - y)))
			var worn := 1.0 - smoothstep(0.0, reach * (0.6 + 0.4 * ragged.get_noise_2d(x, y)), edge)
			if worn > color.a / WORN_DARK:
				color = Color(WORN_COLOR, worn * WORN_DARK)
			image.set_pixel(x, y, color)
	return image
