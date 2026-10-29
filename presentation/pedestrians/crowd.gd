class_name Crowd
extends RefCounted
## Multidão (seção 9). Pedestres são só visuais: um para cada residents_per_pedestrian moradores,
## até max_visible_pedestrians; rotina casa → trabalho → mercado, taverna ou igreja → casa; menos
## gente na rua à noite (pedestrian_activity_by_hour). Não mudam nada na simulação e não vão para
## o save: são refeitos ao carregar.
## Toda a conta mora aqui, sem nós (testável): cada grupo (classe × corpo) é um MultiMesh na
## PedestrianView, que só aplica a lista de mudanças. O pedestre anda na placa de vídeo, trecho
## reto por trecho reto (shaders/pedestrian_vat.gdshader); a CPU só mexe nele quando ele troca de
## trecho, chega ou sai.
## Fase 80: turistas. Com os eventos ligados, cada ilha com atratividade (DerivedState.attractiveness) ganha
## tourists_per_point turistas por ponto (até max_tourists_per_island): saem do entreposto, visitam uma das atrações da
## ilha (os prédios com beleza: zoológico, museu, praças, estátuas), ficam olhando na porta e voltam. Roupa clara
## (TOURIST_COLORS) e a calça da classe mais rica. Desde a Fase 81, na festa vêm mais (1 + tourism_festival_bonus); desde a
## Fase 82, na hora dos fogos eles vão ver a festa em volta dos mastros das praças; desde a Fase 83, os moradores também
## (RESIDENT_WATCH_SHARE de quem sai nessa hora).
const BUCKET_SECONDS := 0.25
const REBALANCE_SECONDS := 2.0
## Quem não achou caminho tenta de novo depois disto.
const RETRY_SECONDS := 15.0
## Partidas tentadas por quadro (cada uma pode pedir rota); na partida em massa (ao carregar, ao
## amanhecer), mais, mas ainda com teto: a fila não é percorrida inteira num quadro.
const STARTS_PER_FRAME := 40
const WARM_STARTS_PER_FRAME := 400
## Com mais que esta fração faltando na rua (ao carregar, ao amanhecer), o pedestre já aparece no
## meio do caminho em vez de todos saírem de casa no mesmo quadro.
const WARM_START_SHARE := 0.25
## Animações, na ordem gravada pelo tools/bake_pedestrians.gd.
const CLIP_WALK := 0
const CLIP_WALK_CARRY := 1
const CLIP_IDLE := 2
const CLIP_TALK := 3
## Fase 84: olhando para o céu e batendo palmas (gerada no código, tools/vat/cheer_clip.gd). Desde a Fase 85 é a reação
## a cada estouro (react_to_burst): quem vê a festa até REACT_RADIUS_M dele, na parte REACT_SHARE, demora REACT_DELAY_S,
## bate palmas por CHEER_SECONDS e volta a olhar o mastro.
const CLIP_CHEER := 4
const REACT_SHARE := 0.85
const REACT_RADIUS_M := 30.0
const REACT_DELAY_S := Vector2(0.15, 0.6)
const CHEER_SECONDS := Vector2(1.6, 2.6)
## O que vai na mão de quem anda com a animação de carregar (Fase 15): cesto saindo do mercado, saco saindo
## de fazenda.
enum Load { NONE, BASKET, SACK }
const BODIES := 2
## Fase 80: as roupas dos turistas (linho, branco, azul-claro, palha, rosa) e entre quantas atrações (as de mais beleza)
## cada um escolhe.
const TOURIST_COLORS: Array[Color] = [Color(0.93, 0.9, 0.8), Color(0.95, 0.95, 0.93), Color(0.62, 0.76, 0.9),
		Color(0.86, 0.76, 0.5), Color(0.9, 0.72, 0.72)]
const TOURIST_CHOICES := 4
## Fase 82: na festa, na hora dos fogos (FestivalView.NIGHT_FIREWORKS), o turista vai a uma das praças da festa e fica na
## rua em volta do mastro, ao longo das cordas de bandeirolas: de WATCH_NEAR_M até WATCH_FAR_M do mastro, até
## WATCH_SIDE_SHARE da célula para o lado, de frente para o mastro.
const WATCH_NEAR_M := 1.2
const WATCH_FAR_M := 7.0
const WATCH_SIDE_SHARE := 0.35
## Fase 83: a parte dos moradores que, saindo na hora dos fogos, vai direto de casa a uma praça da festa (os outros seguem
## a rotina; o serviço de quem sai do trabalho também vira a festa nessa parte).
const RESIDENT_WATCH_SHARE := 0.6
## Fase 83: na hora dos fogos, a ilha da festa põe na rua pelo menos esta parte dos pedestres dela (à noite são só ~18%, e
## a festa ficava vazia).
const FESTIVAL_NIGHT_ACTIVITY := 0.5

## HOME e INSIDE ficam escondidos; INSIDE é a pausa na porta do trabalho ou de casa no meio da
## rotina (conta como gente na rua).
enum State { HOME, INSIDE, WALKING, WAITING }
enum Leg { TO_WORK, TO_SERVICE, TO_HOME }


class Agent:
	var index: int
	var home_id: int
	var tier: StringName
	var body: int
	var group: int
	var slot: int
	var color: Color
	var state: State = State.HOME
	var leg: Leg = Leg.TO_HOME
	var target_id: int = 0
	var points := PackedVector3Array()
	var cells := PackedInt32Array()
	var island_id: int = 0
	var segment: int = 0
	var segment_start: float = 0.0
	var walked: float = 0.0
	var clip: int = CLIP_WALK
	var load: Load = Load.NONE
	var phase: float = 0.0
	var spot := Vector3.ZERO
	var facing := Vector3.FORWARD
	## Hora (tempo visual) do próximo evento; em casa, a partir de quando pode sair.
	var event_at: float = 0.0
	var serial: int = 0
	## Sai da multidão quando chegar a algum lugar (casa sumiu de classe ou sobrou gente).
	var retiring: bool = false
	var removed: bool = false
	## Já está na lista de mudanças.
	var queued: bool = false
	## Fase 80: turista (a "casa" é o entreposto da ilha).
	var tourist: bool = false
	## Fase 82: andando da porta da praça até o lugar de ver a festa (agent.spot).
	var to_spot: bool = false
	## Fase 83: parado (ou indo) num lugar de ver a festa, longe da porta: ao sair, anda primeiro até ela.
	var watching: bool = false
	## Fase 85: batendo palmas por um estouro até este tempo visual (0 = não).
	var cheer_until: float = 0.0


