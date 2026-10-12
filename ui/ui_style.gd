class_name UiStyle
extends RefCounted
## Estilo provisório dos painéis até o Theme da Fase 7: fundo opaco, para o texto não se
## misturar com a cena atrás.

const PANEL_COLOR := Color(0.11, 0.11, 0.13, 0.95)


static func panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	return style
