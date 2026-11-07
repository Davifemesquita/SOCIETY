class_name NoticeWatcher
extends RefCounted
## O que vira notificação (seção 10): falta de bem, prédio parado, estoque cheio, navio chegou,
## marco atingido, colônia fundada, visita do comerciante e, desde a Fase 11, eventos e encomendas. Os eventos da simulação chegam pelo
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
	## O clique abre a janela das encomendas em vez de levar a câmera (Fase 11).
	var opens_missions: bool = false
	## O clique abre a janela das rivais (Fase 11).
	var opens_rivals: bool = false

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


func event_started(def_id: StringName, island_id: int) -> Notice:
	var event_def := _simulation.data.event(def_id)
	var place: String = Fmt.place(island_id) if island_id >= 0 else String(TranslationServer.translate("PLACE_ARCHIPELAGO"))
	var notice := Notice.new("event/%s" % def_id, MissionWindow.event_icon(def_id), "NOTICE_EVENT",
			[TranslationServer.translate(event_def.title_key()), place])
	notice.island_id = island_id
	notice.opens_missions = island_id < 0
	notice.status = UiPalette.Status.GOOD if event_def.is_good() else UiPalette.Status.PARTIAL
	return notice


## Saiu uma edição do jornal (Fase 63): a manchete, verde se sobe a felicidade e laranja se tira; o clique abre a janela.
func newspaper_published(headline_id: StringName) -> Notice:
	var def := _simulation.data.headline(headline_id)
	var title: String = String(TranslationServer.translate(def.title_key())) if def != null else ""
	var notice := Notice.new("newspaper/edition", "notice_mission", "NOTICE_NEWSPAPER", [title])
	notice.opens_missions = true
	if def != null and def.happiness > 0.0:
		notice.status = UiPalette.Status.GOOD
	elif def != null and def.happiness < 0.0:
		notice.status = UiPalette.Status.PARTIAL
	return notice


## Expedição de volta (Fase 69): com a peça ou as moedas (verde), de mãos vazias (neutro) ou o navio perdido (vermelho).
func expedition_returned(expedition_id: StringName, outcome: int, exhibit_id: StringName) -> Notice:
	var def := _simulation.data.expedition(expedition_id)
	var place: String = String(TranslationServer.translate(def.title_key())) if def != null else ""
	var notice: Notice
	match outcome:
		ExpeditionSystem.Outcome.LOST:
			notice = Notice.new("expedition/%s" % expedition_id, "notice_ship_arrived", "NOTICE_EXPEDITION_LOST", [place])
			notice.status = UiPalette.Status.BAD
		ExpeditionSystem.Outcome.EMPTY:
			notice = Notice.new("expedition/%s" % expedition_id, "notice_ship_arrived", "NOTICE_EXPEDITION_EMPTY", [place])
		_:
			var exhibit := _simulation.data.exhibit(exhibit_id)
			if exhibit != null:
				notice = Notice.new("expedition/%s" % expedition_id, "notice_ship_arrived", "NOTICE_EXPEDITION_EXHIBIT",
						[place, TranslationServer.translate(exhibit.title_key())])
			else:
				notice = Notice.new("expedition/%s" % expedition_id, "notice_ship_arrived", "NOTICE_EXPEDITION_RICH", [place])
			notice.status = UiPalette.Status.GOOD
	notice.opens_missions = true
	return notice


func mission_offered(mission_id: int) -> Notice:
	var item := _simulation.world.events_state.mission(mission_id)
	var good: String = String(TranslationServer.translate(_simulation.data.good(item.def.good).name_key)) if item != null else ""
	var tons: int = item.def.tons if item != null else 0
	var notice := Notice.new("mission/offer", "notice_mission", "NOTICE_MISSION_OFFERED", [Fmt.integer(tons), good])
	notice.opens_missions = true
	return notice


func mission_completed(def_id: StringName, bonus: int) -> Notice:
	var def := _simulation.data.mission(def_id)
	var notice := Notice.new("mission/done/%s" % def_id, "notice_mission", "NOTICE_MISSION_DONE",
			[TranslationServer.translate(_simulation.data.good(def.good).name_key), Fmt.integer(bonus)])
	notice.opens_missions = true
	notice.status = UiPalette.Status.GOOD
	return notice


func rival_colonized(rival_id: StringName, island_id: int) -> Notice:
	var rival := _simulation.data.rival(rival_id)
	var notice := Notice.new("rival/colony/%d" % island_id, "notice_rival", "NOTICE_RIVAL_COLONY",
			[TranslationServer.translate(rival.name_key), Fmt.place(island_id)])
	notice.island_id = island_id
	notice.status = UiPalette.Status.PARTIAL
	return notice


func rival_stance(rival_id: StringName, stance: int) -> Notice:
	var rival := _simulation.data.rival(rival_id)
	var keys: Array[String] = ["NOTICE_RIVAL_NEUTRAL", "NOTICE_RIVAL_TRADE", "NOTICE_RIVAL_WAR"]
	var notice := Notice.new("rival/stance/%s" % rival_id, "notice_rival", keys[stance], [TranslationServer.translate(rival.name_key)])
	notice.opens_rivals = true
	notice.status = [UiPalette.Status.NEUTRAL, UiPalette.Status.GOOD, UiPalette.Status.BAD][stance]
	return notice


