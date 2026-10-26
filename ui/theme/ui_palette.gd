class_name UiPalette
extends RefCounted
## Cores da interface (seção 10: papel envelhecido, madeira e dourado, legibilidade antes da
## decoração). O Theme, os ícones gerados e os indicadores de estado tiram as cores daqui.
## Indicador de estado (bom, parcial, ruim) tem duas paletas: a normal (semáforo) e a do modo
## para daltonismo (azul, laranja e vermelhão, da paleta de Okabe e Ito), escolhida nas opções.

enum Status { GOOD, PARTIAL, BAD, NEUTRAL }

const PAPER := Color("efe3c6")
const PAPER_DARK := Color("e0d0aa")
const PAPER_SHADE := Color("cdb88c")
const INK := Color("2e2116")
const INK_SOFT := Color("5c4a36")
const INK_FAINT := Color("8a765c")
const WOOD := Color("4a3020")
const WOOD_LIGHT := Color("6b4a30")
const GOLD := Color("b8892e")
const GOLD_LIGHT := Color("d9b45a")
const BURGUNDY := Color("6e2a26")
const SEA := Color("5d7f8c")
const ALERT := Color("c8641e")
const PROTEST := Color("a8281e")

## Fase 43: os indicadores passam de 4,5:1 sobre o papel (WCAG para texto); o verde, o âmbar e, no modo para
## daltonismo, o laranja e o vermelhão escureceram o mínimo para isso (o teste de contraste confere).
const STATUS_NORMAL: Array[Color] = [Color("236326"), Color("8a5600"), Color("b0281c"), Color("5c4a36")]
const STATUS_COLORBLIND: Array[Color] = [Color("0b5fa0"), Color("8c5200"), Color("9c3a08"), Color("5c4a36")]
## Fase 43: o contorno do foco (3:1 sobre o botão, WCAG para componentes): o dourado não chegava lá.
const FOCUS := Color("7a4f12")

## Modo para daltonismo nos indicadores (opção da interface, gravada pelo Settings).
static var colorblind: bool = false


static func status(value: Status) -> Color:
	return (STATUS_COLORBLIND if colorblind else STATUS_NORMAL)[value]


## Estado de uma fração atendida (necessidade, atendimento) pelos limites do GameConfig.
static func status_of(fraction: float, met: float, partial: float) -> Status:
	if fraction >= met:
		return Status.GOOD
	return Status.PARTIAL if fraction >= partial else Status.BAD


## Pinta o texto do rótulo com a cor do estado (no lugar de modulate, que escurece no papel).
static func paint(control: Control, value: Status) -> void:
	control.add_theme_color_override(&"font_color", status(value))


static func unpaint(control: Control) -> void:
	control.remove_theme_color_override(&"font_color")
