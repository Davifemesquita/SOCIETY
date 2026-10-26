extends GdUnitTestSuite
## Interface enxuta (Fase 43): contraste WCAG das cores do Theme (4,5:1 no texto, 3:1 no foco e nos componentes),
## tamanho mínimo de fonte em cada escala com o aviso abaixo de 18 px, cadeia de foco do menu, chaves novas em pt_BR e
## en, o feed de avisos (contador, silenciar, pausa no alerta, duração), o painel dos prédios que encolhe e o "reduzir
## movimento".

var _theme: Theme


func before_test() -> void:
	_theme = ThemeBuilder.build()


func after_test() -> void:
	Settings.reduce_motion = false
	Settings.pause_on_alert = false
	Settings.notice_duration = 1.0
	Settings.muted_notices = PackedStringArray()
	GameClock.set_speed(TickClock.PAUSED)


## Contraste WCAG entre duas cores (de 1 a 21).
static func contrast(a: Color, b: Color) -> float:
	var high := maxf(luminance(a), luminance(b))
	var low := minf(luminance(a), luminance(b))
	return (high + 0.05) / (low + 0.05)


## Luminância relativa do WCAG (o sRGB linearizado; o get_luminance() do Godot não lineariza).
static func luminance(color: Color) -> float:
	var linear := color.srgb_to_linear()
	return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b


func _fill(type: StringName, state: StringName) -> Color:
	var box := _theme.get_stylebox(state, type)
	if box is StyleBoxFlat:
		return (box as StyleBoxFlat).bg_color
	return UiPalette.PAPER


func test_text_colours_reach_wcag_on_their_backgrounds() -> void:
	var paper := UiPalette.PAPER
	var pairs := {
		"texto no papel": [_theme.get_color(&"font_color", &"Label"), paper],
		"cabeçalho no papel": [_theme.get_color(&"font_color", &"HeaderLabel"), paper],
		"nota no papel": [_theme.get_color(&"font_color", &"DimLabel"), paper],
		"botão": [_theme.get_color(&"font_color", &"Button"), _fill(&"Button", &"normal")],
		"botão sob o mouse": [_theme.get_color(&"font_hover_color", &"Button"), _fill(&"Button", &"hover")],
		"botão apertado": [_theme.get_color(&"font_pressed_color", &"Button"), _fill(&"Button", &"pressed")],
		"campo": [_theme.get_color(&"font_color", &"LineEdit"), _fill(&"LineEdit", &"normal")],
		"dica": [_theme.get_color(&"font_color", &"TooltipLabel"), _fill(&"TooltipPanel", &"panel")],
		"lista": [_theme.get_color(&"font_color", &"ItemList"), _fill(&"ItemList", &"panel")],
	}
	for label: String in pairs:
		var pair: Array = pairs[label]
		var text: Color = pair[0]
		var back: Color = pair[1]
		var ratio := contrast(text, back)
		assert_float(ratio).override_failure_message("%s: %.2f:1" % [label, ratio]).is_greater_equal(4.5)
	# os indicadores de estado (as duas paletas) sobre o papel
	for palette: Array[Color] in [UiPalette.STATUS_NORMAL, UiPalette.STATUS_COLORBLIND]:
		for color: Color in palette:
			assert_float(contrast(color, paper)).override_failure_message("estado %s: %.2f:1" % [color.to_html(false),
					contrast(color, paper)]).is_greater_equal(4.5)


func test_focus_and_component_borders_reach_three_to_one() -> void:
	var focus := _theme.get_stylebox(&"focus", &"Button") as StyleBoxFlat
	for state: StringName in [&"normal", &"hover", &"pressed"]:
		var ratio := contrast(focus.border_color, _fill(&"Button", state))
		assert_float(ratio).override_failure_message("foco sobre %s: %.2f:1" % [state, ratio]).is_greater_equal(3.0)
	var normal := _theme.get_stylebox(&"normal", &"Button") as StyleBoxFlat
	assert_float(contrast(normal.border_color, UiPalette.PAPER)).is_greater_equal(3.0)


func test_font_sizes_hold_at_every_scale_and_warn_below_eighteen_pixels() -> void:
	var smallest := ThemeBuilder.FONT_SIZE
	for type: StringName in [&"DimLabel", &"CardButton", &"NoticeButton", &"TooltipLabel"]:
		smallest = mini(smallest, _theme.get_font_size(&"font_size", type))
	assert_int(smallest).is_greater_equal(15)
	var config := GameConfig.get_default()
	assert_float(config.ui_scale_max).is_equal(2.0)
	# no mínimo da escala, nada abaixo de 12 px; o aviso aparece quando o corpo do texto fica abaixo de 18 px
	assert_float(smallest * config.ui_scale_min).is_greater_equal(12.0)
	assert_bool(OptionsDialog.small_text(0.9)).is_true()
	assert_bool(OptionsDialog.small_text(1.0)).is_false()
	assert_bool(OptionsDialog.small_text(2.0)).is_false()
	# a escala de verdade cabe na janela: 200% só a partir de 4K; abaixo de 100% sem limite
	var before := Settings.ui_scale
	Settings.ui_scale = 2.0
	assert_float(Settings.effective_ui_scale(1920.0)).is_equal(1.0)
	assert_float(Settings.effective_ui_scale(2560.0)).is_equal_approx(2560.0 / 1920.0, 0.001)
	assert_float(Settings.effective_ui_scale(3840.0)).is_equal(2.0)
	assert_bool(OptionsDialog.limited(2.0, Settings.effective_ui_scale(1920.0))).is_true()
	Settings.ui_scale = 0.8
	assert_float(Settings.effective_ui_scale(1280.0)).is_equal(0.8)
	Settings.ui_scale = before
	# a Playfair só nos títulos grandes
	assert_object(_theme.get_font(&"font", &"HeaderLabel")).is_not_same(_theme.get_font(&"font", &"TitleLabel"))
	for variation: StringName in [&"PeriodTitle", &"NumberLabel", &"PlainCard", &"MedallionButton"]:
		assert_bool(_theme.is_type_variation(variation, _theme.get_type_variation_base(variation))) \
				.override_failure_message(String(variation)).is_true()