class Group:
	var tier: StringName
	var body: int
	var capacity: int = 0
	var free_slots := PackedInt32Array()
	## A capacidade cresceu: a vista refaz o MultiMesh inteiro do grupo.
	var resized: bool = false


## Tempo visual em segundos: anda com a velocidade do jogo e para na pausa.
var time: float = 0.0
## Fração na rua forçada (benchmark); negativa segue a hora.
var activity_override: float = -1.0
var agents: Array[Agent] = []
var groups: Array[Group] = []
## Pedestres cuja instância mudou desde a última leitura (take_changes).
var changed: Array[Agent] = []
## Instâncias que ficaram vazias: (grupo, posição).
var cleared: Array[Vector2i] = []

var _simulation: Simulation
var _config: GameConfig
var _cell_size: float
var _rng := RandomNumberGenerator.new()
## Passo (m por ciclo) de cada animação, por corpo.
var _strides: Array[PackedFloat32Array] = []
var _free_agents := PackedInt32Array()
var _by_house: Dictionary[int, PackedInt32Array] = {}
## Fase 80: os turistas de cada ilha e as atrações que cada entreposto alcança (em cache).
var _tourists: Dictionary[int, PackedInt32Array] = {}
var _attractions_of: Dictionary[int, PackedInt32Array] = {}
## Fase 82: as praças da festa que cada entreposto alcança (em cache).
var _squares_of: Dictionary[int, PackedInt32Array] = {}
## Fase 83: pedestres (moradores e turistas) das ilhas na hora dos fogos, contados a cada _rebalance.
var _festival_agents: int = 0
## Fase 84: as ilhas na hora dos fogos e os pedestres das outras na rua (contados a cada _rebalance e somados a cada
## partida até o próximo).
var _festive: Dictionary[int, bool] = {}
var _quiet_out: int = 0
## Fase 85: quem está batendo palmas por um estouro (índices).
var _cheering := PackedInt32Array()
var _buckets: Dictionary[int, PackedInt32Array] = {}
var _next_bucket: int = 0
var _home_queue: Array[int] = []
var _out: int = 0
var _visible: int = 0
var _rebalance_left: float = 0.0
var _structure_dirty: bool = true
var _road_count: Dictionary[int, int] = {}
var _routers: Dictionary[int, RoadRouter] = {}
var _labels: Dictionary[int, PackedInt32Array] = {}
var _legs: Dictionary[Vector2i, Array] = {}
var _work_choices: Dictionary[int, PackedInt32Array] = {}
var _services_of: Dictionary[int, PackedInt32Array] = {}
var _group_of: Dictionary[StringName, int] = {}
var _route_usec: int = 0
var _building_labels: Dictionary[int, int] = {}
## Rotas calculadas (A*) e o tempo total delas, para o benchmark.
var routes_computed: int = 0
## Fração do teto de pedestres em uso (o nível gráfico escolhe).
var pedestrian_ratio: float = 1.0
var routes_usec: int = 0
## Hora recebida no último update.
var _hour: float = 12.0


func _init(simulation: Simulation, config: GameConfig, strides: Array[PackedFloat32Array], seed_value: int = 1) -> void:
	_simulation = simulation
	_config = config
	_cell_size = config.cell_size_m
	_strides = strides
	_rng.seed = seed_value
	for tier: TierDef in simulation.data.tiers:
		for body: int in BODIES:
			var group := Group.new()
			group.tier = tier.id
			group.body = body
			_group_of[_group_key(tier.id, body)] = groups.size()
			groups.append(group)


## Prédios ou estradas mudaram: refaz rotas, escolhas e confere quem está na rua.
func mark_structure_changed() -> void:
	_structure_dirty = true


## Mundo trocado (carregar): começa do zero.
func reset() -> void:
	agents.clear()
	_free_agents.clear()
	_by_house.clear()
	_tourists.clear()
	_festival_agents = 0
	_festive.clear()
	_quiet_out = 0
	_cheering.clear()
	_buckets.clear()
	_home_queue.clear()
	_out = 0
	_visible = 0
	changed.clear()
	cleared.clear()
	for group: Group in groups:
		group.free_slots.clear()
		for slot: int in group.capacity:
			group.free_slots.append(group.capacity - 1 - slot)
		group.resized = true
	_road_count.clear()
	_structure_dirty = true
	_rebalance_left = 0.0


func agent_count() -> int:
	return agents.size() - _free_agents.size()


## Pedestres à vista (andando ou parados na rua).
func visible_count() -> int:
	return _visible


## Pedestres fora de casa (andando, parados ou na pausa de uma porta).
func out_count() -> int:
	return _out


## Quantos a multidão quer na rua agora.
func desired_out(hour: float) -> int:
	var activity := activity_override if activity_override >= 0.0 else DayClock.activity(_config, hour)
	# a festa com fogos (Fase 83) enche a rua da ilha dela
	return roundi(agent_count() * activity + _festival_agents * maxf(FESTIVAL_NIGHT_ACTIVITY - activity, 0.0))


