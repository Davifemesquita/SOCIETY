class_name ThemeBuilder
extends RefCounted
## Monta o Theme único do jogo (seção 10): papel envelhecido, moldura de madeira, detalhe
## dourado; Old Standard TT nos textos e números, Playfair Display nos títulos. O resultado é
## gravado em ui/theme/society_theme.tres por tools/build_theme.gd e vale para o projeto todo
## (gui/theme/custom). Mudou alguma coisa aqui, rode a ferramenta de novo (há teste que confere).
##
## Variações (theme_type_variation): TitleLabel, HeaderLabel, DimLabel, BigLabel, TopBar,
## MenuPanel, NoticePanel, ToastPanel, IconButton, MenuButtonLarge, CardButton, NoticeButton; desde a Fase 43,
## PeriodTitle (título de época), NumberLabel (algarismos tabulares), PlainCard (cartela lisa) e MedallionButton.

const FONT_REGULAR := "res://assets/fonts/OldStandard-Regular.ttf"
const FONT_BOLD := "res://assets/fonts/OldStandard-Bold.ttf"
const FONT_ITALIC := "res://assets/fonts/OldStandard-Italic.ttf"
const FONT_TITLE := "res://assets/fonts/PlayfairDisplay.ttf"
const FONT_SIZE := 18
const ICON_SIZE := 26


## Papel dos painéis (Fase 9): gerado por tools/build_theme.gd; a moldura tem PAPER_FRAME_PX.
const PAPER_TEXTURE := "res://ui/theme/paper_panel.png"
const MENU_TEXTURE := "res://ui/theme/paper_menu.png"
## Cantoneira gravada (Fase 21): o filete em anel e o prego, em fração do raio da chapa.
const CORNER_RING := 0.72
const CORNER_NAIL := 0.22
const PAPER_FRAME_PX := 14


static func build() -> Theme:
	var theme := Theme.new()
	var regular: FontFile = load(FONT_REGULAR)
	var bold: FontFile = load(FONT_BOLD)
	var italic: FontFile = load(FONT_ITALIC)
	var title := FontVariation.new()
	title.base_font = load(FONT_TITLE)
	title.variation_opentype = {"wght": 700}
	theme.default_font = regular
	theme.default_font_size = FONT_SIZE
	_labels(theme, bold, italic, title)
	_panels(theme)
	_buttons(theme, title)
	_inputs(theme)
	_lists(theme)
	_tooltip(theme)
	return theme


static func _labels(theme: Theme, bold: Font, italic: Font, title: Font) -> void:
	for type: StringName in [&"Label", &"RichTextLabel"]:
		theme.set_color(&"font_color" if type == &"Label" else &"default_color", type, UiPalette.INK)
	theme.set_color(&"font_outline_color", &"Label", Color(UiPalette.PAPER, 0.0))
	theme.set_font(&"bold_font", &"RichTextLabel", bold)
	theme.set_font(&"italics_font", &"RichTextLabel", italic)
	theme.set_font(&"normal_font", &"RichTextLabel", theme.default_font)
	theme.set_font_size(&"normal_font_size", &"RichTextLabel", FONT_SIZE)
	theme.set_font_size(&"bold_font_size", &"RichTextLabel", FONT_SIZE)
	_variation(theme, &"TitleLabel", &"Label")
	theme.set_font(&"font", &"TitleLabel", title)
	theme.set_font_size(&"font_size", &"TitleLabel", 28)
	theme.set_color(&"font_color", &"TitleLabel", UiPalette.WOOD)
	# Fase 43: a Playfair fica só nos títulos grandes (TitleLabel, BigLabel, PeriodTitle); o cabeçalho é a Old Standard
	# em negrito, mais firme no tamanho pequeno
	_variation(theme, &"HeaderLabel", &"Label")
	theme.set_font(&"font", &"HeaderLabel", bold)
	theme.set_font_size(&"font_size", &"HeaderLabel", 21)
	theme.set_color(&"font_color", &"HeaderLabel", UiPalette.WOOD)
	_variation(theme, &"PeriodTitle", &"Label")
	theme.set_font(&"font", &"PeriodTitle", title)
	theme.set_font_size(&"font_size", &"PeriodTitle", 40)
	theme.set_color(&"font_color", &"PeriodTitle", UiPalette.WOOD)
	theme.set_color(&"font_shadow_color", &"PeriodTitle", Color(UiPalette.GOLD, 0.35))
	theme.set_constant(&"shadow_offset_x", &"PeriodTitle", 2)
	theme.set_constant(&"shadow_offset_y", &"PeriodTitle", 2)
	# números alinhados em colunas (algarismos tabulares, quando a fonte tem; sem eles, a Old Standard de sempre)
	var tabular := FontVariation.new()
	tabular.base_font = theme.default_font
	tabular.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("tnum"): 1}
	_variation(theme, &"NumberLabel", &"Label")
	theme.set_font(&"font", &"NumberLabel", tabular)
	_variation(theme, &"BigLabel", &"Label")
	theme.set_font(&"font", &"BigLabel", title)
	theme.set_font_size(&"font_size", &"BigLabel", 72)
	theme.set_color(&"font_color", &"BigLabel", UiPalette.WOOD)
	theme.set_color(&"font_shadow_color", &"BigLabel", Color(UiPalette.GOLD, 0.45))
	theme.set_constant(&"shadow_offset_x", &"BigLabel", 3)
	theme.set_constant(&"shadow_offset_y", &"BigLabel", 3)
	_variation(theme, &"DimLabel", &"Label")
	theme.set_font(&"font", &"DimLabel", italic)
	theme.set_font_size(&"font_size", &"DimLabel", 16)
	theme.set_color(&"font_color", &"DimLabel", UiPalette.INK_SOFT)


