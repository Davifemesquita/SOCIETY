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
	add_theme_stylebox_override(&"panel", UiStyle.panel())
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_title.add_theme_font_size_override(&"font_size", 20)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close := Button.new()
	close.text = "STATS_CLOSE"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func() -> void: visible = false)
	header.add_child(close)
	var hint := Label.new()
	hint.text = "TRADE_HINT"
	hint.modulate = Color(1, 1, 1, 0.6)
	column.add_child(hint)
	_rows.columns = 5
	_rows.add_theme_constant_override(&"h_separation", 14)
	column.add_child(_rows)
	EventBus.world_replaced.connect(func() -> void: visible = false)


## Abre a janela para a ilha.
func open(island_id: int) -> void:
	_island = island_id
	visible = true
	_build()


func _build() -> void:
	for child: Node in _rows.get_children():
		# fora da árvore já: o nome fica livre para o filho novo de mesmo nome
		child.get_parent().remove_child(child)
		child.queue_free()
	var trader := _simulation.data.trader()
	if trader == null:
		return
	_title.text = tr("TRADE_TITLE") % Fmt.place(_island)
	for key: String in ["TRADE_COL_GOOD", "TRADE_COL_PRICE", "TRADE_COL_STOCK", "TRADE_COL_SELL", "TRADE_COL_BUY"]:
		var header := Label.new()
		header.text = key
		header.modulate = Color(1, 1, 1, 0.6)
		_rows.add_child(header)
	var economy := _simulation.world.economy(_island)
	var goods: Array[StringName] = trader.buys.duplicate()
	for good: StringName in trader.sells:
		if not goods.has(good):
			goods.append(good)
	for good: StringName in goods:
		var def := _simulation.data.good(good)
		_rows.add_child(_label(tr(def.name_key)))
		var price := TraderState.price(_simulation.world.seed, _simulation.world.trader.tour, def, _simulation.config.trader_price_variation)
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
