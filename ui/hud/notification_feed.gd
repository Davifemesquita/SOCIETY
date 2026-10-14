class_name NotificationFeed
extends VBoxContainer
## Notificações na lateral direita (seção 10): ícone, texto e clique para ir ao lugar (prédio,
## navio ou ilha). Cada uma some depois de notice_seconds; a mesma situação repetida renova a que
## já está na tela. Mostra no máximo notice_max_visible, as mais novas em cima.

## O jogador clicou: a partida leva a câmera até o lugar.
signal go_to(notice: NoticeWatcher.Notice)

var watcher: NoticeWatcher

var _config: GameConfig
var _items: Dictionary[String, Button] = {}
var _ages: Dictionary[String, float] = {}
var _notices: Dictionary[String, NoticeWatcher.Notice] = {}
var _check_left: float = 0.0


func setup(simulation: Simulation) -> void:
	_config = simulation.config
	watcher = NoticeWatcher.new(simulation)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", 6)
	custom_minimum_size.x = 380
	EventBus.good_shortage.connect(func(island_id: int, good: StringName) -> void: push(watcher.shortage(island_id, good)))
	EventBus.milestone_reached.connect(func(count: int) -> void: push(watcher.milestone(count)))
	EventBus.island_colonized.connect(func(island_id: int) -> void: push(watcher.colonized(island_id)))
	EventBus.trader_visited.connect(func(island_id: int, earned: float, spent: float) -> void:
		push(watcher.trader(island_id, earned, spent)))
	EventBus.world_replaced.connect(func() -> void:
		clear()
		watcher.reset())


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = _config.notice_check_seconds
		for notice: NoticeWatcher.Notice in watcher.check():
			push(notice)
	for key: String in _ages.keys():
		_ages[key] -= delta
		if _ages[key] <= 0.0:
			_remove(key)


## Mostra a notificação (ou renova a mesma, se já está na tela).
func push(notice: NoticeWatcher.Notice) -> void:
	if _items.has(notice.key):
		_remove(notice.key)
	var button := Button.new()
	button.name = "Notice_" + notice.key.validate_node_name().replace("/", "_")
	button.theme_type_variation = &"NoticeButton"
	button.icon = Icons.get_icon(notice.icon)
	button.text = notice.text()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(380, 46)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = tr("NOTICE_CLICK_TIP")
	if notice.status != UiPalette.Status.NEUTRAL:
		button.add_theme_color_override(&"font_color", UiPalette.status(notice.status))
		button.add_theme_color_override(&"font_hover_color", UiPalette.status(notice.status))
	button.pressed.connect(func() -> void:
		go_to.emit(notice)
		_remove(notice.key))
	add_child(button)
	move_child(button, 0)
	EventBus.notice_shown.emit(notice.icon)
	_items[notice.key] = button
	_ages[notice.key] = _config.notice_seconds
	_notices[notice.key] = notice
	while _items.size() > _config.notice_max_visible:
		var oldest := get_child(get_child_count() - 1) as Button
		for key: String in _items:
			if _items[key] == oldest:
				_remove(key)
				break


func shown() -> Array[NoticeWatcher.Notice]:
	var result: Array[NoticeWatcher.Notice] = []
	for child: Node in get_children():
		for key: String in _items:
			if _items[key] == child:
				result.append(_notices[key])
	return result


func clear() -> void:
	for key: String in _items.keys():
		_remove(key)


func _remove(key: String) -> void:
	if not _items.has(key):
		return
	var button := _items[key]
	remove_child(button)
	button.queue_free()
	_items.erase(key)
	_ages.erase(key)
	_notices.erase(key)