static func _panels(theme: Theme) -> void:
	# Fase 9: papel envelhecido com moldura de madeira e filete dourado (textura gerada por
	# tools/build_theme.gd em PAPER_TEXTURE; sem ela, o papel liso de antes)
	var paper: StyleBox = _paper_box(12, PAPER_TEXTURE)
	if paper == null:
		var flat := _box(UiPalette.PAPER, UiPalette.WOOD, 3, 4)
		flat.shadow_color = Color(0, 0, 0, 0.35)
		flat.shadow_size = 6
		flat.shadow_offset = Vector2(0, 2)
		flat.set_content_margin_all(12)
		paper = flat
	theme.set_stylebox(&"panel", &"PanelContainer", paper)
	theme.set_stylebox(&"panel", &"Panel", paper)
	_variation(theme, &"TopBar", &"PanelContainer")
	var bar := _box(UiPalette.PAPER, UiPalette.WOOD, 0, 0)
	bar.border_width_bottom = 4
	bar.border_color = UiPalette.GOLD
	bar.set_content_margin_all(6)
	bar.content_margin_left = 12
	bar.content_margin_right = 12
	bar.shadow_color = Color(0, 0, 0, 0.3)
	bar.shadow_size = 5
	theme.set_stylebox(&"panel", &"TopBar", bar)
	_variation(theme, &"MenuPanel", &"PanelContainer")
	var menu: StyleBox = _paper_box(28, MENU_TEXTURE)
	if menu == null:
		var flat_menu := _box(UiPalette.PAPER, UiPalette.WOOD, 5, 6)
		flat_menu.shadow_color = Color(0, 0, 0, 0.5)
		flat_menu.shadow_size = 14
		flat_menu.set_content_margin_all(28)
		menu = flat_menu
	theme.set_stylebox(&"panel", &"MenuPanel", menu)
	_variation(theme, &"NoticePanel", &"PanelContainer")
	var notice := _box(UiPalette.PAPER, UiPalette.GOLD, 2, 4)
	notice.set_content_margin_all(6)
	notice.shadow_color = Color(0, 0, 0, 0.3)
	notice.shadow_size = 4
	theme.set_stylebox(&"panel", &"NoticePanel", notice)
	_variation(theme, &"ToastPanel", &"PanelContainer")
	var toast := _box(UiPalette.WOOD, UiPalette.GOLD, 2, 4)
	toast.set_content_margin_all(10)
	theme.set_stylebox(&"panel", &"ToastPanel", toast)
	# Fase 43: a cartela lisa (sem o grão do papel) por baixo de números e listas, para o texto não brigar com o fundo
	_variation(theme, &"PlainCard", &"PanelContainer")
	var card := _box(Color("f7eed6"), UiPalette.PAPER_SHADE, 1, 3)
	card.set_content_margin_all(6)
	theme.set_stylebox(&"panel", &"PlainCard", card)
	var line := StyleBoxLine.new()
	line.color = UiPalette.PAPER_SHADE
	line.thickness = 2
	theme.set_stylebox(&"separator", &"HSeparator", line)
	var vline := StyleBoxLine.new()
	vline.color = UiPalette.PAPER_SHADE
	vline.thickness = 2
	vline.vertical = true
	theme.set_stylebox(&"separator", &"VSeparator", vline)


