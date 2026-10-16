class_name SaveMigrations
extends RefCounted
## Migrações do formato do save, uma por versão. all()[i] leva da versão i + 1 para a i + 2.


static func all() -> Array[Callable]:
	return [from_1_to_2, from_2_to_3, from_3_to_4, from_4_to_5, from_5_to_6, from_6_to_7, from_7_to_8, from_8_to_9, from_9_to_10, from_10_to_11, from_11_to_12, from_12_to_13, from_13_to_14]


## Fase 1 → Fase 2: as caixas provisórias saem (as estradas ficam) e entra a economia, com o
## dinheiro e os materiais iniciais.
static func from_1_to_2(state: Dictionary) -> Dictionary:
	var config := GameConfig.get_default()
	var world: Dictionary = state.get("world", {})
	var kept: Array = []
	var buildings: Array = world.get("buildings", [])
	for raw: Variant in buildings:
		if raw is Dictionary:
			var record: Dictionary = raw
			if not str(record.get("def", "")).begins_with("placeholder_"):
				kept.append(record)
	world["buildings"] = kept
	world["money"] = float(config.starting_money)
	world["tax_levels"] = {}
	world["tick"] = 0
	var islands: Array = world.get("islands", [])
	for raw: Variant in islands:
		if raw is Dictionary:
			var island: Dictionary = raw
			var stock := {}
			for material: StringName in config.starting_materials:
				stock[material] = float(config.starting_materials[material])
			island["economy"] = {"profile": GameData.get_default().island_profiles[0].id, "stock": stock,
					"category_supply": {}, "good_supply": {}, "shortage_announced": {}}
	state["world"] = world
	return state


## Fase 2 → Fase 3: cada prédio ganha nível 0 e cada prédio de produção ganha sua carroça, em
## casa. Sem entreposto, a produção espera até o jogador construir um (decisão do dono do
## produto: o save não se perde).
static func from_2_to_3(state: Dictionary) -> Dictionary:
	var data := GameData.get_default()
	var world: Dictionary = state.get("world", {})
	var carts: Array = []
	var buildings: Array = world.get("buildings", [])
	for raw: Variant in buildings:
		if raw is Dictionary:
			var record: Dictionary = raw
			record["level"] = 0
			var def_id: Variant = record.get("def")
			var home: Variant = record.get("id")
			if def_id is StringName and home is int:
				var def_name: StringName = def_id
				var home_id: int = home
				var def := data.building(def_name)
				if def != null and def.is_production():
					var cart := Cart.new(home_id)
					carts.append(cart.to_dict())
	world["carts"] = carts
	state["world"] = world
	return state


## Fase 4 → Fase 5: o save antigo segue na ilha plana de antes (terrain_version 0, decisão do dono
## do produto): sem semente e sem árvore derrubada.
static func from_3_to_4(state: Dictionary) -> Dictionary:
	var world: Dictionary = state.get("world", {})
	world["seed"] = 0
	world["terrain_version"] = 0
	var islands: Array = world.get("islands", [])
	for raw: Variant in islands:
		if raw is Dictionary:
			var island: Dictionary = raw
			island["cleared_trees"] = PackedInt32Array()
	state["world"] = world
	return state


## Fase 5 → Fase 6: o save antigo segue sem navios e sem rotas (o estoque que já tinha fica); os
## marcos são contados de novo pela população no primeiro tick, e o comerciante aparece no posto.
static func from_4_to_5(state: Dictionary) -> Dictionary:
	var world: Dictionary = state.get("world", {})
	world["ships"] = []
	world["next_ship_id"] = 1
	world["routes"] = []
	world["next_route_id"] = 1
	world["trader"] = TraderState.new().to_dict()
	world["milestones_reached"] = 0
	var islands: Array = world.get("islands", [])
	for raw: Variant in islands:
		if raw is Dictionary:
			var island: Dictionary = raw
			var economy: Dictionary = island.get("economy", {})
			economy["sell_above"] = {}
			economy["buy_up_to"] = {}
			island["economy"] = economy
	state["world"] = world
	return state


## Fase 6 → Fase 7: dificuldade normal (a única que existia) e o histórico das estatísticas vazio
## (os gráficos começam a partir do carregamento).
static func from_5_to_6(state: Dictionary) -> Dictionary:
	var world: Dictionary = state.get("world", {})
	world["difficulty"] = 1
	world["history"] = StatisticsHistory.new().to_dict()
	state["world"] = world
	return state


