class_name MissionWindow
extends PanelContainer
## Encomendas do comerciante e eventos em andamento (Fase 11). Cada oferta mostra o pedido, o
## prêmio e o tempo para responder, com aceitar e recusar; a aceita mostra o entregue e o prazo. A
## entrega é vender o bem no posto do comerciante (rota ou painel do navio). Abaixo, os eventos com
## a descrição, o lugar e o tempo que falta.
## Fase 63: no alto, o jornal — a manchete da edição com o efeito e o tempo até a próxima, e a propaganda que troca a
## manchete (uma vez por edição, pelo preço da config).

var _simulation: Simulation
var _newspaper := VBoxContainer.new()
var _missions := VBoxContainer.new()
var _events := VBoxContainer.new()
## Rótulos de tempo que andam sozinhos, o tick em que o tempo acaba e a chave do texto.
var _timer_labels: Array[Label] = []
var _timer_ends: PackedInt64Array = []
var _timer_keys: PackedStringArray = []
var _refresh_left: float = 0.0


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	name = "Missions"
	visible = false
	custom_minimum_size.x = 560
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	column.add_child(UiKit.header("MISSIONS_TITLE", func() -> void: visible = false))
	_newspaper.name = "Newspaper"
	_newspaper.add_theme_constant_override(&"separation", 6)
	column.add_child(_newspaper)
	column.add_child(HSeparator.new())
	var intro := HBoxContainer.new()
	intro.add_theme_constant_override(&"separation", 12)
	column.add_child(intro)
	var portrait := UiKit.icon_rect(Icons.portrait("trader"), 80)
	portrait.custom_minimum_size = Vector2(64, 80)
	portrait.tooltip_text = "PORTRAIT_TRADER"
	intro.add_child(portrait)
	var hint := UiKit.label("MISSIONS_HINT", &"DimLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# com quebra de linha e sem largura, o rótulo quebraria a cada letra e esticaria a janela
	hint.custom_minimum_size.x = 440
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.add_child(hint)
	_missions.add_theme_constant_override(&"separation", 8)
	column.add_child(_missions)
	column.add_child(HSeparator.new())
	column.add_child(UiKit.label("MISSIONS_EVENTS", &"HeaderLabel"))
	_events.add_theme_constant_override(&"separation", 6)
	column.add_child(_events)
	for event_signal: Signal in [EventBus.missions_changed, EventBus.world_replaced]:
		event_signal.connect(_rebuild_if_open)
	EventBus.mission_offered.connect(func(_id: int) -> void: _rebuild_if_open())
	EventBus.mission_expired.connect(func(_def: StringName, _accepted: bool) -> void: _rebuild_if_open())
	EventBus.mission_completed.connect(func(_def: StringName, _bonus: int) -> void: _rebuild_if_open())
	EventBus.world_event_started.connect(func(_def: StringName, _island: int) -> void: _rebuild_if_open())
	EventBus.world_event_ended.connect(func(_def: StringName, _island: int) -> void: _rebuild_if_open())
	EventBus.newspaper_published.connect(func(_headline: StringName) -> void: _rebuild_if_open())
	EventBus.newspaper_changed.connect(_rebuild_if_open)
	EventBus.ships_changed.connect(_rebuild_if_open)


func toggle() -> void:
	visible = not visible
	if visible:
		rebuild()


func open() -> void:
	visible = true
	rebuild()


func _rebuild_if_open() -> void:
	if visible:
		rebuild()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = 0.5
	var tick := _simulation.world.tick
	for index: int in _timer_labels.size():
		var ticks_left := maxi(_timer_ends[index] - tick, 0)
		_timer_labels[index].text = tr(_timer_keys[index]) % Fmt.countdown(ticks_left * _simulation.config.tick_interval())


func rebuild() -> void:
	_timer_labels.clear()
	_timer_ends.clear()
	_timer_keys.clear()
	UiKit.clear(_newspaper)
	UiKit.clear(_missions)
	UiKit.clear(_events)
	var state := _simulation.world.events_state
	_fill_newspaper(state)
	if not state.enabled:
		_missions.add_child(UiKit.label("MISSIONS_DISABLED", &"DimLabel"))
	elif state.missions.is_empty():
		_missions.add_child(UiKit.label("MISSIONS_NONE", &"DimLabel"))
	for item: Mission in state.missions:
		_missions.add_child(_mission_row(item))
	if state.events.is_empty():
		_events.add_child(UiKit.label("MISSIONS_NO_EVENTS", &"DimLabel"))
	for event: WorldEvent in state.events:
		_events.add_child(_event_row(event))
	# Fase 69: as expedições em andamento (o navio fica fora do mapa até a volta)
	for trip: ExpeditionsState.Trip in _simulation.world.expeditions_state.trips:
		var row := HBoxContainer.new()
		row.name = "Trip_%d" % trip.number
		row.add_theme_constant_override(&"separation", 10)
		row.add_child(UiKit.icon_rect(Icons.get_icon("notice_ship_arrived"), 32))
		var text := VBoxContainer.new()
		row.add_child(text)
		var ship_def := _simulation.data.ship(trip.ship.def_id)
		text.add_child(UiKit.label(tr("EXPEDITION_UNDER_WAY") % [tr(trip.def.title_key()),
				tr("SHIP_TITLE") % [tr(ship_def.name_key), trip.ship.id]], &"HeaderLabel"))
		var timer := Label.new()
		text.add_child(timer)
		_track(timer, trip.ends_tick, "EXPEDITION_BACK_IN")
		_events.add_child(row)
	_refresh_left = 0.0
	reset_size()
	_center.call_deferred()


## Volta ao meio da tela depois de mudar de tamanho (a lista cresce e encolhe).
func _center() -> void:
	reset_size()
	position = ((get_parent_area_size() - size) / 2.0).round()


func _mission_row(item: Mission) -> Control:
	var data := _simulation.data
	var good := data.good(item.def.good)
	var row := HBoxContainer.new()
	row.name = "Mission_%d" % item.id
	row.add_theme_constant_override(&"separation", 10)
	row.add_child(UiKit.icon_rect(Icons.good(item.def.good), 40))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UiKit.label(tr("MISSION_REQUEST") % [Fmt.integer(item.def.tons), tr(good.name_key)], &"HeaderLabel"))
	var details := UiKit.label(tr("MISSION_REWARD") % [Fmt.integer(item.def.bonus(data)), Fmt.countdown(item.def.duration_s)], &"DimLabel")
	text.add_child(details)
	var timer := Label.new()
	text.add_child(timer)
	if item.state == Mission.State.OFFERED:
		_track(timer, item.expires_tick, "MISSION_ANSWER_IN")
		var accept := UiKit.button("MISSION_ACCEPT", "action_confirm", func() -> void: _answer(item.id, true), "MISSION_ACCEPT_TIP")
		accept.name = "Accept"
		row.add_child(accept)
		var decline := UiKit.icon_button("action_close", "MISSION_DECLINE_TIP", func() -> void: _answer(item.id, false))
		decline.name = "Decline"
		row.add_child(decline)
	else:
		details.text = tr("MISSION_DELIVERED") % [Fmt.integer(item.delivered), Fmt.integer(item.def.tons),
				Fmt.integer(item.def.bonus(data))]
		_track(timer, item.expires_tick, "MISSION_DEADLINE")
		var progress := ProgressBar.new()
		progress.custom_minimum_size = Vector2(120, 18)
		progress.max_value = item.def.tons
		progress.value = item.delivered
		progress.show_percentage = false
		progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		progress.tooltip_text = "MISSION_PROGRESS_TIP"
		row.add_child(progress)
	return row


