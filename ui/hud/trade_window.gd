class_name TradeWindow
extends PanelContainer
## Comércio passivo de uma ilha com o comerciante (Fase 6): para cada bem que ele negocia, o
## preço desta volta e os dois ajustes: vender o que passar de X t e comprar até ter Y t. O navio
## dele passa pelo entreposto de tempos em tempos e negocia por aqui.

const MAX_TONS := 200

var _simulation: Simulation
var _island: int = 0
var _title := Label.new()
var _rows := GridContainer.new()


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	add_child(column)
	column.add_child(UiKit.header("", func() -> void: visible = false, _title))
	var intro := HBoxContainer.new()
	intro.add_theme_constant_override(&"separation", 12)
	column.add_child(intro)
	var portrait := UiKit.icon_rect(Icons.portrait("trader"), 96)
	portrait.custom_minimum_size = Vector2(80, 100)
	portrait.tooltip_text = "PORTRAIT_TRADER"
	intro.add_child(portrait)
	var hint := UiKit.label("TRADE_HINT", &"DimLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 420
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.add_child(hint)
	_rows.columns = 6
	_rows.add_theme_constant_override(&"h_separation", 14)
	column.add_child(_rows)
	EventBus.world_replaced.connect(func() -> void: visible = false)


## Abre a janela para a ilha.
func open(island_id: int) -> void:
	_island = island_id
	visible = true
	_build()


func _build() -> void:
	# fora da árvore já: o nome fica livre para o filho novo de mesmo nome
	UiKit.clear(_rows)
	var trader := _simulation.data.trader()
	if trader == null:
		return
	_title.text = tr("TRADE_TITLE") % Fmt.place(_island)
	for key: String in ["", "TRADE_COL_GOOD", "TRADE_COL_PRICE", "TRADE_COL_STOCK", "TRADE_COL_SELL", "TRADE_COL_BUY"]:
		_rows.add_child(UiKit.label(key, &"DimLabel"))
	var economy := _simulation.world.economy(_island)
	var goods: Array[StringName] = trader.buys.duplicate()
	for good: StringName in trader.sells:
		if not goods.has(good):
			goods.append(good)
	for good: StringName in goods:
		var def := _simulation.data.good(good)
		_rows.add_child(UiKit.icon_rect(Icons.good(good), 26))
		_rows.add_child(_label(tr(def.name_key)))
		var price := _simulation.world.trader_price(_simulation.data, _simulation.config, good)
		_rows.add_child(_label(Fmt.integer(price)))
		_rows.add_child(_label(Fmt.integer(economy.amount(good))))
		_rows.add_child(_setting(good, true, trader.buys.has(good), economy.sell_above))
		_rows.add_child(_setting(good, false, trader.sells.has(good), economy.buy_up_to))


## Caixa para ligar e toneladas do ajuste; sem o bem na lista do comerciante, fica vazio.
func _setting(good: StringName, selling: bool, offered: bool, current: Dictionary[StringName, int]) -> Control:
	var row := HBoxContainer.new()
	if not offered:
		return row
	var check := CheckBox.new()
	check.focus_mode = Control.FOCUS_NONE
	check.tooltip_text = "TRADE_SELL_TIP" if selling else "TRADE_BUY_TIP"
	check.button_pressed = current.has(good)
	row.add_child(check)
	var amount := SpinBox.new()
	amount.min_value = 0
	amount.max_value = MAX_TONS
	amount.step = 5
	amount.value = current.get(good, 20 if selling else 10)
	amount.editable = check.button_pressed
	row.add_child(amount)
	row.name = ("Sell_" if selling else "Buy_") + String(good)
	var apply := func() -> void:
		amount.editable = check.button_pressed
		_apply(good, selling, roundi(amount.value) if check.button_pressed else -1)
	check.toggled.connect(func(_on: bool) -> void: apply.call())
	amount.value_changed.connect(func(_value: float) -> void: apply.call())
	return row


func _apply(good: StringName, selling: bool, tons: int) -> void:
	var economy := _simulation.world.economy(_island)
	var sell: int = tons if selling else economy.sell_above.get(good, -1)
	var buy: int = economy.buy_up_to.get(good, -1) if selling else tons
	_simulation.execute(SetTradeSettingCommand.new(_island, good, sell, buy))


static func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label