## Avança dt segundos visuais. Pausado (dt = 0), nada muda: ninguém sai congelado na porta.
func update(dt: float, hour: float) -> void:
	_hour = hour
	if dt <= 0.0:
		return
	time += dt
	_route_usec = 0
	if _structure_dirty:
		_refresh_structure()
	_rebalance_left -= dt
	if _rebalance_left <= 0.0:
		_rebalance_left = REBALANCE_SECONDS
		_rebalance()
	_process_events()
	if not _cheering.is_empty():
		_end_cheers()
	var wanted := desired_out(hour)
	if _out < wanted:
		_start_trips(wanted - _out, wanted)


# --- pool de pedestres por casa ---

## Ajusta a quantidade de pedestres de cada casa à população dela, com o teto global.
func _rebalance() -> void:
	var world := _simulation.world
	var derived := _simulation.derived_state()
	var total := 0.0
	for house_id: int in derived.houses:
		total += world.building(house_id).residents
	var wanted_total := total / maxf(_config.residents_per_pedestrian, 0.001)
	var cap := _config.max_visible_pedestrians * pedestrian_ratio
	var scale := 1.0 if wanted_total <= cap else cap / wanted_total
	var accumulated := 0.0
	var seen: Dictionary[int, bool] = {}
	for house_id: int in derived.houses:
		var house := world.building(house_id)
		var before := floori(accumulated)
		accumulated += house.residents / maxf(_config.residents_per_pedestrian, 0.001) * scale
		var count := floori(accumulated + 0.000001) - before
		seen[house_id] = true
		var current: PackedInt32Array = _by_house.get(house_id, PackedInt32Array())
		var kept := PackedInt32Array()
		for index: int in current:
			var agent := agents[index]
			if agent.tier != house.tier or kept.size() >= count:
				_retire(agent)
			else:
				kept.append(index)
		while kept.size() < count:
			kept.append(_add_agent(house).index)
		_by_house[house_id] = kept
	for house_id: int in _by_house.keys():
		if not seen.has(house_id):
			for index: int in _by_house[house_id]:
				_remove_agent(agents[index])
			_by_house.erase(house_id)
	_rebalance_tourists()
	_count_festival_agents()


## Fase 83: quantos pedestres (de casa e turistas) estão nas ilhas na hora dos fogos. Desde a Fase 84, também quais
## ilhas são essas e quantos das outras estão na rua: a cota extra é só para a gente da festa.
func _count_festival_agents() -> void:
	_festival_agents = 0
	_festive.clear()
	for house_id: int in _by_house:
		var house := _simulation.world.building(house_id)
		if house == null:
			continue
		if not _festive.has(house.island_id):
			_festive[house.island_id] = fireworks_now(house.island_id)
		if _festive[house.island_id]:
			_festival_agents += _by_house[house_id].size()
	for island_id: int in _tourists:
		if not _festive.has(island_id):
			_festive[island_id] = fireworks_now(island_id)
		if _festive[island_id]:
			_festival_agents += _tourists[island_id].size()
	_quiet_out = 0
	if _festival_agents > 0:
		for agent: Agent in agents:
			if agent != null and not agent.removed and agent.state != State.HOME and not _festive.get(agent.island_id, false):
				_quiet_out += 1


## Fase 84: o pedestre de fora da festa já não cabe na rua: a parte da multidão dele (sem a cota extra) está cheia.
func _quiet_full(agent: Agent) -> bool:
	if _festival_agents == 0 or _festive.get(agent.island_id, false):
		return false
	var activity := activity_override if activity_override >= 0.0 else DayClock.activity(_config, _hour)
	return _quiet_out >= roundi((agent_count() - _festival_agents) * activity)


## Fase 80: ajusta os turistas de cada ilha à atratividade dela (só com os eventos ligados, como o turismo).
func _rebalance_tourists() -> void:
	var world := _simulation.world
	var derived := _simulation.derived_state()
	var seen: Dictionary[int, bool] = {}
	if world.events_state.enabled:
		for island_id: int in derived.attractiveness:
			var post := _trading_post(island_id)
			if post == null:
				continue
			seen[island_id] = true
			var points: float = derived.attractiveness[island_id]
			# Fase 81: na festa, mais turistas, na mesma proporção da renda (e o teto também sobe)
			var crowd_factor := 1.0 + _config.tourism_festival_bonus if TourismSystem.has_festival(world, island_id) else 1.0
			var count := mini(roundi(_config.max_tourists_per_island * crowd_factor),
					floori(points * _config.tourists_per_point * pedestrian_ratio * crowd_factor))
			var kept := PackedInt32Array()
			for index: int in _tourists.get(island_id, PackedInt32Array()):
				var agent := agents[index] if index < agents.size() else null
				if agent == null or not agent.tourist or agent.island_id != island_id:
					continue
				if kept.size() >= count or agent.home_id != post.id:
					_retire(agent)
				else:
					kept.append(index)
			while kept.size() < count:
				kept.append(_add_agent(post, _simulation.data.tiers[_simulation.data.tiers.size() - 1].id, true).index)
			_tourists[island_id] = kept
	for island_id: int in _tourists.keys():
		if seen.has(island_id):
			continue
		for index: int in _tourists[island_id]:
			var agent := agents[index] if index < agents.size() else null
			if agent != null and agent.tourist and agent.island_id == island_id:
				_retire(agent)
		_tourists.erase(island_id)


func _trading_post(island_id: int) -> BuildingRecord:
	for record: BuildingRecord in _simulation.world.buildings.values():
		if record.island_id == island_id and _simulation.def_of(record).is_trading_post:
			return record
	return null


## Turistas na multidão agora (testes).
func tourist_count() -> int:
	var total := 0
	for agent: Agent in agents:
		if agent != null and agent.tourist:
			total += 1
	return total


