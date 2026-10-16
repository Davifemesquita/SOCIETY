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
	EventBus.world_event_started.connect(func(def_id: StringName, island_id: int) -> void: push(watcher.event_started(def_id, island_id)))
	EventBus.mission_offered.connect(func(mission_id: int) -> void: push(watcher.mission_offered(mission_id)))
	EventBus.mission_completed.connect(func(def_id: StringName, bonus: int) -> void: push(watcher.mission_completed(def_id, bonus)))
	EventBus.mission_expired.connect(func(def_id: StringName, accepted: bool) -> void:
		if accepted:
			push(watcher.mission_expired(def_id)))
	EventBus.rival_colonized.connect(func(rival_id: StringName, island_id: int) -> void: push(watcher.rival_colonized(rival_id, island_id)))
	EventBus.rival_stance_changed.connect(func(rival_id: StringName, stance: int) -> void: push(watcher.rival_stance(rival_id, stance)))
	EventBus.ship_sunk.connect(func(_ship_id: int, owner: int, _at: Vector2) -> void: push(watcher.ship_sunk(owner)))
	EventBus.ship_fired.connect(_on_ship_fired)
	EventBus.fire_started.connect(func(building_id: int) -> void: push(watcher.fire_started(building_id)))
	EventBus.fire_ended.connect(func(building_id: int, lost: bool) -> void:
		if not lost:
			push(watcher.fire_out(building_id)))
	EventBus.building_lost.connect(func(building_id: int, def_id: StringName, island_id: int) -> void:
		push(watcher.building_lost(building_id, def_id, island_id)))
	EventBus.outbreak_started.connect(func(house_id: int) -> void: push(watcher.outbreak(house_id)))
	EventBus.world_replaced.connect(func() -> void:
		clear()
		watcher.reset())


## Tiro num navio nosso: avisa, sem repetir enquanto o aviso daquele navio está na tela.
func _on_ship_fired(_attacker: int, target_id: int) -> void:
	var target := watcher.simulation_world().ship(target_id)
	if target == null or target.owner != Ship.Owner.PLAYER or _items.has("attack/%d" % target_id):
		return
	push(watcher.under_attack(target_id))


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