func _event_row(event: WorldEvent) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	row.add_child(UiKit.icon_rect(Icons.get_icon(event_icon(event.def_id)), 32))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UiKit.label(event_title(event, _simulation.data), &"HeaderLabel"))
	var description := UiKit.label(event_description(event, _simulation.data), &"DimLabel")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 440
	text.add_child(description)
	var timer := Label.new()
	text.add_child(timer)
	_track(timer, event.ends_tick, "EVENT_TIME_LEFT")
	return row


## O jornal: título, a manchete com o texto e o efeito, o tempo até a próxima edição e os botões de propaganda.
func _fill_newspaper(state: EventsState) -> void:
	_newspaper.add_child(UiKit.label("NEWSPAPER_TITLE", &"HeaderLabel"))
	if not state.enabled:
		_newspaper.add_child(UiKit.label("NEWSPAPER_DISABLED", &"DimLabel"))
		return
	if state.edition_count == 0 or state.headline == null:
		_newspaper.add_child(UiKit.label("NEWSPAPER_NONE", &"DimLabel"))
		if state.next_edition_tick > 0:
			_next_edition(state)
		return
	var headline := UiKit.label(state.headline.title_key(), &"HeaderLabel")
	headline.name = "Headline"
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headline.custom_minimum_size.x = 520
	_newspaper.add_child(headline)
	var story := UiKit.label(state.headline.description_key(), &"DimLabel")
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.custom_minimum_size.x = 520
	_newspaper.add_child(story)
	var effect := UiKit.label(headline_effect(state.headline))
	effect.name = "Effect"
	_newspaper.add_child(effect)
	_next_edition(state)
	var choices := NewspaperSystem.propaganda_choices(_simulation.world, _simulation.data)
	if choices.is_empty():
		return
	var cost := _simulation.config.newspaper_propaganda_cost
	var row := HFlowContainer.new()
	row.name = "Propaganda"
	row.add_theme_constant_override(&"h_separation", 8)
	_newspaper.add_child(row)
	for def: HeadlineDef in choices:
		var text := tr("NEWSPAPER_PROPAGANDA") % [tr(def.title_key()), Fmt.integer(cost)]
		var button := UiKit.button(text, "notice_mission", func() -> void: _buy(def.id), "NEWSPAPER_PROPAGANDA_TIP")
		button.name = "Buy_" + String(def.id)
		if state.propaganda_used:
			button.disabled = true
			button.tooltip_text = "NEWSPAPER_PROPAGANDA_USED"
		elif _simulation.world.money < cost:
			button.disabled = true
			button.tooltip_text = "REASON_NO_MONEY"
		row.add_child(button)


