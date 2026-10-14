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

const STATUS_NORMAL: Array[Color] = [Color("2f7a32"), Color("a86a00"), Color("b0281c"), Color("5c4a36")]
const STATUS_COLORBLIND: Array[Color] = [Color("0b5fa0"), Color("d08a00"), Color("c0480a"), Color("5c4a36")]

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
