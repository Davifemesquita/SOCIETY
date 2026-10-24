class_name Hud
extends Control
## Interface da partida: barra superior (data e hora, velocidade, dinheiro com o saldo, população
## por classe, os eventos em andamento, estatísticas, rotas, encomendas, salvar, carregar e o menu), menu de construção por categoria
## com as camadas de mapa, painel do selecionado, notificações, avisos e a dica ao lado do cursor.
## Só lê o estado e chama a ferramenta; nenhuma regra de jogo aqui.

signal save_requested()
signal load_requested()
## O jogador pediu o menu da partida (botão da barra).
signal menu_requested()
## A camada de mapa escolhida mudou (NONE = nenhuma).
signal overlay_changed(layer: MapOverlays.Layer)

const MESSAGE_SECONDS := 3.0
const REFRESH_SECONDS := 0.5
const CARD_WIDTH := 112
## Fase 30: o dinheiro e a população andam até o valor novo em COUNT_S; um ganho grande (BIG_GAIN moedas ou
## BIG_GAIN_FRACTION do saldo) pulsa o dinheiro em GAIN_COLOR. Com as animações desligadas (SceneFader.is_instant:
## testes, headless) o texto vai direto ao valor final.
const COUNT_S := 0.4
const BIG_GAIN := 500.0
const BIG_GAIN_FRACTION := 0.05
const GAIN_COLOR := Color(1.0, 0.82, 0.35)
const PULSE_SCALE := 1.15

var selection_panel: SelectionPanel
var statistics_window: StatisticsWindow
var ship_panel: ShipPanel
var route_window: RouteWindow
var trade_window: TradeWindow
var mission_window: MissionWindow
var diplomacy_window: DiplomacyWindow
var specialist_window: SpecialistWindow
var notifications: NotificationFeed
var goal_panel: GoalPanel
var overlay_layer: MapOverlays.Layer = MapOverlays.Layer.NONE

var _tool: BuildTool
var _simulation: Simulation
var _clock_label := Label.new()
var _money_label := Label.new()
var _population := HBoxContainer.new()
var _population_labels: Dictionary[StringName, Label] = {}
## Fase 30: o valor que cada contador mostra agora (NAN antes do primeiro) e a animação dele.
var _money_shown: float = NAN
var _money_balance: float = 0.0
var _money_tween: Tween
var _population_shown: Dictionary[StringName, float] = {}
var _population_tweens: Dictionary[StringName, Tween] = {}
## Selos dos eventos em andamento (Fase 11) e o botão das encomendas, com quantas estão abertas.
var _event_chips := HBoxContainer.new()
var _missions_button: Button
var _rivals_button: Button
var _specialists_button: Button
var _chips_signature: String = ""
var _speed_buttons: Array[Button] = []
var _category_buttons: Array[Button] = []
var _overlay_buttons: Dictionary[MapOverlays.Layer, Button] = {}
var _items := HFlowContainer.new()
## Coluna de baixo: a dica em cima do menu de construção (a dica nunca cobre o menu).
var _bottom := VBoxContainer.new()
var _item_buttons: Dictionary[StringName, Button] = {}
## Cartão do paralelepípedo (Fase 8), travado até a classe que o libera (null fora da aba).
var _paved_button: Button
var _hint_phase: float = 0.0
var _message_panel := PanelContainer.new()
var _message := Label.new()
var _hint_panel := PanelContainer.new()
var _hint := Label.new()
var _cursor_panel := PanelContainer.new()
var _cursor_label := Label.new()
var _message_left: float = 0.0
var _refresh_left: float = 0.0
var _category: int = 0