## A casa do pedestre; turista (Fase 80): a "casa" é o entreposto, com a classe dada e a roupa de turista.
func _add_agent(house: BuildingRecord, tier: StringName = &"", tourist: bool = false) -> Agent:
	var agent := Agent.new()
	if _free_agents.is_empty():
		agent.index = agents.size()
		agents.append(agent)
	else:
		agent.index = _free_agents[_free_agents.size() - 1]
		_free_agents.resize(_free_agents.size() - 1)
		agents[agent.index] = agent
	agent.home_id = house.id
	agent.island_id = house.island_id
	agent.tier = tier if tourist else house.tier
	agent.tourist = tourist
	agent.body = _rng.randi_range(0, BODIES - 1)
	agent.group = _group_of[_group_key(agent.tier, agent.body)]
	agent.slot = _take_slot(groups[agent.group])
	var palette: Array = TOURIST_COLORS if tourist else Array(_simulation.data.tier(agent.tier).clothing_colors)
	var coat: Color = palette[_rng.randi_range(0, palette.size() - 1)] if not palette.is_empty() else Color.GRAY
	agent.color = Color(coat.r, coat.g, coat.b, _rng.randf())
	agent.event_at = time
	_home_queue.append(agent.index)
	_write(agent)
	return agent


## Tira o pedestre agora se ele está escondido; senão, quando ele chegar.
func _retire(agent: Agent) -> void:
	if agent.state == State.HOME or agent.state == State.INSIDE:
		_remove_agent(agent)
	else:
		agent.retiring = true


func _remove_agent(agent: Agent) -> void:
	if agents[agent.index] != agent:
		return
	_set_state(agent, State.HOME)
	var group := groups[agent.group]
	cleared.append(Vector2i(agent.group, agent.slot))
	group.free_slots.append(agent.slot)
	agent.serial += 1
	agent.removed = true
	agents[agent.index] = null
	_free_agents.append(agent.index)
	var current: PackedInt32Array = _by_house.get(agent.home_id, PackedInt32Array())
	var position := current.find(agent.index)
	if position >= 0:
		current.remove_at(position)
		_by_house[agent.home_id] = current


func _take_slot(group: Group) -> int:
	if group.free_slots.is_empty():
		var old := group.capacity
		group.capacity = maxi(16, old * 2)
		group.resized = true
		for slot: int in range(group.capacity - 1, old - 1, -1):
			group.free_slots.append(slot)
	var slot := group.free_slots[group.free_slots.size() - 1]
	group.free_slots.resize(group.free_slots.size() - 1)
	return slot


# --- rotina ---

func _start_trips(missing: int, wanted: int) -> void:
	var warm := missing > maxi(4, roundi(wanted * WARM_START_SHARE))
	var attempts := mini(_home_queue.size(), WARM_STARTS_PER_FRAME if warm else STARTS_PER_FRAME)
	var started := 0
	while attempts > 0 and started < missing and not _home_queue.is_empty():
		attempts -= 1
		var index: int = _home_queue.pop_front()
		var agent := agents[index] if index < agents.size() else null
		if agent == null or agent.state != State.HOME:
			continue
		if agent.event_at > time or _route_usec > _config.pedestrian_route_budget_ms * 1000.0 * (4.0 if warm else 1.0) \
				or _quiet_full(agent):
			_home_queue.append(index)
			continue
		if _begin_routine(agent, warm):
			started += 1
			if _festival_agents > 0 and not _festive.get(agent.island_id, false):
				_quiet_out += 1
		else:
			agent.event_at = time + RETRY_SECONDS
			_home_queue.append(index)


## Sai de casa para o trabalho (ou, sem trabalho, direto para o serviço).
func _begin_routine(agent: Agent, warm: bool) -> bool:
	# na hora dos fogos (Fase 83), parte dos moradores vai direto ver a festa
	var square := _resident_festival(agent)
	if square != 0 and _start_leg(agent, Leg.TO_SERVICE, agent.home_id, square, warm):
		return true
	var work := _pick_work(agent)
	if work != 0 and _start_leg(agent, Leg.TO_WORK, agent.home_id, work, warm):
		return true
	var service := _pick_service(agent)
	return service != 0 and _start_leg(agent, Leg.TO_SERVICE, agent.home_id, service, warm)


func _process_events() -> void:
	var last := floori(time / BUCKET_SECONDS)
	var later: Array[Agent] = []
	while _next_bucket <= last:
		# evento marcado para o balde que está sendo lido entra de novo nele: lê até esvaziar
		while _buckets.has(_next_bucket):
			var entries: PackedInt32Array = _buckets[_next_bucket]
			_buckets.erase(_next_bucket)
			for i: int in range(0, entries.size(), 2):
				var agent := agents[entries[i]] if entries[i] < agents.size() else null
				if agent == null or agent.serial != entries[i + 1]:
					continue
				if agent.event_at > time:
					later.append(agent)
				else:
					_on_event(agent)
		_next_bucket += 1
	# ainda não venceu (cai no fim do último balde): fica para o próximo quadro
	for agent: Agent in later:
		if agent.event_at > time:
			_schedule(agent, agent.event_at)


func _schedule(agent: Agent, at: float) -> void:
	agent.serial += 1
	agent.event_at = at
	var bucket := maxi(floori(at / BUCKET_SECONDS), _next_bucket)
	if not _buckets.has(bucket):
		_buckets[bucket] = PackedInt32Array()
	var entries: PackedInt32Array = _buckets[bucket]
	entries.append(agent.index)
	entries.append(agent.serial)
	_buckets[bucket] = entries


func _on_event(agent: Agent) -> void:
	match agent.state:
		State.WALKING:
			agent.walked += _segment_length(agent)
			agent.segment += 1
			if agent.segment < agent.points.size() - 1:
				agent.segment_start = time
				_write(agent)
				_schedule(agent, time + _segment_length(agent) / _config.pedestrian_speed_m_s)
			else:
				_arrive(agent)
		State.WAITING, State.INSIDE:
			_next_leg(agent)