## Navio afundado: o nosso (vermelho) ou o da rival (verde).
func ship_sunk(owner: int) -> Notice:
	var ours := owner == Ship.Owner.PLAYER
	var notice := Notice.new("sunk/%d/%d" % [owner, Time.get_ticks_msec()], "notice_sunk",
			"NOTICE_SHIP_SUNK" if ours else "NOTICE_ENEMY_SUNK")
	notice.status = UiPalette.Status.BAD if ours else UiPalette.Status.GOOD
	return notice


## Navio nosso sob fogo (uma vez por navio enquanto a notificação está na tela).
func under_attack(ship_id: int) -> Notice:
	var ship := _simulation.world.ship(ship_id)
	var def := _simulation.data.ship(ship.def_id)
	var notice := Notice.new("attack/%d" % ship_id, "notice_battle", "NOTICE_UNDER_ATTACK",
			[TranslationServer.translate("SHIP_TITLE") % [TranslationServer.translate(def.name_key), ship.id]])
	notice.ship_id = ship_id
	notice.status = UiPalette.Status.BAD
	return notice


## Só a aceita que venceu vira aviso; a oferta não respondida some calada.
func mission_expired(def_id: StringName) -> Notice:
	var def := _simulation.data.mission(def_id)
	var notice := Notice.new("mission/expired/%s" % def_id, "notice_mission", "NOTICE_MISSION_EXPIRED",
			[TranslationServer.translate(_simulation.data.good(def.good).name_key)])
	notice.opens_missions = true
	notice.status = UiPalette.Status.PARTIAL
	return notice


## Fogo num prédio (riscos): sem bombeiros, diz em quanto tempo ele se perde.
func fire_started(building_id: int) -> Notice:
	var record := _simulation.world.building(building_id)
	var name: String = TranslationServer.translate(_simulation.def_of(record).name_key) if record != null else ""
	var protected := _simulation.derived_state().fire_protected.has(building_id)
	var notice := Notice.new("fire/%d" % building_id, "notice_fire", "NOTICE_FIRE" if protected else "NOTICE_FIRE_UNPROTECTED",
			[name] if protected else [name, Fmt.integer(_simulation.config.fire_burnout_s)])
	notice.building_id = building_id
	notice.status = UiPalette.Status.PARTIAL if protected else UiPalette.Status.BAD
	return notice


func fire_out(building_id: int) -> Notice:
	var record := _simulation.world.building(building_id)
	var name: String = TranslationServer.translate(_simulation.def_of(record).name_key) if record != null else ""
	var notice := Notice.new("fire/%d" % building_id, "notice_fire", "NOTICE_FIRE_OUT", [name])
	notice.building_id = building_id
	notice.status = UiPalette.Status.GOOD
	return notice


## O prédio já saiu do mundo: o clique leva à ilha.
func building_lost(building_id: int, def_id: StringName, island_id: int) -> Notice:
	var notice := Notice.new("fire/%d" % building_id, "notice_fire", "NOTICE_BUILDING_LOST",
			[TranslationServer.translate(_simulation.data.building(def_id).name_key)])
	notice.island_id = island_id
	notice.status = UiPalette.Status.BAD
	return notice


func outbreak(house_id: int) -> Notice:
	var record := _simulation.world.building(house_id)
	var tier := _simulation.data.tier(record.tier) if record != null else null
	var notice := Notice.new("disease/%d" % house_id, "notice_disease", "NOTICE_OUTBREAK",
			[TranslationServer.translate(tier.name_key) if tier != null else ""])
	notice.building_id = house_id
	notice.status = UiPalette.Status.PARTIAL
	return notice


func ship_built(ship_id: int) -> Notice:
	var ship := _simulation.world.ship(ship_id)
	var name: String = TranslationServer.translate(_simulation.data.ship(ship.def_id).name_key) if ship != null else ""
	var notice := Notice.new("ship_built/%d" % ship_id, "notice_ship_built", "NOTICE_SHIP_BUILT", [name])
	notice.ship_id = ship_id
	notice.status = UiPalette.Status.GOOD
	return notice


func achievement(def: AchievementDef) -> Notice:
	var notice := Notice.new("achievement/%s" % def.id, "notice_achievement", "NOTICE_ACHIEVEMENT",
			[TranslationServer.translate(def.title_key())])
	notice.status = UiPalette.Status.GOOD
	return notice


func simulation_world() -> WorldState:
	return _simulation.world


## O entreposto da ilha (o de menor id), ou 0.
func trading_post_of(island_id: int) -> int:
	for building_id: int in _simulation.world.building_ids():
		var record := _simulation.world.building(building_id)
		if record.island_id == island_id and _simulation.def_of(record).is_trading_post:
			return building_id
	return 0
