class_name SaveMigrations
extends RefCounted
## Migrações do formato do save, uma por versão. all()[i] leva da versão i + 1 para a i + 2.


static func all() -> Array[Callable]:
	return [from_1_to_2, from_2_to_3, from_3_to_4, from_4_to_5]


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