static func _buttons(theme: Theme, title: Font) -> void:
	var normal := _button_box(UiPalette.PAPER_DARK, UiPalette.INK_SOFT)
	var hover := _button_box(Color("f6e7bb"), UiPalette.GOLD)
	var pressed := _button_box(UiPalette.PAPER_SHADE, UiPalette.WOOD)
	pressed.border_width_bottom = 1
	pressed.border_width_top = 3
	var disabled := _button_box(UiPalette.PAPER, UiPalette.PAPER_SHADE)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = UiPalette.FOCUS
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(3)
	for type: StringName in [&"Button", &"OptionButton", &"MenuButton"]:
		theme.set_stylebox(&"normal", type, normal)
		theme.set_stylebox(&"hover", type, hover)
		theme.set_stylebox(&"pressed", type, pressed)
		theme.set_stylebox(&"hover_pressed", type, pressed)
		theme.set_stylebox(&"disabled", type, disabled)
		theme.set_stylebox(&"focus", type, focus)
		for color: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
			theme.set_color(color, type, UiPalette.INK)
		theme.set_color(&"font_disabled_color", type, UiPalette.INK_FAINT)
		theme.set_color(&"icon_normal_color", type, Color.WHITE)
		theme.set_color(&"icon_disabled_color", type, Color(1, 1, 1, 0.4))
		theme.set_constant(&"icon_max_width", type, ICON_SIZE)
		theme.set_constant(&"h_separation", type, 6)
	theme.set_icon(&"arrow", &"OptionButton", _arrow_icon(UiPalette.INK))
	_variation(theme, &"IconButton", &"Button")
	theme.set_constant(&"icon_max_width", &"IconButton", 30)
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		var box: StyleBoxFlat = theme.get_stylebox(state, &"Button").duplicate()
		box.set_content_margin_all(4)
		theme.set_stylebox(state, &"IconButton", box)
	_variation(theme, &"MenuButtonLarge", &"Button")
	theme.set_font(&"font", &"MenuButtonLarge", load(FONT_BOLD) as Font)
	theme.set_font_size(&"font_size", &"MenuButtonLarge", 24)
	theme.set_constant(&"icon_max_width", &"MenuButtonLarge", 36)
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		var big: StyleBoxFlat = theme.get_stylebox(state, &"Button").duplicate()
		big.content_margin_left = 18
		big.content_margin_right = 18
		big.content_margin_top = 10
		big.content_margin_bottom = 10
		theme.set_stylebox(state, &"MenuButtonLarge", big)
	_variation(theme, &"CardButton", &"Button")
	theme.set_constant(&"icon_max_width", &"CardButton", 48)
	theme.set_font_size(&"font_size", &"CardButton", 15)
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		var card: StyleBoxFlat = theme.get_stylebox(state, &"Button").duplicate()
		card.set_content_margin_all(4)
		theme.set_stylebox(state, &"CardButton", card)
	# Fase 43: o botão-medalhão (só o ícone, num disco de papel com o aro de madeira)
	_variation(theme, &"MedallionButton", &"Button")
	theme.set_constant(&"icon_max_width", &"MedallionButton", 32)
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		var disc: StyleBoxFlat = theme.get_stylebox(state, &"Button").duplicate()
		disc.set_corner_radius_all(22)
		disc.set_border_width_all(2)
		disc.set_content_margin_all(6)
		theme.set_stylebox(state, &"MedallionButton", disc)
	_variation(theme, &"NoticeButton", &"Button")
	theme.set_constant(&"icon_max_width", &"NoticeButton", 34)
	theme.set_font_size(&"font_size", &"NoticeButton", 16)
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed"]:
		var notice := _box(UiPalette.PAPER if state == &"normal" else Color("f6e7bb"), UiPalette.GOLD, 2, 4)
		notice.content_margin_left = 8
		notice.content_margin_right = 10
		notice.content_margin_top = 5
		notice.content_margin_bottom = 5
		notice.shadow_color = Color(0, 0, 0, 0.3)
		notice.shadow_size = 4
		theme.set_stylebox(state, &"NoticeButton", notice)
	for type: StringName in [&"CheckBox", &"CheckButton"]:
		var empty := StyleBoxEmpty.new()
		empty.set_content_margin_all(3)
		for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
			theme.set_stylebox(state, type, empty)
		theme.set_stylebox(&"focus", type, focus)
		for color: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
			theme.set_color(color, type, UiPalette.INK)
		theme.set_color(&"font_disabled_color", type, UiPalette.INK_FAINT)
	theme.set_icon(&"checked", &"CheckBox", _check_icon(true))
	theme.set_icon(&"unchecked", &"CheckBox", _check_icon(false))
	theme.set_icon(&"checked_disabled", &"CheckBox", _check_icon(true))
	theme.set_icon(&"unchecked_disabled", &"CheckBox", _check_icon(false))
	theme.set_icon(&"checked", &"CheckButton", _check_icon(true))
	theme.set_icon(&"unchecked", &"CheckButton", _check_icon(false))