## Fase 7 → Fase 8: toda estrada antiga é de terra e as metas guiadas recomeçam do início (as já
## cumpridas passam sozinhas na primeira conferência, sem prêmio de novo: ver GoalSystem).
static func from_6_to_7(state: Dictionary) -> Dictionary:
	var world: Dictionary = state.get("world", {})
	var islands: Array = world.get("islands", [])
	for raw: Variant in islands:
		if raw is Dictionary:
			var island: Dictionary = raw
			island["paved"] = PackedInt32Array()
	world["goals_done"] = 0
	world["goals_catch_up"] = true
	state["world"] = world
	return state


## Fase 10 → Fase 11: o arquipélago gerado ganha as ilhas tropicais (as mesmas que a semente dá no
## jogo novo), virgens e sem estoque. As temperadas não mudam; a ilha plana antiga fica sem elas.
static func from_7_to_8(state: Dictionary) -> Dictionary:
	var config := GameConfig.get_default()
	var world: Dictionary = state.get("world", {})
	var raw_version: Variant = world.get("terrain_version")
	var raw_seed: Variant = world.get("seed")
	var raw_islands: Variant = world.get("islands")
	if raw_version is int and raw_version != 0 and raw_seed is int and raw_islands is Array:
		var islands: Array = raw_islands
		var seed_value: int = raw_seed
		for spec: ArchipelagoGenerator.IslandSpec in ArchipelagoGenerator.tropical_layout(seed_value, config, GameData.get_default(), islands.size()):
			var economy := IslandEconomy.new()
			economy.profile_id = spec.profile.id
			islands.append({"size": Vector2i(spec.size, spec.size), "roads": PackedInt32Array(), "paved": PackedInt32Array(),
					"cleared_trees": PackedInt32Array(), "economy": economy.to_dict(), "origin": spec.origin_m})
	state["world"] = world
	return state


## Fase 11 (ilhas tropicais) → Fase 11 (eventos e encomendas): a partida antiga ganha os eventos e
## as encomendas ligados, com o relógio deles começando do zero (o primeiro sai depois do mesmo
## tempo que num jogo novo).
static func from_8_to_9(state: Dictionary) -> Dictionary:
	var world: Dictionary = state.get("world", {})
	var events := EventsState.new()
	events.enabled = true
	world["events"] = events.to_dict()
	state["world"] = world
	return state


## Eventos e encomendas → rivais (Fase 11): a partida antiga ganha as companhias rivais, com a
## primeira colônia de cada uma marcada a partir de agora.
static func from_9_to_10(state: Dictionary) -> Dictionary:
	var world: Dictionary = state.get("world", {})
	var rivals := RivalsState.new()
	rivals.start(GameData.get_default(), GameConfig.get_default())
	world["rivals"] = rivals.to_dict()
	state["world"] = world
	return state


## Rivais → combate naval (Fase 11): todo navio ganha o casco cheio e a arma pronta; as rivais, a
## lista de fragatas vazia (só existem em guerra).
static func from_10_to_11(state: Dictionary) -> Dictionary:
	var data := GameData.get_default()
	var world: Dictionary = state.get("world", {})
	var ships: Array = world.get("ships", [])
	for raw: Variant in ships:
		if raw is Dictionary:
			var ship: Dictionary = raw
			var raw_def: Variant = ship.get("def")
			var def_id: StringName = raw_def if raw_def is StringName else &""
			var def := data.ship(def_id)
			ship["hp"] = def.hull_points if def != null else 1.0
			ship["reload"] = 0.0
	var rivals: Dictionary = world.get("rivals", {})
	var list: Array = rivals.get("rivals", [])
	for raw: Variant in list:
		if raw is Dictionary:
			var rival: Dictionary = raw
			rival["warships"] = []
			rival["next_warship_tick"] = 0
	state["world"] = world
	return state


## Combate naval → especialistas (Fase 11): a partida antiga começa sem contratados; a oferta da volta
## em que o comerciante está chega no primeiro tick. A eletricidade não mudou o save.
static func from_11_to_12(state: Dictionary) -> Dictionary:
	var world: Dictionary = state.get("world", {})
	world["specialists"] = SpecialistsState.new().to_dict()
	state["world"] = world
	return state


## Especialistas → riscos (seção 8): a partida antiga abre com incêndio e doença desligados, para
## nada pegar fogo de repente numa cidade erguida sem bombeiros.
static func from_12_to_13(state: Dictionary) -> Dictionary:
	var world: Dictionary = state.get("world", {})
	world["risks"] = RisksState.new().to_dict()
	state["world"] = world
	return state


## Riscos → estaleiro: a partida antiga começa sem encomenda.
static func from_13_to_14(state: Dictionary) -> Dictionary:
	var world: Dictionary = state.get("world", {})
	world["shipyard"] = ShipyardState.new().to_dict()
	state["world"] = world
	return state