func test_the_main_menu_keeps_a_focus_chain() -> void:
	var menu := (load("res://ui/screens/boot_screen.tscn") as PackedScene).instantiate() as Control
	add_child(menu)
	var buttons: Array[Button] = []
	for node: Node in menu.find_children("BOOT_*", "Button", true, false):
		var button := node as Button
		if button.focus_mode == Control.FOCUS_ALL:
			buttons.append(button)
	assert_int(buttons.size()).is_greater_equal(6)
	await await_idle_frame()
	# do primeiro, descendo, o foco passa por todos os botões do menu sem sair dele
	var visited: Dictionary[Button, bool] = {}
	var current: Control = buttons[0]
	for step: int in buttons.size() * 2:
		if current is Button:
			visited[current as Button] = true
		var next := current.find_valid_focus_neighbor(SIDE_BOTTOM)
		if next == null:
			break
		current = next
	var enabled := buttons.filter(func(button: Button) -> bool: return not button.disabled)
	assert_int(visited.size()).is_greater_equal(enabled.size())
	menu.queue_free()


func test_new_keys_exist_in_both_languages() -> void:
	var keys: Array[String] = ["OPTIONS_SMALL_TEXT", "OPTIONS_READABLE_FONT", "OPTIONS_REDUCE_MOTION", "OPTIONS_NOTICE_DURATION",
			"OPTIONS_PAUSE_ON_ALERT", "OPTIONS_NOTICE_CATEGORY_TIP", "OPTIONS_SECONDS"]
	for category: String in NotificationFeed.CATEGORIES:
		keys.append("NOTICE_CATEGORY_" + category.to_upper())
	for locale: String in ["pt_BR", "en"]:
		TranslationServer.set_locale(locale)
		for key: String in keys:
			assert_str(tr(key)).override_failure_message("%s em %s" % [key, locale]).is_not_equal(key)
	TranslationServer.set_locale("pt_BR")


func _feed() -> NotificationFeed:
	var sim := SimFixture.simulation(Vector2i(40, 20))
	var feed: NotificationFeed = auto_free(NotificationFeed.new())
	add_child(feed)
	feed.setup(sim)
	return feed


func test_repeated_notices_become_one_block_with_a_counter() -> void:
	var feed := _feed()
	var notice := NoticeWatcher.Notice.new("shortage/0/fish", "notice_shortage", "NOTICE_SHORTAGE", ["peixe", "ilha"])
	feed.push(notice)
	feed.push(notice)
	feed.push(notice)
	assert_int(feed.shown().size()).is_equal(1)
	assert_int(feed.count_of(notice.key)).is_equal(3)
	assert_str(feed.get_child(0).get(&"text")).contains("×3")
	assert_str(NotificationFeed.category_of("fire/12")).is_equal("alert")
	assert_str(NotificationFeed.category_of("shortage/0/fish")).is_equal("economy")


func test_muted_categories_stay_out_and_alerts_can_pause() -> void:
	var feed := _feed()
	Settings.mute_notice("economy", true)
	feed.push(NoticeWatcher.Notice.new("shortage/0/fish", "notice_shortage", "NOTICE_SHORTAGE", ["peixe", "ilha"]))
	assert_int(feed.shown().size()).is_equal(0)
	Settings.mute_notice("economy", false)
	assert_bool(Settings.is_notice_muted("economy")).is_false()
	GameClock.set_speed(1)
	Settings.pause_on_alert = true
	var fire := NoticeWatcher.Notice.new("fire/7", "notice_fire", "NOTICE_FIRE", ["casa"])
	fire.status = UiPalette.Status.BAD
	feed.push(fire)
	assert_int(GameClock.clock.speed_index).is_equal(TickClock.PAUSED)
	# a duração vem das opções
	Settings.notice_duration = 2.0
	assert_float(Settings.notice_seconds()).is_equal(GameConfig.get_default().notice_seconds * 2.0)


func test_reduce_motion_stops_the_interface_animations() -> void:
	Settings.reduce_motion = true
	assert_bool(SceneFader.still()).is_true()
	Settings.reduce_motion = false
	assert_bool(SceneFader.still()).is_equal(SceneFader.is_instant())


func test_the_build_items_panel_shrinks_to_its_content() -> void:
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	GameScreen.flat_world = true
	add_child(game)
	var hud := game.hud
	# a última categoria de prédios (porto) tem poucos cartões: o painel fica do tamanho deles
	hud._select_category(hud._categories().size() - 2)
	var cards := hud._items.get_child_count()
	assert_float(hud._items.custom_minimum_size.x).is_equal(
			float(mini(cards, Hud.ITEMS_PER_ROW) * Hud.CARD_WIDTH + (mini(cards, Hud.ITEMS_PER_ROW) - 1) * Hud.ITEM_GAP))
	# a aba de produção escolhida mostra o nome da classe ao lado do medalhão
	hud._select_category(1)
	assert_str(hud._category_buttons[1].text).is_not_empty()
	assert_str(hud._category_buttons[2].text).is_empty()
	GameScreen.flat_world = false
	game.queue_free()
	await await_idle_frame()