## O tempo até a próxima edição, que anda sozinho.
func _next_edition(state: EventsState) -> void:
	var next := Label.new()
	next.name = "NextEdition"
	_newspaper.add_child(next)
	_track(next, state.next_edition_tick, "NEWSPAPER_NEXT")


func _buy(headline_id: StringName) -> void:
	_simulation.execute(BuyPropagandaCommand.new(headline_id))
	rebuild()


## O efeito da manchete: "+6 de felicidade em todas as ilhas" (ou sem efeito).
static func headline_effect(def: HeadlineDef) -> String:
	if is_zero_approx(def.happiness):
		return TranslationServer.translate("NEWSPAPER_NO_EFFECT")
	var points := Fmt.integer(absf(def.happiness))
	return TranslationServer.translate("NEWSPAPER_EFFECT_UP" if def.happiness > 0.0 else "NEWSPAPER_EFFECT_DOWN") % points


func _track(label: Label, end_tick: int, key: String) -> void:
	_timer_labels.append(label)
	_timer_ends.append(end_tick)
	_timer_keys.append(key)


func _answer(mission_id: int, accept: bool) -> void:
	_simulation.execute(AnswerMissionCommand.new(mission_id, accept))
	rebuild()


static func event_icon(def_id: StringName) -> String:
	return "event_" + String(def_id)


## Título com o lugar: "Boa colheita — Ilha 2"; o do arquipélago todo fica sem lugar.
static func event_title(event: WorldEvent, _data: GameData) -> String:
	var title := TranslationServer.translate(event.def.title_key())
	return TranslationServer.translate("EVENT_AT") % [title, Fmt.place(event.island_id)] if event.island_id >= 0 else title


## A descrição com o número do efeito (e o bem, na feira).
static func event_description(event: WorldEvent, data: GameData) -> String:
	var text := TranslationServer.translate(event.def.description_key())
	match event.def.effect:
		EventDef.Effect.TRADER_PRICE:
			return text % [TranslationServer.translate(data.good(event.good).name_key), Fmt.percent(event.def.amount - 1.0)]
		EventDef.Effect.HAPPINESS:
			return text % Fmt.integer(event.def.amount)
	return text % Fmt.percent(absf(event.def.amount - 1.0))
