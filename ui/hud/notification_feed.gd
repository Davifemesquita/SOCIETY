class_name NotificationFeed
extends VBoxContainer
## Notificações na lateral direita (seção 10): ícone, texto e clique para ir ao lugar (prédio,
## navio ou ilha). Cada uma some depois de notice_seconds; a mesma situação repetida renova a que
## já está na tela. Mostra no máximo notice_max_visible, as mais novas em cima.

## O jogador clicou: a partida leva a câmera até o lugar.
signal go_to(notice: NoticeWatcher.Notice)

## Fase 30: quanto a notificação leva para aparecer e para esmaecer.
const FADE_S := 0.25
## Fase 43: as categorias do aviso (pelo começo da chave), que as opções silenciam uma a uma; "alert" com o estado ruim
## pausa o jogo se a opção estiver ligada.
const CATEGORIES: Array[String] = ["economy", "alert", "fleet", "diplomacy", "missions", "progress"]
const PREFIXES := {
	"stopped": "economy", "full": "economy", "shortage": "economy", "trader": "economy",
	"fire": "alert", "disease": "alert", "sunk": "alert", "attack": "alert",
	"ship": "fleet", "ship_built": "fleet", "expedition": "fleet",
	"rival": "diplomacy",
	"mission": "missions", "event": "missions", "newspaper": "missions",
	"milestone": "progress", "colony": "progress", "achievement": "progress",
}

var watcher: NoticeWatcher

var _config: GameConfig
var _items: Dictionary[String, Button] = {}
var _ages: Dictionary[String, float] = {}
var _notices: Dictionary[String, NoticeWatcher.Notice] = {}
## Fase 43: quantas vezes a mesma situação se repetiu com o aviso na tela (o bloco mostra "×N").
var _counts: Dictionary[String, int] = {}
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
	EventBus.expedition_returned.connect(func(expedition_id: StringName, outcome: int, exhibit_id: StringName) -> void:
		push(watcher.expedition_returned(expedition_id, outcome, exhibit_id)))
	EventBus.newspaper_published.connect(func(headline_id: StringName) -> void:
		if headline_id != &"":
			push(watcher.newspaper_published(headline_id)))
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
	EventBus.ship_built.connect(func(ship_id: int) -> void: push(watcher.ship_built(ship_id)))
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


## A categoria do aviso pelo começo da chave ("fire/12" → "alert").
static func category_of(key: String) -> String:
	var found: String = PREFIXES.get(key.get_slice("/", 0), "progress")
	return found


## Repetições do aviso na tela (testes).
func count_of(key: String) -> int:
	return _counts.get(key, 0)


## Mostra a notificação; a mesma situação com o aviso ainda na tela vira um bloco com contador (Fase 43), renovado e
## levado para cima. Categoria silenciada nas opções não aparece.
func push(notice: NoticeWatcher.Notice) -> void:
	var category := category_of(notice.key)
	if Settings.is_notice_muted(category):
		return
	if category == "alert" and notice.status == UiPalette.Status.BAD and Settings.pause_on_alert:
		GameClock.set_speed(TickClock.PAUSED)
	if _items.has(notice.key):
		_counts[notice.key] += 1
		var again := _items[notice.key]
		again.text = "%s  ×%d" % [notice.text(), _counts[notice.key]]
		move_child(again, 0)
		_ages[notice.key] = Settings.notice_seconds()
		_notices[notice.key] = notice
		return
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
	# Fase 30: aparece em FADE_S (com as animações desligadas, já inteira)
	if not SceneFader.still():
		button.modulate.a = 0.0
		create_tween().tween_property(button, ^"modulate:a", 1.0, FADE_S)
	EventBus.notice_shown.emit(notice.icon)
	_items[notice.key] = button
	_ages[notice.key] = Settings.notice_seconds()
	_notices[notice.key] = notice
	_counts[notice.key] = 1
	while _items.size() > _config.notice_max_visible:
		# o mais antigo que ainda conta: os que estão esmaecendo (Fase 30) já saíram de _items
		for index: int in range(get_child_count() - 1, -1, -1):
			var oldest := get_child(index)
			var found := ""
			for key: String in _items:
				if _items[key] == oldest:
					found = key
					break
			if not found.is_empty():
				_remove(found)
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
	_items.erase(key)
	_ages.erase(key)
	_notices.erase(key)
	_counts.erase(key)
	if SceneFader.still():
		remove_child(button)
		button.queue_free()
		return
	# Fase 30: sai das contas na hora (shown() e o limite não a veem mais) e só o desenho esmaece antes de sumir
	button.disabled = true
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade := create_tween()
	fade.tween_property(button, ^"modulate:a", 0.0, FADE_S)
	fade.tween_callback(button.queue_free)
