class_name StatisticsWindow
extends PanelContainer
## Tela de estatísticas da ilha: por bem, produção atual e potencial, consumo e estoque;
## população por classe; finanças por minuto e o nível de imposto de cada classe.
## Mostra só os bens com alguma atividade. Gráficos históricos entram na Fase 7.

const REFRESH_SECONDS := 0.5

var _simulation: Simulation
var _grid := GridContainer.new()
var _population := Label.new()
var _finances := Label.new()
var _tax_options: Dictionary[StringName, OptionButton] = {}
var _refresh_left: float = 0.0


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	visible = false
	custom_minimum_size = Vector2(720, 0)
	add_theme_stylebox_override(&"panel", UiStyle.panel())
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "STATS_TITLE"
	title.add_theme_font_size_override(&"font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "STATS_CLOSE"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func() -> void: visible = false)
	header.add_child(close)
	var unit := Label.new()
	unit.text = "STATS_RATES"
	unit.modulate = Color(1, 1, 1, 0.6)
	column.add_child(unit)
	_grid.columns = 5
	_grid.add_theme_constant_override(&"h_separation", 28)
	column.add_child(_grid)
	column.add_child(HSeparator.new())
	column.add_child(_population)
	column.add_child(_finances)
	var taxes := HBoxContainer.new()
	taxes.add_theme_constant_override(&"separation", 12)
	column.add_child(taxes)
	for tier: TierDef in simulation.data.tiers:
		var label := Label.new()
		label.text = "%s · %s" % [tr("STATS_TAX_LEVEL"), tr(tier.name_key)]
		taxes.add_child(label)
		var option := OptionButton.new()
		option.focus_mode = Control.FOCUS_NONE
		for key: String in ["TAX_LOW", "TAX_NORMAL", "TAX_HIGH"]:
			option.add_item(tr(key))
		var tier_id := tier.id
		option.item_selected.connect(func(level: int) -> void: simulation.execute(SetTaxLevelCommand.new(tier_id, level)))
		taxes.add_child(option)
		_tax_options[tier.id] = option


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		refresh()


func refresh() -> void:
	var report := _simulation.statistics()
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for key: String in ["STATS_GOOD", "STATS_PRODUCED", "STATS_POTENTIAL", "STATS_CONSUMED", "STATS_STOCK"]:
		var heading := Label.new()
		heading.text = key
		heading.modulate = Color(1, 1, 1, 0.7)
		_grid.add_child(heading)
	for line: Statistics.GoodLine in report.goods:
		if line.potential <= 0.0 and line.consumed() <= 0.0 and line.stock <= 0.0:
			continue
		_cell(tr(_simulation.data.good(line.good).name_key))
		_cell(Fmt.decimal(line.produced, 2))
		_cell(Fmt.decimal(line.potential, 2))
		var consumed := _cell(Fmt.decimal(line.consumed(), 2))
		if line.consumed() > line.produced + 0.001:
			consumed.modulate = SelectionPanel.RED
		_cell(Fmt.decimal(line.stock))
	var parts: PackedStringArray = []
	for tier: TierDef in _simulation.data.tiers:
		parts.append("%s %s" % [tr(tier.name_key), Fmt.integer(report.population[tier.id])])
	_population.text = "%s: %s" % [tr("STATS_POPULATION"), " · ".join(parts)]
	_finances.text = "%s: %s %s · %s %s · %s %s" % [tr("STATS_FINANCES"), tr("STATS_INCOME"), Fmt.signed(report.income_per_min),
			tr("STATS_UPKEEP"), Fmt.integer(-report.upkeep_per_min), tr("STATS_BALANCE"), Fmt.signed(report.balance_per_min())]
	for tier_id: StringName in _tax_options:
		_tax_options[tier_id].select(_simulation.world.tax_level(tier_id))


func _cell(text: String) -> Label:
	var label := Label.new()
	label.text = text
	_grid.add_child(label)
	return label