## Chegou ao fim da perna: entra no trabalho, fica na porta do serviço ou entra em casa.
func _arrive(agent: Agent) -> void:
	if agent.retiring:
		_remove_agent(agent)
		return
	match agent.leg:
		Leg.TO_WORK:
			_set_state(agent, State.INSIDE)
			_write(agent)
			_schedule(agent, time + _rng.randf_range(_config.pedestrian_door_seconds.x, _config.pedestrian_door_seconds.y))
		Leg.TO_SERVICE:
			if agent.to_spot:
				_stand(agent)
			else:
				_wait_at_service(agent)
		Leg.TO_HOME:
			var wanted := desired_out(_hour)
			if _out > wanted:
				_go_home(agent)
			else:
				_set_state(agent, State.INSIDE)
				_write(agent)
				_schedule(agent, time + _rng.randf_range(_config.pedestrian_door_seconds.x, _config.pedestrian_door_seconds.y))


func _next_leg(agent: Agent) -> void:
	# rota nova custa A*: passado o teto do quadro, espera um pouco mais na porta
	if _route_usec > _config.pedestrian_route_budget_ms * 1000.0:
		_schedule(agent, time + BUCKET_SECONDS)
		return
	var from := agent.target_id
	match agent.leg:
		Leg.TO_WORK:
			var service := _pick_service(agent)
			if service != 0 and _start_leg(agent, Leg.TO_SERVICE, from, service, false):
				return
			if _start_leg(agent, Leg.TO_HOME, from, agent.home_id, false):
				return
		Leg.TO_SERVICE:
			if _start_leg(agent, Leg.TO_HOME, from, agent.home_id, false):
				return
		Leg.TO_HOME:
			if _begin_routine(agent, false):
				return
	_go_home(agent)


func _go_home(agent: Agent) -> void:
	_set_state(agent, State.HOME)
	agent.leg = Leg.TO_HOME
	agent.serial += 1
	agent.event_at = time + _rng.randf_range(_config.pedestrian_door_seconds.x, _config.pedestrian_door_seconds.y)
	_write(agent)
	_home_queue.append(agent.index)


func _wait_at_service(agent: Agent) -> void:
	var service := _simulation.world.building(agent.target_id)
	if service == null:
		_next_leg(agent)
		return
	var def := _simulation.def_of(service)
	# na hora dos fogos (Fase 82), o turista fica na rua em volta do mastro da praça
	# (desde a Fase 83, também o morador)
	var watching := fireworks_now(agent.island_id) \
			and _festival_squares(agent.home_id).has(service.id) and _watch_spot(agent, service)
	agent.watching = watching
	if not watching:
		var front := Footprint.front_direction(service.rotation)
		var outward := Vector3(front.x, 0.0, front.y)
		var along := outward.cross(Vector3.UP)
		var half_width := Footprint.rotated_size(def.size, service.rotation).x * _cell_size * 0.4
		agent.spot = _door_point(service, def) + outward * _rng.randf_range(0.4, 1.4) + along * _rng.randf_range(-half_width, half_width)
		agent.spot.y = _simulation.world.island(service.island_id).height_at(agent.spot.x, agent.spot.z)
		# o turista (Fase 80) fica olhando para o prédio, quase sempre parado
		var spread := 0.5 if agent.tourist else 2.2
		agent.facing = (-outward).rotated(Vector3.UP, _rng.randf_range(-spread, spread))
	elif agent.state == State.WALKING:
		# da porta da praça até o lugar na rua, andando
		var from := agent.points[agent.points.size() - 1]
		agent.points = PackedVector3Array([from, agent.spot])
		agent.cells = PackedInt32Array()
		agent.segment = 0
		agent.segment_start = time
		agent.to_spot = true
		_write(agent)
		_schedule(agent, time + _segment_length(agent) / _config.pedestrian_speed_m_s)
		return
	_stand(agent)


## Fase 85: um estouro em at, na ilha: quem está parado vendo a festa até REACT_RADIUS_M dele (no chão), na parte
## REACT_SHARE, bate palmas olhando para o céu depois de REACT_DELAY_S. Devolve quantos (o som das palmas segue isso).
func react_to_burst(island_id: int, at: Vector3) -> int:
	var flat := Vector2(at.x, at.z)
	var count := 0
	for agent: Agent in agents:
		if agent == null or agent.removed or not agent.watching or agent.state != State.WAITING:
			continue
		if agent.island_id != island_id or Vector2(agent.spot.x, agent.spot.z).distance_to(flat) > REACT_RADIUS_M:
			continue
		if agent.cheer_until > time or _rng.randf() >= REACT_SHARE:
			continue
		# a animação começa na palma (fase 0) quando ele reage
		agent.clip = CLIP_CHEER
		agent.phase = 0.0
		agent.segment_start = time + _rng.randf_range(REACT_DELAY_S.x, REACT_DELAY_S.y)
		agent.cheer_until = agent.segment_start + _rng.randf_range(CHEER_SECONDS.x, CHEER_SECONDS.y)
		_write(agent)
		_cheering.append(agent.index)
		count += 1
	return count


## Fase 85: quem acabou de bater palmas volta a olhar o mastro; quem saiu do lugar sai da lista.
func _end_cheers() -> void:
	var kept := PackedInt32Array()
	for index: int in _cheering:
		var agent := agents[index] if index < agents.size() else null
		if agent == null or agent.removed:
			continue
		if agent.state != State.WAITING or not agent.watching or agent.clip != CLIP_CHEER:
			agent.cheer_until = 0.0
			continue
		if time < agent.cheer_until:
			kept.append(index)
			continue
		agent.cheer_until = 0.0
		agent.clip = CLIP_IDLE
		agent.phase = _rng.randf()
		agent.segment_start = time
		_write(agent)
	_cheering = kept


## Para no lugar (agent.spot, agent.facing) e fica um tempo, conversando ou parado.
func _stand(agent: Agent) -> void:
	agent.to_spot = false
	if agent.watching:
		# vendo a festa: olha o mastro e bate palmas a cada estouro (Fase 85, react_to_burst)
		agent.clip = CLIP_IDLE
	else:
		agent.clip = CLIP_TALK if _rng.randf() < (0.25 if agent.tourist else 0.6) else CLIP_IDLE
	agent.phase = _rng.randf()
	agent.segment_start = time
	_set_state(agent, State.WAITING)
	_write(agent)
	_schedule(agent, time + _rng.randf_range(_config.pedestrian_service_seconds.x, _config.pedestrian_service_seconds.y))


