class_name SpecialistWindow
extends PanelContainer
## Especialistas (Fase 11): a oferta que o comerciante trouxe nesta volta (contratar) e os
## contratados, com o posto de cada um (retirar, dispensar). Aberta pelo painel de um prédio, cada
## contratado sem posto que serve a ele ganha "Designar aqui".

var _simulation: Simulation
var _offers := VBoxContainer.new()
var _hired := VBoxContainer.new()
var _hired_title := Label.new()
var _target_label := Label.new()
## Prédio para onde designar (0 = aberta pela barra, sem prédio).
var target_building: int = 0


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	name = "Specialists"
	visible = false
	custom_minimum_size.x = 600
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	column.add_child(UiKit.header("SPECIALISTS_TITLE", func() -> void: visible = false))
	var intro := HBoxContainer.new()
	intro.add_theme_constant_override(&"separation", 12)
	column.add_child(intro)
	var portrait := UiKit.icon_rect(Icons.portrait("trader"), 80)
	portrait.custom_minimum_size = Vector2(64, 80)
	portrait.tooltip_text = "PORTRAIT_TRADER"
	intro.add_child(portrait)
	var hint := UiKit.label("SPECIALISTS_HINT", &"DimLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# com quebra de linha e sem largura, o rótulo quebraria a cada letra e esticaria a janela
	hint.custom_minimum_size.x = 480
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.add_child(hint)
	_target_label.name = "Target"
	_target_label.theme_type_variation = &"HeaderLabel"
	column.add_child(_target_label)
	column.add_child(UiKit.label("SPECIALISTS_OFFER", &"HeaderLabel"))
	_offers.add_theme_constant_override(&"separation", 8)
	column.add_child(_offers)
	column.add_child(HSeparator.new())
	_hired_title.theme_type_variation = &"HeaderLabel"
	column.add_child(_hired_title)
	_hired.add_theme_constant_override(&"separation", 8)
	column.add_child(_hired)
	for event_signal: Signal in [EventBus.specialists_changed, EventBus.world_replaced]:
		event_signal.connect(_rebuild_if_open)


func toggle() -> void:
	target_building = 0
	visible = not visible
	if visible:
		rebuild()


func open(building_id: int = 0) -> void:
	target_building = building_id
	visible = true
	rebuild()


func _rebuild_if_open() -> void:
	if visible:
		rebuild()


func rebuild() -> void:
	UiKit.clear(_offers)
	UiKit.clear(_hired)
	var world := _simulation.world
	var state := world.specialists_state
	var target := world.building(target_building)
	if target == null:
		target_building = 0
	_target_label.visible = target != null
	if target != null:
		_target_label.text = tr("SPECIALISTS_FOR") % [tr(_simulation.def_of(target).name_key), Fmt.place(target.island_id)]
	if world.trader.ship_id == 0:
		_offers.add_child(UiKit.label("SPECIALISTS_NO_TRADER", &"DimLabel"))
	elif state.offers.is_empty():
		_offers.add_child(UiKit.label("SPECIALISTS_OFFER_EMPTY", &"DimLabel"))
	for def_id: StringName in state.offers:
		_offers.add_child(_offer_row(_simulation.data.specialist(def_id)))
	_hired_title.text = tr("SPECIALISTS_HIRED") % [state.specialists.size(), _simulation.config.max_specialists]
	if state.specialists.is_empty():
		_hired.add_child(UiKit.label("SPECIALISTS_NONE", &"DimLabel"))
	for item: Specialist in state.specialists:
		_hired.add_child(_hired_row(item, target))
	reset_size()
	_center.call_deferred()


## Volta ao meio da tela depois de mudar de tamanho (a lista cresce e encolhe).
func _center() -> void:
	reset_size()
	position = ((get_parent_area_size() - size) / 2.0).round()


func _offer_row(def: SpecialistDef) -> Control:
	var row := _row(def)
	row.name = "Offer_%s" % def.id
	var text: VBoxContainer = row.get_child(1)
	text.add_child(UiKit.label(tr("SPECIALIST_PRICE") % [Fmt.integer(def.hire_cost), Fmt.integer(def.salary_per_min)], &"DimLabel"))
	var hire := UiKit.button("SPECIALIST_HIRE", "action_confirm", func() -> void: _execute(SpecialistCommand.hire(def.id)),
			"SPECIALIST_HIRE_TIP")
	hire.name = "Hire"
	var reason := SpecialistCommand.check(_simulation.world, _simulation.data, _simulation.config, SpecialistCommand.hire(def.id),
			_simulation.free_build)
	if reason != &"":
		hire.disabled = true
		hire.tooltip_text = tr(reason)
	row.add_child(hire)
	return row


func _hired_row(item: Specialist, target: BuildingRecord) -> Control:
	var row := _row(item.def)
	row.name = "Specialist_%d" % item.id
	var text: VBoxContainer = row.get_child(1)
	var post := _simulation.world.building(item.building_id)
	var where := UiKit.label(tr("SPECIALIST_AT") % [tr(_simulation.def_of(post).name_key), Fmt.place(post.island_id)]
			if post != null else tr("SPECIALIST_NO_POST"), &"DimLabel")
	if post == null:
		UiPalette.paint(where, UiPalette.Status.PARTIAL)
	text.add_child(where)
	if target != null and item.building_id != target.id and item.def.covers(_simulation.def_of(target)):
		var assign := UiKit.button("SPECIALIST_ASSIGN", "action_confirm", func() -> void:
			_execute(SpecialistCommand.assign(item.id, target.id)), "SPECIALIST_ASSIGN_TIP")
		assign.name = "Assign"
		var reason := SpecialistCommand.check(_simulation.world, _simulation.data, _simulation.config,
				SpecialistCommand.assign(item.id, target.id))
		if reason != &"":
			assign.disabled = true
			assign.tooltip_text = tr(reason)
		row.add_child(assign)
	if post != null:
		var unassign := UiKit.button("SPECIALIST_UNASSIGN", "action_back", func() -> void:
			_execute(SpecialistCommand.unassign(item.id)), "SPECIALIST_UNASSIGN_TIP")
		unassign.name = "Unassign"
		row.add_child(unassign)
	var dismiss := UiKit.icon_button("action_close", "SPECIALIST_DISMISS_TIP", func() -> void:
		_execute(SpecialistCommand.dismiss(item.id)))
	dismiss.name = "Dismiss"
	row.add_child(dismiss)
	return row


## Ícone, título e efeito; quem chama acrescenta o resto ao texto e os botões à linha.
func _row(def: SpecialistDef) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	row.add_child(UiKit.icon_rect(Icons.get_icon(icon_name(def.id)), 40))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UiKit.label(def.title_key(), &"HeaderLabel"))
	var description := UiKit.label(description_of(def), &"DimLabel")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 340
	text.add_child(description)
	return row


## O botão já vem desligado com o motivo quando o gesto seria recusado.
func _execute(command: SpecialistCommand) -> void:
	_simulation.execute(command)
	rebuild()


static func icon_name(def_id: StringName) -> String:
	return "specialist_" + String(def_id)


## A descrição com o número do efeito.
static func description_of(def: SpecialistDef) -> String:
	var text := TranslationServer.translate(def.description_key())
	if def.effect == SpecialistDef.Effect.EXTRA_OUTPUT:
		return text % Fmt.integer(def.cycles_per_extra())
	return text % Fmt.percent(def.amount)
