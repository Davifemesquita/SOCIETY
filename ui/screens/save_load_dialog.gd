class_name SaveLoadDialog
extends PanelContainer
## Salvar e carregar com miniatura (seção 10): a lista dos slots, do mais novo para o mais antigo,
## com a miniatura e o resumo (nome, data, dia, população e dinheiro) do escolhido. Para salvar, o
## jogador digita o nome (ou escolhe um slot para gravar por cima); para carregar, escolhe o slot.

signal save_chosen(slot: String, display_name: String)
signal load_chosen(slot: String)
signal closed()

enum Mode { SAVE, LOAD }

var mode: Mode
var slots := ItemList.new()
## Nome digitado (só no modo de salvar; null no de carregar).
var name_edit: LineEdit = LineEdit.new()
var _thumbnail := TextureRect.new()
var _details := Label.new()
var _confirm: Button
var _delete: Button
var _slot_names: PackedStringArray = []


func _init(dialog_mode: Mode) -> void:
	mode = dialog_mode
	name = "SaveLoad"
	theme_type_variation = &"MenuPanel"
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	add_child(column)
	column.add_child(UiKit.header("SAVE_TITLE" if mode == Mode.SAVE else "LOAD_TITLE", func() -> void: closed.emit()))
	var body := HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 16)
	column.add_child(body)
	slots.custom_minimum_size = Vector2(420, 380)
	slots.fixed_icon_size = Vector2i(96, 54)
	slots.max_text_lines = 2
	slots.focus_mode = Control.FOCUS_NONE
	slots.item_selected.connect(_on_selected)
	slots.item_activated.connect(func(_index: int) -> void: confirm())
	body.add_child(slots)
	var side := VBoxContainer.new()
	side.add_theme_constant_override(&"separation", 10)
	body.add_child(side)
	_thumbnail.custom_minimum_size = Vector2(320, 180)
	_thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	side.add_child(_thumbnail)
	_details.custom_minimum_size.x = 320
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_details)
	if mode == Mode.SAVE:
		side.add_child(UiKit.label("SAVE_NAME"))
		name_edit.placeholder_text = tr("SAVE_NAME_PLACEHOLDER")
		name_edit.tooltip_text = "SAVE_NAME_TIP"
		name_edit.max_length = 40
		name_edit.text_submitted.connect(func(_text: String) -> void: confirm())
		side.add_child(name_edit)
	else:
		# só o salvar digita nome: no carregar o campo nem entra na árvore
		name_edit.free()
		name_edit = null
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 10)
	side.add_child(buttons)
	_delete = UiKit.button("SAVE_DELETE", "action_delete", _delete_selected, "SAVE_DELETE_TIP")
	_delete.name = "Delete"
	buttons.add_child(_delete)
	_confirm = UiKit.button("SAVE_CONFIRM" if mode == Mode.SAVE else "LOAD_CONFIRM", "action_save" if mode == Mode.SAVE else "action_load", confirm)
	_confirm.name = "Confirm"
	_confirm.theme_type_variation = &"MenuButtonLarge"
	buttons.add_child(_confirm)
	refresh()


func refresh() -> void:
	slots.clear()
	_slot_names = SaveSystem.list_slots()
	for slot: String in _slot_names:
		var info := SaveSystem.read_info(slot)
		var image := SaveSystem.read_thumbnail(slot)
		var icon: Texture2D = ImageTexture.create_from_image(image) if image != null else Icons.action("save")
		slots.add_item("%s\n%s" % [_display_name(slot, info), _date(info)], icon)
	_on_selected(0 if not _slot_names.is_empty() else -1)
	if not _slot_names.is_empty():
		slots.select(0)


func selected_slot() -> String:
	var picked := slots.get_selected_items()
	return _slot_names[picked[0]] if not picked.is_empty() else ""


func _on_selected(index: int) -> void:
	var has_slot := index >= 0 and index < _slot_names.size()
	_delete.disabled = not has_slot
	if mode == Mode.LOAD:
		_confirm.disabled = not has_slot
	if not has_slot:
		_thumbnail.texture = null
		_details.text = tr("LOAD_EMPTY") if _slot_names.is_empty() else ""
		return
	var slot := _slot_names[index]
	var info := SaveSystem.read_info(slot)
	var image := SaveSystem.read_thumbnail(slot)
	_thumbnail.texture = ImageTexture.create_from_image(image) if image != null else null
	var lines: PackedStringArray = [_display_name(slot, info), _date(info)]
	var day: Variant = info.get("day")
	var population: Variant = info.get("population")
	var money: Variant = info.get("money")
	if day is float and population is float and money is float:
		var day_value: float = day
		var population_value: float = population
		var money_value: float = money
		lines.append(tr("SAVE_SUMMARY") % [roundi(day_value), Fmt.integer(population_value), Fmt.integer(money_value)])
	_details.text = "\n".join(lines)
	if mode == Mode.SAVE:
		name_edit.text = _display_name(slot, info)


func confirm() -> void:
	if mode == Mode.LOAD:
		var slot := selected_slot()
		if not slot.is_empty():
			load_chosen.emit(slot)
		return
	var typed := name_edit.text.strip_edges()
	var slot := SaveSystem.slot_from_name(typed)
	if slot.is_empty():
		name_edit.placeholder_text = tr("SAVE_NAME_INVALID")
		name_edit.text = ""
		return
	save_chosen.emit(slot, typed)


func _delete_selected() -> void:
	var slot := selected_slot()
	if slot.is_empty():
		return
	SaveSystem.delete_slot(slot)
	refresh()


func _display_name(slot: String, info: Dictionary) -> String:
	var name_value: Variant = info.get("name")
	if name_value is String:
		var text: String = name_value
		if not text.is_empty():
			return text
	return tr("SAVE_QUICK") if slot == GameScreen.QUICK_SLOT else slot


static func _date(info: Dictionary) -> String:
	var raw: Variant = info.get("saved_at_unix")
	var stamp := 0
	if raw is float:
		var value: float = raw
		stamp = roundi(value)
	elif raw is int:
		stamp = raw
	if stamp <= 0:
		return ""
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	var date := Time.get_datetime_dict_from_unix_time(stamp + bias * 60)
	return "%02d/%02d/%04d %02d:%02d" % [date["day"], date["month"], date["year"], date["hour"], date["minute"]]