static func _inputs(theme: Theme) -> void:
	var field := _box(Color("fbf4e2"), UiPalette.INK_SOFT, 1, 2)
	field.set_content_margin_all(5)
	var field_focus := _box(Color("fbf4e2"), UiPalette.FOCUS, 2, 2)
	field_focus.set_content_margin_all(5)
	theme.set_stylebox(&"normal", &"LineEdit", field)
	theme.set_stylebox(&"focus", &"LineEdit", field_focus)
	theme.set_stylebox(&"read_only", &"LineEdit", _box(UiPalette.PAPER, UiPalette.PAPER_SHADE, 1, 2))
	theme.set_color(&"font_color", &"LineEdit", UiPalette.INK)
	theme.set_color(&"font_placeholder_color", &"LineEdit", UiPalette.INK_FAINT)
	theme.set_color(&"caret_color", &"LineEdit", UiPalette.INK)
	theme.set_color(&"selection_color", &"LineEdit", Color(UiPalette.GOLD, 0.4))
	theme.set_color(&"font_uneditable_color", &"LineEdit", UiPalette.INK_FAINT)
	theme.set_icon(&"updown", &"SpinBox", _updown_icon())
	var track := _box(UiPalette.PAPER_SHADE, UiPalette.INK_SOFT, 1, 3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := _box(UiPalette.GOLD, UiPalette.WOOD, 1, 3)
	for type: StringName in [&"HSlider", &"VSlider"]:
		theme.set_stylebox(&"slider", type, track)
		theme.set_stylebox(&"grabber_area", type, fill)
		theme.set_stylebox(&"grabber_area_highlight", type, fill)
		theme.set_icon(&"grabber", type, _knob_icon(UiPalette.WOOD))
		theme.set_icon(&"grabber_highlight", type, _knob_icon(UiPalette.GOLD))
	theme.set_stylebox(&"background", &"ProgressBar", track)
	theme.set_stylebox(&"fill", &"ProgressBar", fill)
	theme.set_color(&"font_color", &"ProgressBar", UiPalette.INK)
	for type: StringName in [&"HScrollBar", &"VScrollBar"]:
		theme.set_stylebox(&"scroll", type, _box(UiPalette.PAPER_DARK, UiPalette.PAPER_SHADE, 0, 4))
		theme.set_stylebox(&"grabber", type, _box(UiPalette.INK_FAINT, UiPalette.INK_FAINT, 0, 4))
		theme.set_stylebox(&"grabber_highlight", type, _box(UiPalette.INK_SOFT, UiPalette.INK_SOFT, 0, 4))
		theme.set_stylebox(&"grabber_pressed", type, _box(UiPalette.WOOD, UiPalette.WOOD, 0, 4))


static func _lists(theme: Theme) -> void:
	var list := _box(Color("f7eed6"), UiPalette.INK_SOFT, 1, 2)
	list.set_content_margin_all(4)
	theme.set_stylebox(&"panel", &"ItemList", list)
	theme.set_stylebox(&"focus", &"ItemList", StyleBoxEmpty.new())
	var selected := _box(Color(UiPalette.GOLD, 0.35), UiPalette.GOLD, 1, 2)
	theme.set_stylebox(&"selected", &"ItemList", selected)
	theme.set_stylebox(&"selected_focus", &"ItemList", selected)
	theme.set_stylebox(&"hovered", &"ItemList", _box(Color(UiPalette.GOLD, 0.15), Color(UiPalette.GOLD, 0.15), 0, 2))
	for color: StringName in [&"font_color", &"font_selected_color", &"font_hovered_color"]:
		theme.set_color(color, &"ItemList", UiPalette.INK)
	var popup := _box(UiPalette.PAPER, UiPalette.WOOD, 2, 2)
	popup.set_content_margin_all(4)
	theme.set_stylebox(&"panel", &"PopupMenu", popup)
	theme.set_stylebox(&"hover", &"PopupMenu", _box(Color(UiPalette.GOLD, 0.35), Color(UiPalette.GOLD, 0.35), 0, 2))
	for color: StringName in [&"font_color", &"font_hover_color", &"font_accelerator_color"]:
		theme.set_color(color, &"PopupMenu", UiPalette.INK)
	theme.set_color(&"font_disabled_color", &"PopupMenu", UiPalette.INK_FAINT)
	theme.set_icon(&"radio_checked", &"PopupMenu", _check_icon(true))
	theme.set_icon(&"radio_unchecked", &"PopupMenu", _check_icon(false))
	var tab := _box(UiPalette.PAPER_DARK, UiPalette.INK_SOFT, 1, 3)
	tab.set_content_margin_all(8)
	var tab_selected := _box(UiPalette.PAPER, UiPalette.WOOD, 2, 3)
	tab_selected.border_width_bottom = 0
	tab_selected.set_content_margin_all(8)
	theme.set_stylebox(&"tab_unselected", &"TabContainer", tab)
	theme.set_stylebox(&"tab_hovered", &"TabContainer", tab)
	theme.set_stylebox(&"tab_selected", &"TabContainer", tab_selected)
	var page := _box(UiPalette.PAPER, UiPalette.WOOD, 2, 2)
	page.set_content_margin_all(14)
	theme.set_stylebox(&"panel", &"TabContainer", page)
	for color: StringName in [&"font_selected_color", &"font_unselected_color", &"font_hovered_color"]:
		theme.set_color(color, &"TabContainer", UiPalette.INK)
	theme.set_constant(&"icon_max_width", &"TabContainer", ICON_SIZE)


static func _tooltip(theme: Theme) -> void:
	var box := _box(Color("fbf4e2"), UiPalette.GOLD, 2, 3)
	box.set_content_margin_all(8)
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 4
	theme.set_stylebox(&"panel", &"TooltipPanel", box)
	theme.set_color(&"font_color", &"TooltipLabel", UiPalette.INK)
	theme.set_font_size(&"font_size", &"TooltipLabel", 16)


## Painel de papel com moldura: textura de 9 fatias (os cantos e a borda não esticam).
static func _paper_box(margin: int, path: String) -> StyleBoxTexture:
	if not ResourceLoader.exists(path):
		return null
	var box := StyleBoxTexture.new()
	box.texture = load(path) as Texture2D
	box.set_texture_margin_all(PAPER_FRAME_PX)
	box.set_content_margin_all(margin)
	return box


## Papel envelhecido (manchas e fibras por ruído, bordas mais escuras), moldura de madeira, filete
## dourado por dentro e cantoneiras. Determinístico: a mesma imagem a cada geração. Desde a Fase 21, o grão
## do `PaperGrain` (vergê e ferrugem) e as cantoneiras gravadas.
static func paper_image(side: int, frame: int, seed_value: int) -> Image:
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	var stains := FastNoiseLite.new()
	stains.seed = seed_value
	stains.frequency = 0.035
	var fibers := FastNoiseLite.new()
	fibers.seed = seed_value + 1
	fibers.frequency = 0.4
	for y: int in side:
		for x: int in side:
			var edge := mini(mini(x, y), mini(side - 1 - x, side - 1 - y))
			var color: Color
			if edge < frame - 6:
				color = UiPalette.WOOD.lerp(UiPalette.WOOD_LIGHT, 0.5 + 0.5 * fibers.get_noise_2d(x * 0.3, y * 3.0))
			elif edge < frame - 3:
				color = UiPalette.GOLD.lerp(UiPalette.GOLD_LIGHT, float(edge - frame + 6) / 3.0)
			else:
				var inside := float(edge - frame + 3) / float(side / 2 - frame + 3)
				var stain := stains.get_noise_2d(x, y) * 0.5 + 0.5
				var fiber := fibers.get_noise_2d(x, y) * 0.5 + 0.5
				color = UiPalette.PAPER.lerp(UiPalette.PAPER_DARK, stain * 0.55 + fiber * 0.15)
				color = color.lerp(UiPalette.PAPER_SHADE, (1.0 - smoothstep(0.0, 0.35, inside)) * 0.45)
				# Fase 21: as linhas do vergê e as manchas de ferrugem
				color = PaperGrain.age(color, x, y, seed_value)
			image.set_pixel(x, y, color)
	# cantoneiras de latão; desde a Fase 21, gravadas: um filete em anel e o prego no meio
	var plate := frame * 0.36
	for corner: Vector2i in [Vector2i(0, 0), Vector2i(side - frame, 0), Vector2i(0, side - frame), Vector2i(side - frame, side - frame)]:
		for y: int in frame:
			for x: int in frame:
				var gap := (Vector2(x, y) - Vector2(frame, frame) * 0.5).length()
				if gap >= plate:
					continue
				var brass := UiPalette.GOLD_LIGHT.lerp(UiPalette.GOLD, gap / plate)
				if absf(gap - plate * CORNER_RING) < 0.75:
					brass = UiPalette.GOLD.darkened(0.35)
				elif gap < plate * CORNER_NAIL:
					brass = UiPalette.WOOD.lerp(UiPalette.GOLD, gap / (plate * CORNER_NAIL) * 0.5)
				image.set_pixel(corner.x + x, corner.y + y, brass)
	return image


static func _variation(theme: Theme, name: StringName, base: StringName) -> void:
	theme.set_type_variation(name, base)


static func _box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	return box


static func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := _box(fill, border, 1, 3)
	box.border_width_bottom = 3
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box


## Desenhos pequenos do Theme (caixa de marcar, seta da lista, botões do número, alça do
## controle deslizante), feitos aqui para combinar com o papel: os do Godot são para fundo escuro.
static func _check_icon(checked: bool) -> ImageTexture:
	var size := 22
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(1, 1, size - 2, size - 2), UiPalette.INK_SOFT)
	image.fill_rect(Rect2i(3, 3, size - 6, size - 6), Color("fbf4e2"))
	if checked:
		image.fill_rect(Rect2i(6, 6, size - 12, size - 12), UiPalette.WOOD)
	return ImageTexture.create_from_image(image)


static func _arrow_icon(color: Color) -> ImageTexture:
	var image := Image.create_empty(14, 10, false, Image.FORMAT_RGBA8)
	for y: int in 7:
		for x: int in range(y, 14 - y):
			image.set_pixel(x, y + 2, color)
	return ImageTexture.create_from_image(image)


static func _updown_icon() -> ImageTexture:
	var image := Image.create_empty(14, 20, false, Image.FORMAT_RGBA8)
	for y: int in 6:
		for x: int in range(6 - y, 8 + y):
			image.set_pixel(x, y + 2, UiPalette.INK)
			image.set_pixel(x, 17 - y, UiPalette.INK)
	return ImageTexture.create_from_image(image)


static func _knob_icon(color: Color) -> ImageTexture:
	var size := 18
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) * 0.5
	for y: int in size:
		for x: int in size:
			var d := (Vector2(x + 0.5, y + 0.5) - center).length()
			if d < 8.5:
				image.set_pixel(x, y, UiPalette.WOOD if d > 6.5 else color)
	return ImageTexture.create_from_image(image)