## Começa uma perna de from até to. Com warm, aparece num ponto qualquer dela.
func _start_leg(agent: Agent, leg: Leg, from_id: int, to_id: int, warm: bool) -> bool:
	var route := _route(from_id, to_id)
	if route.is_empty():
		return false
	var points: PackedVector3Array = route[0]
	if points.size() < 2:
		return false
	# saindo de longe da porta (Fase 82: de ver a festa na rua), anda primeiro até ela
	if agent.watching and agent.state == State.WAITING and not agent.spot.is_equal_approx(points[0]):
		points = points.duplicate()
		points.insert(0, agent.spot)
	agent.watching = false
	agent.points = points
	agent.cells = route[1]
	agent.leg = leg
	agent.to_spot = false
	agent.target_id = to_id
	agent.segment = 0
	agent.walked = 0.0
	agent.load = _load_from(from_id)
	agent.clip = CLIP_WALK_CARRY if agent.load != Load.NONE else CLIP_WALK
	agent.phase = _rng.randf()
	agent.segment_start = time
	if warm:
		var skip := _rng.randf() * SidewalkPath.length(points)
		while agent.segment < points.size() - 2 and skip > _segment_length(agent):
			skip -= _segment_length(agent)
			agent.walked += _segment_length(agent)
			agent.segment += 1
		skip = minf(skip, _segment_length(agent))
		agent.segment_start = time - skip / _config.pedestrian_speed_m_s
	_set_state(agent, State.WALKING)
	_write(agent)
	_schedule(agent, agent.segment_start + _segment_length(agent) / _config.pedestrian_speed_m_s)
	return true


## Sai do mercado com cesto e de fazenda com saco (seção 9); de outro lugar, de mãos vazias.
func _load_from(building_id: int) -> Load:
	var record := _simulation.world.building(building_id)
	if record == null:
		return Load.NONE
	var def := _simulation.def_of(record)
	if def.id == &"market":
		return Load.BASKET
	return Load.SACK if def.modules_required > 0 else Load.NONE


## Comprimento do trecho no chão (o passo e o tempo contam a distância horizontal).
func _segment_length(agent: Agent) -> float:
	return SidewalkPath.flat_distance(agent.points[agent.segment], agent.points[agent.segment + 1])


func _set_state(agent: Agent, state: State) -> void:
	var was_out := agent.state != State.HOME
	var was_visible := agent.state == State.WALKING or agent.state == State.WAITING
	agent.state = state
	_out += int(state != State.HOME) - int(was_out)
	_visible += int(state == State.WALKING or state == State.WAITING) - int(was_visible)


# --- escolhas e rotas ---

## Trabalho: um dos prédios mais perto da casa que empregam a classe do pedestre e estão na
## mesma rede de estrada. Sem nenhum da classe, qualquer prédio de trabalho da rede (o pedestre
## anda atrás de serviço).
func _pick_work(agent: Agent) -> int:
	if agent.tourist:
		return 0
	if not _work_choices.has(agent.home_id):
		_work_choices[agent.home_id] = _work_candidates(agent)
	var choices: PackedInt32Array = _work_choices[agent.home_id]
	return choices[_rng.randi_range(0, choices.size() - 1)] if not choices.is_empty() else 0


func _work_candidates(agent: Agent) -> PackedInt32Array:
	var derived := _simulation.derived_state()
	var own := _nearest(agent, derived.production, func(def: BuildingDef) -> bool: return def.workforce_tier == agent.tier)
	if not own.is_empty():
		return own
	var any: Array[int] = derived.production.duplicate()
	any.append_array(derived.warehouses_list())
	return _nearest(agent, any, func(_def: BuildingDef) -> bool: return true)


## Os pedestrian_work_choices prédios da lista mais perto da casa, na mesma rede de estrada.
func _nearest(agent: Agent, ids: Array[int], accepts: Callable) -> PackedInt32Array:
	var world := _simulation.world
	var home := world.building(agent.home_id)
	var home_label := _label_of(home)
	var found: Array[Vector2] = []
	if home_label <= 0:
		return PackedInt32Array()
	for building_id: int in ids:
		var record := world.building(building_id)
		if record == null or record.island_id != home.island_id:
			continue
		if not accepts.call(_simulation.def_of(record)) or _label_of(record) != home_label:
			continue
		found.append(Vector2(Vector2(record.origin - home.origin).length_squared(), building_id))
	found.sort()
	var result := PackedInt32Array()
	for i: int in mini(found.size(), _config.pedestrian_work_choices):
		result.append(int(found[i].y))
	return result


## Serviço: um dos que atendem a casa; sem nenhum, um dos mais perto na mesma rede de estrada.
func _pick_service(agent: Agent) -> int:
	if agent.tourist:
		return _pick_attraction(agent)
	var square := _resident_festival(agent)
	if square != 0:
		return square
	if not _services_of.has(agent.home_id):
		_services_of[agent.home_id] = _nearest(agent, _simulation.derived_state().services_list(),
				func(_def: BuildingDef) -> bool: return true)
	var services: PackedInt32Array = _services_of[agent.home_id]
	return services[_rng.randi_range(0, services.size() - 1)] if not services.is_empty() else 0


