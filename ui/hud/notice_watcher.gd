class_name NoticeWatcher
extends RefCounted
## O que vira notificação (seção 10): falta de bem, prédio parado, estoque cheio, navio chegou,
## marco atingido, colônia fundada e visita do comerciante. Os eventos da simulação chegam pelo
## EventBus (falta, marco, colônia, comerciante); prédio parado, estoque cheio e chegada de navio
## saem da comparação do estado de agora com o da última conferência. Sem nós: testável.


## Uma notificação: ícone, texto (chave + argumentos) e onde ela leva ao ser clicada.
class Notice:
	## Igual para a mesma situação: notificação repetida só renova a que já está na tela.
	var key: String
	var icon: String
	var text_key: String
	var args: Array = []
	## Lugar do clique: prédio, navio ou ilha (0 = nenhum; ilha -1 = nenhuma).
	var building_id: int = 0
	var ship_id: int = 0
	var island_id: int = -1
	## UiPalette.Status da notificação (cor do texto).
	var status: int = UiPalette.Status.NEUTRAL

	func _init(notice_key: String, icon_name: String, key_text: String, text_args: Array = []) -> void:
		key = notice_key
		icon = icon_name
		text_key = key_text
		args = text_args

	func text() -> String:
		var translated := TranslationServer.translate(text_key)
		return translated % args if not args.is_empty() else translated


var _simulation: Simulation
## Prédio → tick em que começou a ficar parado.
var _stopped_since: Dictionary[int, int] = {}
var _stopped_announced: Dictionary[int, bool] = {}
var _full_announced: Dictionary[String, bool] = {}
var _ship_states: Dictionary[int, int] = {}


func _init(simulation: Simulation) -> void:
	_simulation = simulation
	reset()


## Esquece o que já foi avisado (mundo trocado). O estado de agora vira a referência: o que já
## estava parado, cheio ou atracado ao carregar não vira notificação de repente.
func reset() -> void:
	_stopped_since.clear()
	_stopped_announced.clear()
	_full_announced.clear()
	_ship_states.clear()
	for ship: Ship in _simulation.world.player_ships():
		_ship_states[ship.id] = ship.state
	check()


## Confere o estado e devolve as notificações novas.
func check() -> Array[Notice]:
	var notices: Array[Notice] = []
	_check_stopped(notices)
	_check_storage(notices)
	_check_ships(notices)
	return notices


func _check_stopped(notices: Array[Notice]) -> void:
	var world := _simulation.world
	var config := _simulation.config
	var wait_ticks := roundi(config.stopped_notice_after_s * config.ticks_per_second)
	var seen: Dictionary[int, bool] = {}
	for building_id: int in _simulation.derived_state().production:
		var record := world.building(building_id)
		var state := SelectionPanel.shown_state(record)
		if record.paused or state in [BuildingRecord.State.PRODUCING, BuildingRecord.State.IDLE]:
			continue
		seen[building_id] = true
		if not _stopped_since.has(building_id):
			_stopped_since[building_id] = world.tick
		if world.tick - _stopped_since[building_id] >= wait_ticks and not _stopped_announced.has(building_id):
			_stopped_announced[building_id] = true
			var notice := Notice.new("stopped/%d" % building_id, "notice_stopped", "NOTICE_STOPPED",
					[TranslationServer.translate(_simulation.def_of(record).name_key), TranslationServer.translate(SelectionPanel.state_key(state))])
			notice.building_id = building_id
			notice.island_id = record.island_id
			notice.status = UiPalette.Status.BAD
			notices.append(notice)
	for building_id: int in _stopped_since.keys():
		if not seen.has(building_id):
			_stopped_since.erase(building_id)
			_stopped_announced.erase(building_id)


func _check_storage(notices: Array[Notice]) -> void:
	var world := _simulation.world
	var config := _simulation.config
	for island_id: int in world.colonized_islands(_simulation.data):
		var capacity := _simulation.storage_capacity(island_id)
		var economy := world.economy(island_id)
		for good: GoodDef in _simulation.data.goods:
			var key := "full/%d/%s" % [island_id, good.id]
			var amount := economy.amount(good.id)
			if amount >= capacity * config.storage_full_fraction:
				if not _full_announced.has(key):
					_full_announced[key] = true
					var notice := Notice.new(key, "notice_storage_full", "NOTICE_STORAGE_FULL",
							[TranslationServer.translate(good.name_key), Fmt.place(island_id)])
					notice.island_id = island_id
					notice.building_id = trading_post_of(island_id)
					notice.status = UiPalette.Status.PARTIAL
					notices.append(notice)
			elif amount < capacity * config.storage_full_reset_fraction:
				_full_announced.erase(key)


## Navio do jogador que acabou de chegar: deixou de navegar e está num lugar.
func _check_ships(notices: Array[Notice]) -> void:
	var current: Dictionary[int, int] = {}
	for ship: Ship in _simulation.world.player_ships():
		current[ship.id] = ship.state
		var before: int = _ship_states.get(ship.id, ship.state)
		if before == Ship.State.SAILING and ship.state != Ship.State.SAILING and ship.at != Ship.NOWHERE:
			var def := _simulation.data.ship(ship.def_id)
			var notice := Notice.new("ship/%d" % ship.id, "notice_ship_arrived", "NOTICE_SHIP_ARRIVED",
					[TranslationServer.translate("SHIP_TITLE") % [TranslationServer.translate(def.name_key), ship.id], Fmt.place(ship.at)])
			notice.ship_id = ship.id
			notice.status = UiPalette.Status.GOOD
			notices.append(notice)
	_ship_states = current


## Notificação de um evento da simulação.
func shortage(island_id: int, good: StringName) -> Notice:
	var notice := Notice.new("shortage/%d/%s" % [island_id, good], "notice_shortage", "NOTICE_SHORTAGE",
			[TranslationServer.translate(_simulation.data.good(good).name_key), Fmt.place(island_id)])
	notice.island_id = island_id
	notice.building_id = trading_post_of(island_id)
	notice.status = UiPalette.Status.BAD
	return notice


func milestone(count: int) -> Notice:
	var notice := Notice.new("milestone/%d" % count, "notice_milestone", "NOTICE_MILESTONE",
			[Fmt.integer(_simulation.config.population_milestones[count - 1])])
	notice.island_id = Simulation.MAIN_ISLAND
	notice.status = UiPalette.Status.GOOD
	return notice


func colonized(island_id: int) -> Notice:
	var notice := Notice.new("colony/%d" % island_id, "notice_colonized", "NOTICE_COLONIZED", [Fmt.place(island_id)])
	notice.island_id = island_id
	notice.building_id = trading_post_of(island_id)
	notice.status = UiPalette.Status.GOOD
	return notice


func trader(island_id: int, earned: float, spent: float) -> Notice:
	var notice := Notice.new("trader/%d" % island_id, "notice_trader", "NOTICE_TRADER",
			[Fmt.place(island_id), Fmt.integer(earned), Fmt.integer(spent)])
	notice.island_id = island_id
	notice.building_id = trading_post_of(island_id)
	return notice


## O entreposto da ilha (o de menor id), ou 0.
func trading_post_of(island_id: int) -> int:
	for building_id: int in _simulation.world.building_ids():
		var record := _simulation.world.building(building_id)
		if record.island_id == island_id and _simulation.def_of(record).is_trading_post:
			return building_id
	return 0
