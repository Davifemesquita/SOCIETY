class_name MissionWindow
extends PanelContainer
## Encomendas do comerciante e eventos em andamento (Fase 11). Cada oferta mostra o pedido, o
## prêmio e o tempo para responder, com aceitar e recusar; a aceita mostra o entregue e o prazo. A
## entrega é vender o bem no posto do comerciante (rota ou painel do navio). Abaixo, os eventos com
## a descrição, o lugar e o tempo que falta.

var _simulation: Simulation
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
	UiKit.clear(_missions)
	UiKit.clear(_events)
	var state := _simulation.world.events_state
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