## Fase 80: a atração que o turista visita: uma das TOURIST_CHOICES de mais beleza da ilha (os prédios com beleza e raio),
## na mesma rede de estrada do entreposto.
func _pick_attraction(agent: Agent) -> int:
	if fireworks_now(agent.island_id):
		var squares := _festival_squares(agent.home_id)
		if not squares.is_empty():
			return squares[_rng.randi_range(0, squares.size() - 1)]
	if not _attractions_of.has(agent.home_id):
		var world := _simulation.world
		var post := world.building(agent.home_id)
		var post_label := _label_of(post) if post != null else 0
		var found: Array[Vector2] = []
		if post_label > 0:
			for record: BuildingRecord in world.buildings.values():
				var def := _simulation.def_of(record)
				if record.island_id != post.island_id or def.beauty <= 0.0 or def.beauty_radius_cells <= 0:
					continue
				if _label_of(record) != post_label:
					continue
				found.append(Vector2(-DerivedState.beauty_strength(world, _simulation.data, record.id), record.id))
		found.sort()
		var ids := PackedInt32Array()
		for i: int in mini(found.size(), TOURIST_CHOICES):
			ids.append(int(found[i].y))
		_attractions_of[agent.home_id] = ids
	var choices: PackedInt32Array = _attractions_of[agent.home_id]
	return choices[_rng.randi_range(0, choices.size() - 1)] if not choices.is_empty() else 0


## Fase 83: na hora dos fogos, RESIDENT_WATCH_SHARE dos moradores escolhem uma das praças da festa que a casa alcança; 0 para
## o turista, fora da hora ou para quem segue a rotina.
func _resident_festival(agent: Agent) -> int:
	if agent.tourist or not fireworks_now(agent.island_id) or _rng.randf() >= RESIDENT_WATCH_SHARE:
		return 0
	var squares := _festival_squares(agent.home_id)
	return squares[_rng.randi_range(0, squares.size() - 1)] if not squares.is_empty() else 0


## Fase 82: festa na ilha e hora dos fogos (a mesma noite em que a FestivalView os solta).
func fireworks_now(island_id: int) -> bool:
	return TourismSystem.has_festival(_simulation.world, island_id) \
			and DayClock.night_factor(_config, _hour) >= FestivalView.NIGHT_FIREWORKS


## Fase 82: as praças da festa (FestivalView.squares) com mastro na rua, na mesma rede de estrada do entreposto
## (desde a Fase 83, também da casa do morador: a chave é o prédio de onde ele sai).
func _festival_squares(post_id: int) -> PackedInt32Array:
	if _squares_of.has(post_id):
		return _squares_of[post_id]
	var ids := PackedInt32Array()
	var post := _simulation.world.building(post_id)
	var post_label := _label_of(post) if post != null else 0
	if post_label > 0:
		for building_id: int in FestivalView.squares(_simulation, post.island_id):
			var record := _simulation.world.building(building_id)
			if _label_of(record) == post_label and not FestivalView.strings_of(_simulation, building_id).is_empty():
				ids.append(building_id)
	_squares_of[post_id] = ids
	return ids


## Fase 82: lugar para ver a festa: na rua, ao longo de uma das cordas do mastro, de frente para ele. Falso se a praça não
## tem mastro (a porta não dá para estrada reta).
func _watch_spot(agent: Agent, square: BuildingRecord) -> bool:
	var lines := FestivalView.strings_of(_simulation, square.id)
	if lines.is_empty():
		return false
	var line := lines[_rng.randi_range(0, lines.size() - 1)]
	var mast := Vector3(line[0].x, 0.0, line[0].z)
	var along := Vector3(line[1].x, 0.0, line[1].z) - mast
	var reach := along.length()
	along /= maxf(reach, 0.001)
	var side := along.cross(Vector3.UP) * _cell_size * WATCH_SIDE_SHARE
	agent.spot = mast + along * _rng.randf_range(WATCH_NEAR_M, minf(WATCH_FAR_M, reach)) + side * _rng.randf_range(-1.0, 1.0)
	agent.spot.y = _simulation.world.island(square.island_id).height_at(agent.spot.x, agent.spot.z)
	var toward := mast - Vector3(agent.spot.x, 0.0, agent.spot.z)
	agent.facing = toward.normalized().rotated(Vector3.UP, _rng.randf_range(-0.4, 0.4))
	return true


## Rota de porta a porta: [pontos na calçada, células da estrada], em cache por par de prédios.
func _route(from_id: int, to_id: int) -> Array:
	var key := Vector2i(from_id, to_id)
	if _legs.has(key):
		return _legs[key]
	var started := Time.get_ticks_usec()
	var world := _simulation.world
	var from := world.building(from_id)
	var to := world.building(to_id)
	var result: Array = []
	if from != null and to != null and from.island_id == to.island_id:
		var grid := world.island(from.island_id)
		var start := _access_cell(grid, from)
		var goal := _access_cell(grid, to)
		if start >= 0 and goal >= 0:
			var cells := _router(from.island_id).path(start, goal)
			if not cells.is_empty():
				var points := PackedVector3Array([_door_point(from, _simulation.def_of(from))])
				points.append_array(SidewalkPath.from_cells(grid, cells, _config.pedestrian_sidewalk_offset_m))
				points.append(_door_point(to, _simulation.def_of(to)))
				result = [points, cells]
	_legs[key] = result
	var spent := Time.get_ticks_usec() - started
	_route_usec += spent
	routes_computed += 1
	routes_usec += spent
	return result


## Meio da face de entrada do prédio, no chão (a célula de entrada é a de fora, na frente: a porta
## fica meia célula para trás).
func _door_point(record: BuildingRecord, def: BuildingDef) -> Vector3:
	var grid := _simulation.world.island(record.island_id)
	var entrance := grid.cell_world(Footprint.entrance_cell(record.origin, def.size, record.rotation))
	var front := Footprint.front_direction(record.rotation)
	var point := Vector3(entrance.x, 0.0, entrance.z) - Vector3(front.x, 0.0, front.y) * (_cell_size * 0.5)
	point.y = grid.height_at(point.x, point.z)
	return point


