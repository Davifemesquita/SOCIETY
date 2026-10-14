class_name StatisticsWindow
extends PanelContainer
## Estatísticas (seção 10), em três abas. Produção: por bem, produção atual e potencial, consumo e
## estoque em t/min, na ilha escolhida (ou todas), e o gráfico histórico do bem escolhido.
## População: moradores por classe, com retrato, e o gráfico. Finanças: receita, manutenção e
## saldo por minuto, o nível de imposto de cada classe e o gráfico do dinheiro e do saldo.
## Mostra só os bens com alguma atividade.

const REFRESH_SECONDS := 0.5
## Ilha "todas" no seletor.
const ALL_ISLANDS := -1
const PRODUCED_COLOR := Color("2f7a32")
const CONSUMED_COLOR := Color("b0281c")
const MONEY_COLOR := Color("8a6a1e")
const BALANCE_COLOR := Color("2b5a8a")
const TIER_COLORS: Array[Color] = [Color("7a5a36"), Color("2b5a8a"), Color("6e2a26"), Color("2f7a32"), Color("5c4a36")]

var _simulation: Simulation
var _tabs := TabContainer.new()
var _island := OptionButton.new()
var _grid := GridContainer.new()
var _good_chart := LineChart.new()
var _chart_good: StringName = &""
var _population_rows := GridContainer.new()
var _population_chart := LineChart.new()
var _finances := Label.new()
var _finance_chart := LineChart.new()
## O saldo por minuto (centenas) some na escala do dinheiro (dezenas de milhares): gráfico próprio.
var _balance_chart := LineChart.new()
var _seed := Label.new()
var _tax_options: Dictionary[StringName, OptionButton] = {}
var _refresh_left: float = 0.0


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	visible = false
	custom_minimum_size = Vector2(820, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	column.add_child(UiKit.header("STATS_TITLE", func() -> void: visible = false))
	_tabs.focus_mode = Control.FOCUS_NONE
	column.add_child(_tabs)
	_tabs.add_child(_production_tab())
	_tabs.add_child(_population_tab())
	_tabs.add_child(_finance_tab())
	_name_tabs()
	EventBus.settings_changed.connect(_name_tabs)
	EventBus.world_replaced.connect(func() -> void:
		_fill_islands()
		_chart_good = &"")
	_fill_islands()


func toggle() -> void:
	visible = not visible
	if visible:
		_fill_islands()
		refresh()


func _name_tabs() -> void:
	var tabs: Array[Array] = [["STATS_TAB_PRODUCTION", "action_statistics"], ["STATS_TAB_POPULATION", "hud_population"],
			["STATS_TAB_FINANCES", "hud_money"]]
	for index: int in tabs.size():
		var key: String = tabs[index][0]
		var icon_name: String = tabs[index][1]
		_tabs.set_tab_title(index, tr(key))
		_tabs.set_tab_icon(index, Icons.get_icon(icon_name))


func _production_tab() -> Control:
	var page := VBoxContainer.new()
	page.name = "Production"
	page.add_theme_constant_override(&"separation", 8)
	var top := HBoxContainer.new()
	page.add_child(top)
	top.add_child(UiKit.icon_rect(Icons.get_icon("hud_island"), 26))
	top.add_child(UiKit.label("STATS_ISLAND"))
	_island.focus_mode = Control.FOCUS_NONE
	_island.tooltip_text = "STATS_ISLAND_TIP"
	_island.item_selected.connect(func(_index: int) -> void: refresh())
	top.add_child(_island)
	var unit := UiKit.label("STATS_RATES", &"DimLabel")
	unit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(unit)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(780, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	_grid.columns = 7
	_grid.add_theme_constant_override(&"h_separation", 22)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)
	page.add_child(_good_chart)
	return page


func _population_tab() -> Control:
	var page := VBoxContainer.new()
	page.name = "Population"
	page.add_theme_constant_override(&"separation", 10)
	_population_rows.columns = 4
	_population_rows.add_theme_constant_override(&"h_separation", 18)
	page.add_child(_population_rows)
	page.add_child(_seed)
	page.add_child(_population_chart)
	return page


func _finance_tab() -> Control:
	var page := VBoxContainer.new()
	page.name = "Finances"
	page.add_theme_constant_override(&"separation", 10)
	page.add_child(_finances)
	var taxes := GridContainer.new()
	taxes.columns = 3
	taxes.add_theme_constant_override(&"h_separation", 12)
	page.add_child(taxes)
	for tier: TierDef in _simulation.data.tiers:
		taxes.add_child(UiKit.icon_rect(Icons.tier(tier.id), 28))
		taxes.add_child(UiKit.label("%s · %s" % [tr("STATS_TAX_LEVEL"), tr(tier.name_key)]))
		var option := OptionButton.new()
		option.focus_mode = Control.FOCUS_NONE
		option.tooltip_text = "STATS_TAX_TIP"
		for key: String in ["TAX_LOW", "TAX_NORMAL", "TAX_HIGH"]:
			option.add_icon_item(Icons.get_icon("hud_tax"), tr(key))
		var tier_id := tier.id
		option.item_selected.connect(func(level: int) -> void: _simulation.execute(SetTaxLevelCommand.new(tier_id, level)))
		taxes.add_child(option)
		_tax_options[tier.id] = option
	_finance_chart.custom_minimum_size.y = 160
	_balance_chart.custom_minimum_size.y = 160
	page.add_child(_finance_chart)
	page.add_child(_balance_chart)
	return page


## Ilhas com entreposto, mais "todas".
func _fill_islands() -> void:
	var previous := _island.get_selected_id() if _island.item_count > 0 else Simulation.MAIN_ISLAND
	_island.clear()
	_island.add_item(tr("STATS_ALL_ISLANDS"), 1000)
	for island_id: int in _simulation.world.islands.size():
		if island_id == Simulation.MAIN_ISLAND or _simulation.world.has_trading_post(island_id, _simulation.data):
			_island.add_item(Fmt.place(island_id), island_id)
	var at := _island.get_item_index(previous)
	_island.select(at if at >= 0 else 1)


func selected_island() -> int:
	var id := _island.get_selected_id()
	return ALL_ISLANDS if id == 1000 else id


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		refresh()


func refresh() -> void:
	_refresh_goods()
	_refresh_population()
	_refresh_finances()


## Soma das ilhas (todas) ou a escolhida.
func _report() -> Statistics:
	var island := selected_island()
	if island != ALL_ISLANDS:
		return _simulation.statistics(island)
	var total: Statistics = null
	for island_id: int in _simulation.world.islands.size():
		var report := _simulation.statistics(island_id)
		if total == null:
			total = report
			continue
		for line: Statistics.GoodLine in report.goods:
			var sum := total.line(line.good)
			sum.produced += line.produced
			sum.potential += line.potential
			sum.consumed_by_houses += line.consumed_by_houses
			sum.consumed_by_buildings += line.consumed_by_buildings
			sum.stock += line.stock
	return total


func _refresh_goods() -> void:
	var report := _report()
	UiKit.clear(_grid)
	for key: String in ["", "STATS_GOOD", "STATS_PRODUCED", "STATS_POTENTIAL", "STATS_CONSUMED", "STATS_STOCK", ""]:
		_grid.add_child(UiKit.label(key, &"DimLabel"))
	for line: Statistics.GoodLine in report.goods:
		if line.potential <= 0.0 and line.consumed() <= 0.0 and line.stock <= 0.0:
			continue
		if _chart_good == &"":
			_chart_good = line.good
		_grid.add_child(UiKit.icon_rect(Icons.good(line.good), 24))
		_cell(tr(_simulation.data.good(line.good).name_key))
		_cell(Fmt.decimal(line.produced, 2))
		_cell(Fmt.decimal(line.potential, 2))
		var consumed := _cell(Fmt.decimal(line.consumed(), 2))
		if line.consumed() > line.produced + 0.001:
			UiPalette.paint(consumed, UiPalette.Status.BAD)
		_cell(Fmt.decimal(line.stock))
		var good := line.good
		var chart := UiKit.icon_button("action_statistics", "STATS_CHART_TIP", func() -> void:
			_chart_good = good
			_refresh_goods())
		chart.toggle_mode = true
		chart.set_pressed_no_signal(good == _chart_good)
		_grid.add_child(chart)
	_refresh_good_chart()


func _refresh_good_chart() -> void:
	var history := _simulation.world.history
	if _chart_good == &"":
		_good_chart.set_series([], [], [], "")
		return
	var name := tr(_simulation.data.good(_chart_good).name_key)
	var produced := history.good_series(selected_island(), _chart_good, true)
	var consumed := history.good_series(selected_island(), _chart_good, false)
	_good_chart.set_series([produced, consumed], [PRODUCED_COLOR, CONSUMED_COLOR],
			[tr("CHART_PRODUCED") % name, tr("CHART_CONSUMED") % name], _span())


func _refresh_population() -> void:
	var world := _simulation.world
	UiKit.clear(_population_rows)
	var series: Array[PackedFloat32Array] = []
	var colors: Array[Color] = []
	var names: Array[String] = []
	var total := 0
	for index: int in _simulation.data.tiers.size():
		var tier := _simulation.data.tiers[index]
		var portrait := UiKit.icon_rect(Icons.portrait("tier_" + tier.id), 64)
		portrait.custom_minimum_size = Vector2(52, 64)
		_population_rows.add_child(portrait)
		_population_rows.add_child(UiKit.icon_rect(Icons.tier(tier.id), 32))
		_population_rows.add_child(UiKit.label(tr(tier.name_key), &"HeaderLabel"))
		var count := world.population(tier.id)
		total += count
		_population_rows.add_child(UiKit.label(Fmt.integer(count)))
		series.append(world.history.population.get(tier.id, PackedFloat32Array()))
		colors.append(TIER_COLORS[index % TIER_COLORS.size()])
		names.append(tr(tier.name_key))
	_seed.text = tr("STATS_POPULATION_TOTAL") % Fmt.integer(total)
	if world.terrain_version != 0:
		_seed.text += "    " + tr("PANEL_SEED") % world.seed
	_population_chart.set_series(series, colors, names, _span())


func _refresh_finances() -> void:
	var world := _simulation.world
	var balance := world.income_per_min - world.upkeep_per_min
	_finances.text = "%s %s · %s %s · %s %s" % [tr("STATS_INCOME"), Fmt.signed(world.income_per_min),
			tr("STATS_UPKEEP"), Fmt.integer(-world.upkeep_per_min), tr("STATS_BALANCE"), Fmt.signed(balance)]
	for tier_id: StringName in _tax_options:
		_tax_options[tier_id].select(world.tax_level(tier_id))
	var history := world.history
	var balances := PackedFloat32Array()
	for i: int in history.size():
		balances.append(history.income[i] - history.upkeep[i])
	_finance_chart.set_series([history.money], [MONEY_COLOR], [tr("CHART_MONEY")], _span())
	_balance_chart.set_series([history.income, history.upkeep, balances], [PRODUCED_COLOR, CONSUMED_COLOR, BALANCE_COLOR],
			[tr("STATS_INCOME"), tr("STATS_UPKEEP"), tr("CHART_BALANCE")], _span())


## Período que o gráfico cobre, em minutos de jogo.
func _span() -> String:
	var history := _simulation.world.history
	if history.size() < 2:
		return ""
	var minutes := (history.ticks[history.size() - 1] - history.ticks[0]) / float(_simulation.config.ticks_per_second) / 60.0
	return tr("CHART_SPAN") % Fmt.integer(minutes)


func _cell(text: String) -> Label:
	var label := Label.new()
	label.text = text
	_grid.add_child(label)
	return label