func setup(tool: BuildTool, simulation: Simulation) -> void:
	_tool = tool
	_simulation = simulation
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_bar()
	_build_build_menu()
	selection_panel = SelectionPanel.new()
	_pin(selection_panel, Vector2(0.0, 1.0), Vector2(16, -150), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_BEGIN)
	add_child(selection_panel)
	selection_panel.setup(tool, simulation)
	ship_panel = ShipPanel.new()
	_pin(ship_panel, Vector2(0.0, 1.0), Vector2(16, -150), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_BEGIN)
	add_child(ship_panel)
	ship_panel.setup(tool, simulation)
	notifications = NotificationFeed.new()
	_pin(notifications, Vector2(1.0, 0.0), Vector2(-16, 72), Control.GROW_DIRECTION_BEGIN, Control.GROW_DIRECTION_END)
	add_child(notifications)
	notifications.setup(simulation)
	goal_panel = GoalPanel.new()
	goal_panel.name = "Goals"
	_pin(goal_panel, Vector2(0.0, 0.0), Vector2(16, 72), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_END)
	add_child(goal_panel)
	goal_panel.setup(simulation)
	statistics_window = StatisticsWindow.new()
	_pin(statistics_window, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	add_child(statistics_window)
	statistics_window.setup(simulation)
	route_window = RouteWindow.new()
	_pin(route_window, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	add_child(route_window)
	route_window.setup(simulation, tool)
	trade_window = TradeWindow.new()
	_pin(trade_window, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	add_child(trade_window)
	trade_window.setup(simulation)
	selection_panel.trade_requested.connect(trade_window.open)
	mission_window = MissionWindow.new()
	_pin(mission_window, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	add_child(mission_window)
	mission_window.setup(simulation)
	diplomacy_window = DiplomacyWindow.new()
	_pin(diplomacy_window, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	add_child(diplomacy_window)
	diplomacy_window.setup(simulation)
	specialist_window = SpecialistWindow.new()
	_pin(specialist_window, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	add_child(specialist_window)
	specialist_window.setup(simulation)
	selection_panel.specialists_requested.connect(specialist_window.open)
	_build_labels()
	tool.changed.connect(_refresh_tool)
	tool.refused.connect(func(reason: StringName) -> void: show_message(tr(reason)))
	EventBus.time_speed_changed.connect(func(_speed_index: int, _paused: bool) -> void: _refresh_speed())
	EventBus.settings_changed.connect(func() -> void:
		_select_category(_category)
		_refresh())
	_select_category(category_of(&"trading_post") if _needs_trading_post() else 0)
	_refresh_speed()
	_refresh_tool()
	_refresh()


func show_message(text: String) -> void:
	_message.text = text
	_message_panel.visible = not text.is_empty()
	_message_left = MESSAGE_SECONDS


func toggle_statistics() -> void:
	statistics_window.toggle()


func toggle_routes() -> void:
	route_window.toggle()


func toggle_missions() -> void:
	mission_window.toggle()


func toggle_rivals() -> void:
	diplomacy_window.toggle()


func toggle_specialists() -> void:
	specialist_window.toggle()


## Fecha a janela aberta de cima (Esc); devolve se havia alguma.
func close_top_window() -> bool:
	for window: Control in [specialist_window, diplomacy_window, mission_window, trade_window, route_window, statistics_window]:
		if window.visible:
			window.visible = false
			return true
	return false


func set_overlay(layer: MapOverlays.Layer) -> void:
	overlay_layer = layer
	for key: MapOverlays.Layer in _overlay_buttons:
		_overlay_buttons[key].set_pressed_no_signal(key == layer)
	overlay_changed.emit(layer)
	_refresh_tool()


func _process(delta: float) -> void:
	var clock := GameClock.clock
	var minutes := floori(clock.time_of_day() * 24.0 * 60.0)
	_clock_label.text = tr("HUD_CLOCK") % [clock.day_number(), minutes / 60, minutes % 60]
	if _message_left > 0.0:
		_message_left -= delta
		_message_panel.visible = _message_left > 0.0
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		_refresh()
	_update_cursor_label()
	_pulse_hint(delta)


## Tutorial pelas metas (Fase 10): a aba e o cartão do prédio que a meta da vez pede piscam.
func hinted_building() -> StringName:
	if not Settings.advisor:
		return &""
	var goal := GoalSystem.current(_simulation.world, _simulation.data)
	return goal.hint if goal != null else &""


## Índice da aba do menu que tem o prédio dado (o paralelepípedo fica na infraestrutura), ou -1.
func category_of(building: StringName) -> int:
	var groups := _categories()
	if building == &"paved_road":
		return groups.size() - 1
	for index: int in groups.size():
		for def: BuildingDef in groups[index]:
			if def.id == building:
				return index
	return -1


func _pulse_hint(delta: float) -> void:
	_hint_phase += delta
	var target := hinted_building()
	# acima de 1 clareia o papel em dourado (multiplicar pelo dourado só escurecia)
	var glow := Color.WHITE.lerp(Color(1.3, 1.05, 0.45), 0.5 + 0.5 * sin(_hint_phase * 5.0))
	var tab := category_of(target) if target != &"" else -1
	for index: int in _category_buttons.size():
		_category_buttons[index].self_modulate = glow if index == tab and index != _category else Color.WHITE
	for def_id: StringName in _item_buttons:
		_item_buttons[def_id].self_modulate = glow if def_id == target else Color.WHITE
	if _paved_button != null:
		_paved_button.self_modulate = glow if target == &"paved_road" else Color.WHITE


func _refresh() -> void:
	var world := _simulation.world
	var balance := world.income_per_min - world.upkeep_per_min
	_money_balance = balance
	_count_money(world.money)
	if world.money < _simulation.config.min_balance_for(world.difficulty):
		UiPalette.paint(_money_label, UiPalette.Status.BAD)
	else:
		UiPalette.unpaint(_money_label)
	_money_label.tooltip_text = tr("HUD_MONEY_TIP") % [Fmt.integer(world.income_per_min), Fmt.integer(world.upkeep_per_min),
			Fmt.integer(_simulation.config.min_balance_for(world.difficulty))]
	# Fase 28: o que as fábricas ociosas custam, para o jogador pausar ou demolir
	var idle := _simulation.idle_upkeep()
	if idle.x > 0.0:
		_money_label.tooltip_text += "\n" + tr("HUD_MONEY_IDLE") % [Fmt.integer(idle.x), Fmt.integer(idle.y),
				Fmt.percent(_simulation.config.paused_upkeep_factor)]
	for tier: TierDef in _simulation.data.tiers:
		if _population_labels.has(tier.id):
			_count_population(tier.id, float(world.population(tier.id)))
	if _tool.mode == BuildTool.Mode.NONE:
		_refresh_tool()
	for def_id: StringName in _item_buttons:
		var def := _simulation.data.building(def_id)
		_item_buttons[def_id].disabled = not _simulation.free_build and PlacementRules.check_unlock(world, def) != PlacementRules.OK
	_refresh_events()
	if _paved_button != null:
		var config := _simulation.config
		_paved_button.disabled = not _simulation.free_build \
				and world.population(config.paved_road_unlock_tier) < config.paved_road_unlock_residents


## Leva o dinheiro mostrado até "target" (Fase 30), com o pulso dourado num ganho grande.
func _count_money(target: float) -> void:
	var from := _money_shown
	if _money_tween != null:
		_money_tween.kill()
		_money_tween = null
	if is_nan(from) or SceneFader.is_instant() or absf(target - from) < 0.5:
		_show_money(target)
		return
	_money_tween = create_tween()
	_money_tween.tween_method(_show_money, from, target, COUNT_S)
	var gain := target - from
	if gain >= BIG_GAIN or (from > 0.0 and gain >= from * BIG_GAIN_FRACTION):
		_pulse(_money_label)


func _show_money(value: float) -> void:
	_money_shown = value
	_money_label.text = tr("HUD_MONEY") % [Fmt.integer(value), Fmt.signed(_money_balance)]


func _count_population(tier_id: StringName, target: float) -> void:
	var from: float = _population_shown.get(tier_id, NAN)
	var running: Tween = _population_tweens.get(tier_id)
	if running != null:
		running.kill()
		_population_tweens.erase(tier_id)
	if is_nan(from) or SceneFader.is_instant() or absf(target - from) < 0.5:
		_show_population(tier_id, target)
		return
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void: _show_population(tier_id, value), from, target, COUNT_S)
	_population_tweens[tier_id] = tween


func _show_population(tier_id: StringName, value: float) -> void:
	_population_shown[tier_id] = value
	_population_labels[tier_id].text = Fmt.integer(roundf(value))


## Pulso de ganho (Fase 30): cresce e doura e volta. O dourado vai no self_modulate, por cima da cor de estado
## (UiPalette.paint), que fica intacta quando ele volta ao branco.
func _pulse(label: Label) -> void:
	label.pivot_offset = label.size * 0.5
	var pulse := create_tween()
	pulse.tween_property(label, ^"scale", Vector2.ONE * PULSE_SCALE, 0.12)
	pulse.parallel().tween_property(label, ^"self_modulate", GAIN_COLOR, 0.12)
	pulse.tween_property(label, ^"scale", Vector2.ONE, 0.25)
	pulse.parallel().tween_property(label, ^"self_modulate", Color.WHITE, 0.25)


func _build_top_bar() -> void:
	var panel := PanelContainer.new()
	panel.name = "TopBar"
	panel.theme_type_variation = &"TopBar"
	panel.anchor_right = 1.0
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	panel.add_child(row)
	row.add_child(UiKit.icon_rect(Icons.get_icon("hud_clock"), 28))
	_clock_label.custom_minimum_size.x = 150
	_clock_label.tooltip_text = "HUD_CLOCK_TIP"
	_clock_label.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(_clock_label)
	var speeds := GameConfig.get_default().game_speeds
	for index: int in speeds.size() + 1:
		var speed_index := TickClock.PAUSED if index == 0 else index - 1
		var button: Button
		if index == 0:
			button = UiKit.icon_button("action_pause", "HUD_SPEED_PAUSE_TIP")
		else:
			button = UiKit.button(tr("SPEED_MULTIPLIER") % _speed_text(speeds[index - 1]), "action_play" if index == 1 else "action_fast")
			button.tooltip_text = tr("HUD_SPEED_TIP") % _speed_text(speeds[index - 1])
		button.toggle_mode = true
		button.pressed.connect(func() -> void: GameClock.set_speed(speed_index))
		row.add_child(button)
		_speed_buttons.append(button)
	row.add_child(VSeparator.new())
	row.add_child(UiKit.icon_rect(Icons.get_icon("hud_money"), 28))
	_money_label.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(_money_label)
	row.add_child(VSeparator.new())
	_population.add_theme_constant_override(&"separation", 6)
	_population.tooltip_text = "HUD_POPULATION_TIP"
	_population.mouse_filter = Control.MOUSE_FILTER_STOP
	for tier: TierDef in _simulation.data.tiers:
		var icon := UiKit.icon_rect(Icons.tier(tier.id), 28)
		icon.tooltip_text = tier.name_key
		_population.add_child(icon)
		var count := Label.new()
		count.tooltip_text = tier.name_key
		count.mouse_filter = Control.MOUSE_FILTER_STOP
		count.custom_minimum_size.x = 56
		_population.add_child(count)
		_population_labels[tier.id] = count
	row.add_child(_population)
	_event_chips.name = "Events"
	_event_chips.add_theme_constant_override(&"separation", 4)
	row.add_child(_event_chips)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	# só ícone (a dica tem o nome e o atalho): com rivais e especialistas a barra passava de 1920 px
	var stats := UiKit.icon_button("action_statistics", "HUD_STATS_TIP", toggle_statistics)
	stats.name = "Statistics"
	row.add_child(stats)
	var routes := UiKit.icon_button("action_routes", "HUD_ROUTES_TIP", toggle_routes)
	routes.name = "Routes"
	row.add_child(routes)
	_missions_button = UiKit.button("", "action_missions", toggle_missions, "HUD_MISSIONS_TIP")
	_missions_button.name = "MissionsButton"
	row.add_child(_missions_button)
	_rivals_button = UiKit.icon_button("hud_rival", "HUD_RIVALS_TIP", toggle_rivals)
	_rivals_button.name = "RivalsButton"
	row.add_child(_rivals_button)
	_specialists_button = UiKit.button("", "action_specialists", toggle_specialists, "HUD_SPECIALISTS_TIP")
	_specialists_button.name = "SpecialistsButton"
	row.add_child(_specialists_button)
	row.add_child(UiKit.icon_button("action_save", "HUD_SAVE_TIP", save_requested.emit))
	row.add_child(UiKit.icon_button("action_load", "HUD_LOAD_TIP", load_requested.emit))
	var menu := UiKit.icon_button("action_menu", "HUD_MENU_TIP", menu_requested.emit)
	menu.name = "Menu"
	row.add_child(menu)


## Selos dos eventos (ícone com o título, a descrição e o tempo na dica) e a contagem das encomendas.
## Os selos só se refazem quando a lista de eventos muda.
func _refresh_events() -> void:
	var state := _simulation.world.events_state
	var open := 0
	for item: Mission in state.missions:
		if item.state == Mission.State.OFFERED:
			open += 1
	_missions_button.text = tr("HUD_MISSIONS") % state.missions.size()
	var specialists := _simulation.world.specialists_state
	_specialists_button.text = tr("HUD_SPECIALISTS") % specialists.specialists.size()
	# contratado sem posto pede atenção
	if specialists.unassigned_count() > 0:
		UiPalette.paint(_specialists_button, UiPalette.Status.PARTIAL)
	else:
		UiPalette.unpaint(_specialists_button)
	var rivals := _simulation.world.rivals_state
	_rivals_button.visible = rivals.enabled
	if rivals.at_war():
		UiPalette.paint(_rivals_button, UiPalette.Status.BAD)
	else:
		UiPalette.unpaint(_rivals_button)
	if open > 0:
		UiPalette.paint(_missions_button, UiPalette.Status.PARTIAL)
	else:
		UiPalette.unpaint(_missions_button)
	var signature := ""
	for event: WorldEvent in state.events:
		signature += "%s/%d/%d;" % [event.def_id, event.island_id, event.started_tick]
	if signature != _chips_signature:
		_chips_signature = signature
		UiKit.clear(_event_chips)
		for event: WorldEvent in state.events:
			var chip := UiKit.icon_rect(Icons.get_icon(MissionWindow.event_icon(event.def_id)), 28)
			chip.name = "Event_" + String(event.def_id)
			chip.mouse_filter = Control.MOUSE_FILTER_STOP
			_event_chips.add_child(chip)
	var index := 0
	for event: WorldEvent in state.events:
		var chip := _event_chips.get_child(index) as Control
		chip.tooltip_text = "%s\n%s\n%s" % [MissionWindow.event_title(event, _simulation.data),
				MissionWindow.event_description(event, _simulation.data),
				tr("EVENT_TIME_LEFT") % Fmt.countdown(event.ticks_left(_simulation.world.tick) * _simulation.config.tick_interval())]
		index += 1


## Duas linhas: as categorias (com as camadas de mapa à direita) e, abaixo, os prédios da
## categoria escolhida (quebrando a linha quando não cabem).
func _build_build_menu() -> void:
	_bottom.name = "Bottom"
	_bottom.alignment = BoxContainer.ALIGNMENT_END
	_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pin(_bottom, Vector2(0.5, 1.0), Vector2(0, -8), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN)
	add_child(_bottom)
	_hint_panel.name = "Hint"
	_hint_panel.theme_type_variation = &"NoticePanel"
	_hint_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_panel.add_child(_hint)
	_bottom.add_child(_hint_panel)
	var panel := PanelContainer.new()
	panel.name = "BuildMenu"
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_bottom.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 6)
	column.add_child(top)
	for index: int in _categories().size():
		var button := UiKit.button(_category_label(index), _category_icon(index), Callable(), _category_tip(index))
		button.toggle_mode = true
		button.pressed.connect(_select_category.bind(index))
		top.add_child(button)
		_category_buttons.append(button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(VSeparator.new())
	for layer: MapOverlays.Layer in MapOverlays.ICONS:
		var button := UiKit.icon_button(MapOverlays.ICONS[layer], MapOverlays.KEYS[layer] + "_TIP")
		button.name = "Overlay_%d" % layer
		button.toggle_mode = true
		button.pressed.connect(func() -> void: set_overlay(MapOverlays.Layer.NONE if overlay_layer == layer else layer))
		top.add_child(button)
		_overlay_buttons[layer] = button
	_items.custom_minimum_size.x = 1000
	_items.alignment = FlowContainer.ALIGNMENT_CENTER
	_items.add_theme_constant_override(&"h_separation", 6)
	_items.add_theme_constant_override(&"v_separation", 6)
	column.add_child(_items)


## Categorias do menu: residências, produção por classe, serviços, decoração (Fase 16), porto (entreposto, píer e
## estaleiro, Fase 17) e infraestrutura (a última: as estradas entram nela).
func _categories() -> Array[Array]:
	var data := _simulation.data
	var groups: Array[Array] = [data.buildings.filter(func(def: BuildingDef) -> bool: return def.kind == BuildingDef.Kind.RESIDENCE)]
	for tier: TierDef in data.tiers:
		groups.append(data.buildings.filter(func(def: BuildingDef) -> bool:
			return (def.is_production() and def.workforce_tier == tier.id and not def.is_shipyard()) \
					or (def.kind == BuildingDef.Kind.MODULE and def.unlock_tier == tier.id)))
	groups.append(data.buildings.filter(func(def: BuildingDef) -> bool: return def.kind == BuildingDef.Kind.SERVICE))
	groups.append(data.buildings.filter(func(def: BuildingDef) -> bool: return def.is_decoration()))
	groups.append(data.buildings.filter(func(def: BuildingDef) -> bool: return def.is_berth() or def.is_shipyard()))
	groups.append(data.buildings.filter(func(def: BuildingDef) -> bool: return def.is_warehouse() and not def.is_trading_post))
	return groups


func _category_label(index: int) -> String:
	var tiers := _simulation.data.tiers
	if index == 0:
		return tr("HUD_CATEGORY_RESIDENCES")
	# a produção de cada classe vai só com o medalhão dela, como a população na barra de cima: com as abas de
	# decoração (Fase 16) e porto (Fase 17) os nomes passavam de 1920 px; "Produção: <classe>" fica na dica
	if index <= tiers.size():
		return ""
	if index == tiers.size() + 1:
		return tr("HUD_CATEGORY_SERVICES")
	if index == tiers.size() + 2:
		return tr("HUD_CATEGORY_DECORATION")
	return tr("HUD_CATEGORY_HARBOR") if index == tiers.size() + 3 else tr("HUD_CATEGORY_INFRASTRUCTURE")


func _category_tip(index: int) -> String:
	var tiers := _simulation.data.tiers
	if index >= 1 and index <= tiers.size():
		return tr("HUD_CATEGORY_PRODUCTION") % tr(tiers[index - 1].name_key)
	return _category_label(index)


func _category_icon(index: int) -> String:
	var tiers := _simulation.data.tiers
	if index == 0:
		return "building_house"
	if index <= tiers.size():
		return "tier_" + tiers[index - 1].id
	if index == tiers.size() + 1:
		return "building_market"
	if index == tiers.size() + 2:
		return "building_flower_bed"
	return "building_pier" if index == tiers.size() + 3 else "building_warehouse"


func _select_category(index: int) -> void:
	_category = index
	for i: int in _category_buttons.size():
		_category_buttons[i].set_pressed_no_signal(i == index)
		_category_buttons[i].text = _category_label(i)
		_category_buttons[i].tooltip_text = _category_tip(i)
	UiKit.clear(_items)
	_item_buttons.clear()
	_paved_button = null
	var defs: Array = _categories()[index]
	for def: BuildingDef in defs:
		var button := _card(def.name_key, Icons.building(def.id))
		button.tooltip_text = _tooltip(def)
		button.pressed.connect(func() -> void: _tool.start_building(def))
		_items.add_child(button)
		_item_buttons[def.id] = button
	if index == _categories().size() - 1:
		var road := _card("HUD_ROAD", Icons.action("road"))
		road.tooltip_text = tr("HUD_ROAD_TIP") % Fmt.integer(_simulation.config.road_cost_per_cell)
		road.pressed.connect(_tool.start_road)
		_items.add_child(road)
		var config := _simulation.config
		var paved := _card("HUD_PAVED_ROAD", Icons.action("paved_road"))
		paved.tooltip_text = tr("HUD_PAVED_ROAD_TIP") % [Fmt.integer(config.paved_road_cost_per_cell),
				Fmt.decimal(config.paved_road_bricks_per_cell, 1), Fmt.percent(config.paved_road_speed_bonus),
				Fmt.integer(config.paved_road_unlock_residents), tr(_simulation.data.tier(config.paved_road_unlock_tier).name_key)]
		paved.pressed.connect(_tool.start_paved_road)
		_items.add_child(paved)
		_paved_button = paved
		var demolish := _card("HUD_DEMOLISH", Icons.action("demolish"))
		demolish.tooltip_text = tr("HUD_DEMOLISH_TIP") % Fmt.percent(_simulation.config.demolish_refund)
		demolish.pressed.connect(_tool.start_demolish)
		_items.add_child(demolish)
	_refresh()


## Cartão do menu de construção: o ícone em cima e o nome embaixo.
func _card(text_key: String, icon: Texture2D) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"CardButton"
	button.text = text_key
	button.icon = icon
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(CARD_WIDTH, 92)
	button.focus_mode = Control.FOCUS_NONE
	return button


func _tooltip(def: BuildingDef) -> String:
	var data := _simulation.data
	var lines: PackedStringArray = [tr(def.name_key)]
	var cost: PackedStringArray = [tr("TIP_COINS") % Fmt.integer(def.cost_money)]
	for material: StringName in def.cost_materials:
		cost.append("%d %s" % [def.cost_materials[material], tr(data.good(material).name_key)])
	lines.append(tr("TIP_COST") % ", ".join(cost))
	if def.upkeep_per_min > 0:
		lines.append(tr("TIP_UPKEEP") % Fmt.integer(def.upkeep_per_min))
	if def.is_production():
		if def.is_power_plant():
			lines.append(tr("TIP_POWER") % [def.power_radius_cells, Fmt.percent(_simulation.config.electricity_bonus)])
		elif def.is_shipyard():
			lines.append(tr("TIP_SHIPYARD") % [Fmt.percent(_simulation.config.shipyard_cost_factor), Fmt.decimal(_simulation.config.shipyard_repair_factor)])
		else:
			lines.append(tr("TIP_PRODUCES") % [Fmt.decimal(def.output_per_min()), tr(data.good(def.output).name_key)])
		if not def.inputs.is_empty():
			lines.append(tr("TIP_NEEDS") % ", ".join(def.inputs.map(func(good: StringName) -> String: return tr(data.good(good).name_key))))
		lines.append(tr("TIP_WORKERS") % [def.workers, tr(data.tier(def.workforce_tier).name_key)])
		if def.modules_required > 0:
			lines.append(tr("TIP_MODULES") % [def.modules_required, tr(data.building(def.module_id).name_key)])
		if def.terrain == BuildingDef.Terrain.COAST:
			lines.append(tr("TIP_COAST"))
		lines.append_array(RatioCalculator.lines(def, data))
	if def.is_decoration():
		lines.append(tr("TIP_BEAUTY") % [def.beauty_radius_cells,
				Fmt.integer(roundi(def.beauty * _simulation.config.happiness_per_beauty))])
	if def.kind == BuildingDef.Kind.SERVICE:
		var config := _simulation.config
		match def.protects:
			BuildingDef.Hazard.FIRE:
				lines.append(tr("TIP_PROTECTS_FIRE") % [ServiceReach.radius_of(def, config), Fmt.integer(config.fire_extinguish_s)])
			BuildingDef.Hazard.DISEASE:
				lines.append(tr("TIP_PROTECTS_DISEASE") % [ServiceReach.radius_of(def, config), Fmt.integer(config.disease_cure_s)])
			_:
				lines.append(tr("TIP_SERVICE_RADIUS") % ServiceReach.radius_of(def, config))
	if def.kind == BuildingDef.Kind.RESIDENCE:
		lines.append(tr("TIP_HOUSE"))
	if def.unlock_tier != &"":
		lines.append(tr("TIP_UNLOCK") % [Fmt.integer(def.unlock_residents), tr(data.tier(def.unlock_tier).name_key)])
	if def.is_warehouse():
		lines.append(tr("TIP_RAMPS") % def.level(0).ramps)
		if def.is_trading_post:
			lines.append(tr("TIP_STORAGE") % def.level(0).storage_capacity_t)
			lines.append(tr("TIP_COAST"))
			lines.append(tr("TIP_FIRST_FREE"))
			lines.append(tr("TIP_COLONY"))
	if def.is_pier():
		lines.append(tr("TIP_COAST"))
		lines.append(tr("TIP_PIER"))
	return "\n".join(lines)


func _build_labels() -> void:
	_message_panel.name = "Message"
	_message_panel.theme_type_variation = &"ToastPanel"
	_pin(_message_panel, Vector2(0.5, 0.0), Vector2(0, 64), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override(&"font_size", 21)
	_message.add_theme_color_override(&"font_color", UiPalette.PAPER)
	_message_panel.add_child(_message)
	_message_panel.visible = false
	_message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_message_panel)
	_cursor_panel.theme_type_variation = &"NoticePanel"
	_cursor_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor_panel.add_child(_cursor_label)
	_cursor_panel.visible = false
	add_child(_cursor_panel)


## Prende o controle num ponto relativo da tela (anchor) com deslocamento em pixels; o
## tamanho sai do conteúdo e cresce na direção pedida. Vale para qualquer resolução.
static func _pin(control: Control, anchor: Vector2, offset: Vector2, grow_h: Control.GrowDirection, grow_v: Control.GrowDirection) -> void:
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = offset.x
	control.offset_right = offset.x
	control.offset_top = offset.y
	control.offset_bottom = offset.y
	control.grow_horizontal = grow_h
	control.grow_vertical = grow_v


static func _speed_text(speed: float) -> String:
	return String.num(speed, 0 if is_equal_approx(speed, roundf(speed)) else 1)


func _refresh_speed() -> void:
	var clock := GameClock.clock
	for index: int in _speed_buttons.size():
		var speed_index := TickClock.PAUSED if index == 0 else index - 1
		_speed_buttons[index].set_pressed_no_signal(clock.speed_index == speed_index)


func _needs_trading_post() -> bool:
	return not _simulation.free_build and not _simulation.config.instant_logistics \
			and not _simulation.world.has_trading_post(Simulation.MAIN_ISLAND, _simulation.data)


func _refresh_tool() -> void:
	match _tool.mode:
		BuildTool.Mode.BUILDING:
			_hint.text = tr("HUD_HINT_BUILDING")
		BuildTool.Mode.ROAD:
			_hint.text = tr("HUD_HINT_PAVED_ROAD") if _tool.road_paved else tr("HUD_HINT_ROAD")
			# o traçado da vez e a tecla que troca (Fase 17)
			var keys: PackedStringArray = []
			for keycode: int in Settings.keys_of(&"build_rotate"):
				keys.append(InputActions.key_name(keycode))
			_hint.text += " · " + tr("HUD_HINT_ROAD_DIAGONAL" if _tool.road_diagonal else "HUD_HINT_ROAD_STRAIGHT") \
					% " / ".join(keys)
		BuildTool.Mode.MOVE:
			_hint.text = tr("HUD_HINT_MOVE")
		BuildTool.Mode.DEMOLISH:
			_hint.text = tr("HUD_HINT_DEMOLISH")
		BuildTool.Mode.SAIL_TO:
			_hint.text = tr("HUD_HINT_SAIL_TO")
		_:
			_hint.text = tr("HINT_BUILD_TRADING_POST") if _needs_trading_post() else _overlay_hint()
	_hint_panel.visible = not _hint.text.is_empty()


## Legenda da camada de mapa ligada (a fertilidade diz as culturas da ilha).
func _overlay_hint() -> String:
	if overlay_layer == MapOverlays.Layer.NONE:
		return ""
	var text := tr(MapOverlays.KEYS[overlay_layer] + "_LEGEND")
	if overlay_layer == MapOverlays.Layer.FERTILITY:
		var crops := MapOverlays.crops_of(_simulation, _tool.island_id)
		var names := ", ".join(crops.map(func(crop: StringName) -> String: return tr(_simulation.data.good(crop).name_key)))
		text = text % (names if not names.is_empty() else tr("OVERLAY_FERTILITY_NONE"))
	return text


func _update_cursor_label() -> void:
	var text := ""
	var reason := _tool.preview_reason()
	if reason != PlacementRules.OK:
		text = tr(reason)
	elif _tool.mode == BuildTool.Mode.ROAD and _tool.dragging:
		text = tr("PREVIEW_ROAD_COST") % [_tool.road_cells().size(), Fmt.integer(_tool.road_cost())]
		var bricks: int = _tool.road_materials().get(&"bricks", 0)
		if bricks > 0:
			text += "\n" + tr("PREVIEW_ROAD_BRICKS") % Fmt.integer(bricks)
	_cursor_label.text = text
	_cursor_panel.visible = not text.is_empty()
	_cursor_panel.reset_size()
	_cursor_panel.position = get_local_mouse_position() + Vector2(18, 18)