## Primeira célula de estrada encostada na face de entrada, ou −1.
func _access_cell(grid: IslandGrid, record: BuildingRecord) -> int:
	var def := _simulation.def_of(record)
	var cells := Footprint.front_cells(record.origin, def.size, record.rotation)
	var middle := Footprint.entrance_cell(record.origin, def.size, record.rotation)
	if grid.in_bounds(middle) and grid.has_road(middle):
		return grid.index(middle)
	for cell: Vector2i in cells:
		if grid.in_bounds(cell) and grid.has_road(cell):
			return grid.index(cell)
	return -1


## Trecho de estrada (componente) em que o prédio encosta; 0 sem estrada. Em cache por prédio.
func _label_of(record: BuildingRecord) -> int:
	if _building_labels.has(record.id):
		return _building_labels[record.id]
	var grid := _simulation.world.island(record.island_id)
	if not _labels.has(record.island_id):
		_labels[record.island_id] = RoadNetwork.components(grid)
	var cell := _access_cell(grid, record)
	var labels: PackedInt32Array = _labels[record.island_id]
	var label := labels[cell] if cell >= 0 else 0
	_building_labels[record.id] = label
	return label


func _router(island_id: int) -> RoadRouter:
	if not _routers.has(island_id):
		_routers[island_id] = RoadRouter.new(_simulation.world.island(island_id))
	return _routers[island_id]


## Depois de construir ou demolir: esquece rotas e escolhas, refaz quem cada casa alcança e tira
## da rua quem perdeu o destino ou a estrada debaixo dos pés.
func _refresh_structure() -> void:
	_structure_dirty = false
	_routers.clear()
	_labels.clear()
	_building_labels.clear()
	_legs.clear()
	_work_choices.clear()
	_services_of.clear()
	_attractions_of.clear()
	_squares_of.clear()
	var derived := _simulation.derived_state()
	for service_id: int in derived.service_houses:
		for house: Variant in derived.service_houses[service_id]:
			var house_id: int = house
			var services: PackedInt32Array = _services_of.get(house_id, PackedInt32Array())
			services.append(service_id)
			_services_of[house_id] = services
	var lost_roads: Dictionary[int, bool] = {}
	for island_id: int in _simulation.world.islands.size():
		var grid := _simulation.world.island(island_id)
		var count := grid.roads.size() - grid.roads.count(IslandGrid.Road.NONE)
		lost_roads[island_id] = count < _road_count.get(island_id, 0)
		_road_count[island_id] = count
	var world := _simulation.world
	for agent: Agent in agents:
		if agent == null:
			continue
		if world.building(agent.home_id) == null:
			_remove_agent(agent)
			continue
		var moving := agent.state == State.WALKING or agent.state == State.WAITING or agent.state == State.INSIDE
		if not moving:
			continue
		var target_gone := world.building(agent.target_id) == null
		if target_gone or (lost_roads.get(agent.island_id, false) and not _cells_ok(agent)):
			_go_home(agent)


func _cells_ok(agent: Agent) -> bool:
	var grid := _simulation.world.island(agent.island_id)
	for index: int in agent.cells:
		if grid.roads[index] == IslandGrid.Road.NONE:
			return false
	return true


static func _group_key(tier: StringName, body: int) -> StringName:
	return StringName("%s/%d" % [tier, body])


# --- instâncias ---

## Marca a instância do pedestre para a vista refazer.
func _write(agent: Agent) -> void:
	if not agent.queued:
		agent.queued = true
		changed.append(agent)


## Entrega e esvazia a lista de mudanças. Pedestre removido vem com removed = true.
func take_changes() -> Array[Agent]:
	var list := changed
	changed = []
	for agent: Agent in list:
		agent.queued = false
	return list


func is_hidden(agent: Agent) -> bool:
	return agent.state == State.HOME or agent.state == State.INSIDE or agent.removed


## Transformação da instância: no começo do trecho, olhando para onde anda (o boneco olha para −Z).
func instance_transform(agent: Agent) -> Transform3D:
	if is_hidden(agent):
		return Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)
	if agent.state != State.WALKING:
		return Transform3D(Basis.looking_at(agent.facing.normalized(), Vector3.UP), agent.spot)
	var origin := agent.points[agent.segment]
	var step := agent.points[agent.segment + 1] - origin
	var flat := Vector3(step.x, 0.0, step.z)
	if flat.length() < 0.001:
		return Transform3D(Basis.IDENTITY, origin)
	# corpo de pé, base inclinada: andar o comprimento horizontal em −Z leva até o fim do trecho
	var basis := Basis.looking_at(flat.normalized(), Vector3.UP)
	basis.z = -step / flat.length()
	return Transform3D(basis, origin)


## Dado próprio da instância para o shader: início do trecho (tempo visual), comprimento, velocidade
## e animação + fase (a parte fracionária).
func instance_custom(agent: Agent) -> Color:
	if agent.state != State.WALKING:
		return Color(agent.segment_start, 0.0, 0.0, agent.clip + minf(agent.phase, 0.999))
	var stride := _strides[agent.body][agent.clip] if agent.clip < _strides[agent.body].size() else 0.0
	var phase := fposmod(agent.phase + (agent.walked / stride if stride > 0.0 else 0.0), 1.0)
	return Color(agent.segment_start, _segment_length(agent), _config.pedestrian_speed_m_s, agent.clip + minf(phase, 0.999))


## Passo (m por ciclo) da animação do pedestre; 0 na animação parada.
func stride_of(agent: Agent) -> float:
	return _strides[agent.body][agent.clip] if agent.clip < _strides[agent.body].size() else 0.0


## Posição do pedestre agora (para testes e depuração): o shader faz a mesma conta.
func position_of(agent: Agent) -> Vector3:
	if agent.state == State.WAITING:
		return agent.spot
	if agent.state != State.WALKING:
		return Vector3.INF
	var from := agent.points[agent.segment]
	var to := agent.points[agent.segment + 1]
	var length := SidewalkPath.flat_distance(from, to)
	if length < 0.001:
		return from
	var distance := clampf((time - agent.segment_start) * _config.pedestrian_speed_m_s, 0.0, length)
	return from + (to - from) * (distance / length)
