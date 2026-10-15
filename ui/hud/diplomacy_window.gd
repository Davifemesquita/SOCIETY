class_name DiplomacyWindow
extends PanelContainer
## As companhias rivais (Fase 11): para cada uma, a cor, o nome, o temperamento, as ilhas e os
## moradores, a relação (barra de -100 a 100) e a postura, com os gestos: presente, acordo comercial
## (propor ou desfazer), guerra e paz. O botão de gesto recusado fica desligado com o motivo na dica.

const ACTIONS: Array[DiplomacyCommand.Action] = [DiplomacyCommand.Action.GIFT, DiplomacyCommand.Action.PROPOSE_TRADE,
		DiplomacyCommand.Action.CANCEL_TRADE, DiplomacyCommand.Action.DECLARE_WAR, DiplomacyCommand.Action.PROPOSE_PEACE]
const ACTION_KEYS: Array[String] = ["RIVALS_GIFT", "RIVALS_TRADE", "RIVALS_CANCEL_TRADE", "RIVALS_WAR", "RIVALS_PEACE"]
const ACTION_ICONS: Array[String] = ["action_gift", "action_treaty", "action_close", "action_war", "action_peace"]
const STANCE_KEYS: Array[String] = ["RIVALS_STANCE_NEUTRAL", "RIVALS_STANCE_TRADE", "RIVALS_STANCE_WAR"]
const STANCE_STATUS: Array[UiPalette.Status] = [UiPalette.Status.NEUTRAL, UiPalette.Status.GOOD, UiPalette.Status.BAD]
const PERSONALITY_KEYS: Array[String] = ["RIVALS_PEACEFUL", "RIVALS_AMBITIOUS", "RIVALS_AGGRESSIVE"]

var _simulation: Simulation
var _rows := VBoxContainer.new()
var _refresh_left: float = 0.0


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	name = "Diplomacy"
	visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	column.add_child(UiKit.header("RIVALS_TITLE", func() -> void: visible = false))
	var hint := UiKit.label("RIVALS_HINT", &"DimLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 640
	column.add_child(hint)
	_rows.add_theme_constant_override(&"separation", 12)
	column.add_child(_rows)
	EventBus.rivals_changed.connect(_rebuild_if_open)
	EventBus.world_replaced.connect(_rebuild_if_open)
	EventBus.rival_colonized.connect(func(_rival: StringName, _island: int) -> void: _rebuild_if_open())
	EventBus.rival_stance_changed.connect(func(_rival: StringName, _stance: int) -> void: _rebuild_if_open())


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


## A relação anda sozinha: refaz de tempos em tempos enquanto está aberta.
func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = 2.0
		rebuild()


func rebuild() -> void:
	UiKit.clear(_rows)
	var state := _simulation.world.rivals_state
	if not state.enabled:
		_rows.add_child(UiKit.label("RIVALS_DISABLED", &"DimLabel"))
	for rival: RivalState in state.rivals:
		_rows.add_child(_row(rival))
	reset_size()
	_center.call_deferred()


func _center() -> void:
	reset_size()
	position = ((get_parent_area_size() - size) / 2.0).round()


func _row(rival: RivalState) -> Control:
	var config := _simulation.config
	var box := VBoxContainer.new()
	box.name = "Rival_" + String(rival.def_id)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 10)
	box.add_child(top)
	# a cor da rival numa faixa ao lado da bandeira (o tom sobre a tinta escura do ícone não aparece)
	var swatch := ColorRect.new()
	swatch.name = "Color"
	swatch.color = rival.def.color
	swatch.custom_minimum_size = Vector2(10, 40)
	swatch.tooltip_text = rival.def.name_key
	top.add_child(swatch)
	var flag := UiKit.icon_rect(Icons.get_icon("hud_rival"), 40)
	flag.tooltip_text = rival.def.name_key
	top.add_child(flag)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(text)
	text.add_child(UiKit.label(rival.def.name_key, &"HeaderLabel"))
	var islands := ", ".join(rival.island_ids().map(func(island_id: int) -> String: return Fmt.place(island_id)))
	text.add_child(UiKit.label(tr("RIVALS_SUMMARY") % [tr(PERSONALITY_KEYS[rival.def.personality]),
			islands if not islands.is_empty() else tr("RIVALS_NO_ISLANDS"), Fmt.integer(rival.population())], &"DimLabel"))
	var stance := UiKit.label(tr(STANCE_KEYS[rival.stance]))
	stance.name = "Stance"
	UiPalette.paint(stance, STANCE_STATUS[rival.stance])
	top.add_child(stance)
	var relation := HBoxContainer.new()
	relation.add_theme_constant_override(&"separation", 8)
	box.add_child(relation)
	relation.add_child(UiKit.label("RIVALS_RELATION"))
	var bar := ProgressBar.new()
	bar.name = "Relation"
	bar.min_value = -100.0
	bar.max_value = 100.0
	bar.value = rival.relation
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(260, 18)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.tooltip_text = "RIVALS_RELATION_TIP"
	relation.add_child(bar)
	relation.add_child(UiKit.label(Fmt.signed(rival.relation)))
	if rival.stance == RivalState.Stance.TRADE:
		relation.add_child(UiKit.label(tr("RIVALS_TRADE_INCOME") % Fmt.integer(rival.population() * config.rival_trade_income_per_resident), &"DimLabel"))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 6)
	box.add_child(buttons)
	for index: int in ACTIONS.size():
		var action := ACTIONS[index]
		if action == DiplomacyCommand.Action.CANCEL_TRADE and rival.stance != RivalState.Stance.TRADE:
			continue
		if action == DiplomacyCommand.Action.PROPOSE_TRADE and rival.stance == RivalState.Stance.TRADE:
			continue
		if action == DiplomacyCommand.Action.PROPOSE_PEACE and rival.stance != RivalState.Stance.WAR:
			continue
		if action == DiplomacyCommand.Action.DECLARE_WAR and rival.stance == RivalState.Stance.WAR:
			continue
		var button := UiKit.button(ACTION_KEYS[index], ACTION_ICONS[index], func() -> void: _act(rival.def_id, action))
		button.name = "Action_%d" % action
		var reason := DiplomacyCommand.check(_simulation.world, config, rival, action)
		button.disabled = reason != &""
		button.tooltip_text = tr(ACTION_KEYS[index] + "_TIP") % _tip_values(action)
		if reason != &"":
			button.tooltip_text += "\n" + tr(reason)
		buttons.add_child(button)
	box.add_child(HSeparator.new())
	return box


func _tip_values(action: DiplomacyCommand.Action) -> Array:
	var config := _simulation.config
	match action:
		DiplomacyCommand.Action.GIFT:
			return [Fmt.integer(config.rival_gift_money), Fmt.integer(config.rival_gift_relation)]
		DiplomacyCommand.Action.PROPOSE_TRADE:
			return [Fmt.integer(config.rival_trade_relation)]
		DiplomacyCommand.Action.PROPOSE_PEACE:
			return [Fmt.signed(config.rival_peace_relation), Fmt.integer(config.rival_peace_money)]
	return []


func _act(rival_id: StringName, action: DiplomacyCommand.Action) -> void:
	_simulation.execute(DiplomacyCommand.new(rival_id, action))
	rebuild()
