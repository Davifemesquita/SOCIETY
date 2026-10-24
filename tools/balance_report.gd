extends Node
## Relatório de balanceamento (Fase 10): o jogador-robô joga 4 horas na ilha plana e a linha do
## tempo vai para docs/balanceamento.md (ou para o caminho dado), com população por classe, saldo, o
## pior saldo e o que travou a fila. Use junto da planilha (tools/godot.sh planilha) ao mexer nos números.
##   tools/godot.sh godot --headless --path . res://tools/balance_report.tscn -- "$PWD/docs/balanceamento.md"

const STEP_S := 900.0
const DURATION_S := 4.0 * 3600.0
## Raio-x (Fase 27): as colunas da manutenção, na ordem do Group.
enum Group { CONSUMER, INTERMEDIATE, MATERIAL, SERVICE, LOGISTICS }
const UPKEEP_COLUMNS: Array[String] = ["bens de consumo", "intermediários", "material", "serviços", "logística e navios"]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var path := args[0] if not args.is_empty() else ProjectSettings.globalize_path("user://balanceamento.md")
	var player := AutoPlayer.create()
	var sim := player.simulation
	var rows: PackedStringArray = []
	var tiers := sim.data.tiers
	var header := "| min | " + " | ".join(tiers.map(func(tier: TierDef) -> String: return tr(tier.name_key))) + " | casas | saldo | renda/min | manutenção/min | próximo da fila | parado por |"
	rows.append(header)
	rows.append("|" + "---|".repeat(tiers.size() + 7))
	# Fase 27: o raio-x da manutenção e da renda, na mesma linha do tempo
	var groups := upkeep_groups(sim.data)
	var xray: PackedStringArray = []
	xray.append("| min | " + " | ".join(UPKEEP_COLUMNS) + " | ociosas (<50%) | " \
			+ " | ".join(tiers.map(func(tier: TierDef) -> String: return "renda " + tr(tier.name_key))) + " |")
	xray.append("|" + "---|".repeat(UPKEEP_COLUMNS.size() + tiers.size() + 2))
	var works: PackedStringArray = []
	works.append("| min | casas | " + " | ".join(UPKEEP_COLUMNS) + " | total |")
	works.append("|" + "---|".repeat(UPKEEP_COLUMNS.size() + 3))
	var seen: Dictionary[int, bool] = {}
	var elapsed := 0.0
	while elapsed < DURATION_S:
		player.play(STEP_S)
		elapsed += STEP_S
		var world := sim.world
		var cells: Array[String] = ["%.0f" % (elapsed / 60.0)]
		for tier: TierDef in tiers:
			cells.append(str(world.population(tier.id)))
		cells.append(str(player.houses.size()))
		cells.append("%.0f" % world.money)
		cells.append("%.0f" % world.income_per_min)
		cells.append("%.0f" % world.upkeep_per_min)
		cells.append(String(player.next_in_queue()))
		cells.append(String(player.blocked_reason()))
		rows.append("| " + " | ".join(cells) + " |")
		var split := breakdown(sim, groups)
		var upkeep: Array = split["upkeep"]
		var income: Dictionary = split["income"]
		var xcells: Array[String] = ["%.0f" % (elapsed / 60.0)]
		for column: int in UPKEEP_COLUMNS.size() + 1:
			xcells.append("%.0f" % upkeep[column])
		for tier: TierDef in tiers:
			xcells.append("%.0f" % income.get(tier.id, 0.0))
		xray.append("| " + " | ".join(xcells) + " |")
		var spent := new_works(sim, groups, seen)
		var wcells: Array[String] = ["%.0f" % (elapsed / 60.0)]
		var total := 0.0
		for column: int in UPKEEP_COLUMNS.size() + 1:
			var count: int = spent[column].x
			wcells.append("%d (%.0f)" % [count, spent[column].y])
			total += spent[column].y
		wcells.append("%.0f" % total)
		works.append("| " + " | ".join(wcells) + " |")
	var text := """# Balanceamento — partida do jogador-robô

Gerado por `tools/balance_report.tscn` em %s. O robô (`tools/auto_player.gd`) joga 4 h numa ilha plana de
350×350 (a terra do arquipélago inteiro, no lugar das colônias),
dificuldade normal, pagando cada prédio, esperando material e desbloqueio, com carroças e armazéns;
corrige faltas pondo o produtor na frente da fila e pausa fábrica com o estoque cheio.

- Pior saldo: **%.0f** aos %.0f min (limite para construir: %.0f).
- Prédios no fim: %d; casas: %d.

%s

## Para onde vai a manutenção (moedas/min)

Prédios de produção pelo que fazem: bem que alguma classe consome, bem intermediário das cadeias ou material de
construção (custo de prédio ou de subir de classe); os serviços; armazéns, entreposto, píer e navios. "Ociosas" é a
parte da manutenção da produção que vai para fábricas abaixo de 50%% de produtividade (já contada nas colunas).

%s

## Obras de cada intervalo

Prédios novos nos 15 min até a linha, pelo mesmo grupo da manutenção, e as moedas que custaram (quantos (moedas));
as casas à parte (a subida de classe paga material, não moedas).

%s
""" % [Time.get_datetime_string_from_system(), player.lowest_money, player.lowest_at / 60.0,
			sim.config.min_balance_for(sim.world.difficulty), sim.world.buildings.size(), player.houses.size(), "\n".join(rows),
			"\n".join(xray), "\n".join(works)]
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("balance_report: ", path)
	get_tree().quit()


## O grupo de cada prédio de produção pelo bem que ele faz: consumo de alguma classe, material de construção
## (custo de prédio ou de subir de classe) ou intermediário.
static func upkeep_groups(data: GameData) -> Dictionary[StringName, int]:
	var materials: Dictionary[StringName, bool] = {}
	for def: BuildingDef in data.buildings:
		for good: StringName in def.cost_materials:
			materials[good] = true
	for tier: TierDef in data.tiers:
		for good: StringName in tier.upgrade_materials:
			materials[good] = true
	var groups: Dictionary[StringName, int] = {}
	for def: BuildingDef in data.buildings:
		if def.kind == BuildingDef.Kind.SERVICE:
			groups[def.id] = Group.SERVICE
		elif def.kind in [BuildingDef.Kind.WAREHOUSE, BuildingDef.Kind.PIER]:
			groups[def.id] = Group.LOGISTICS
		elif def.kind == BuildingDef.Kind.MODULE:
			# campos e pastos não têm manutenção; nas obras contam com as cadeias, como matéria-prima
			groups[def.id] = Group.INTERMEDIATE
		elif def.is_production():
			var good := data.good(def.output) if def.output != &"" else null
			if good != null and good.consumption_per_resident_t_min > 0.0:
				groups[def.id] = Group.CONSUMER
			elif materials.has(def.output):
				groups[def.id] = Group.MATERIAL
			else:
				groups[def.id] = Group.INTERMEDIATE
	return groups


## Os prédios que apareceram desde a última conferência (os já vistos ficam em "seen"): por grupo, quantos (x) e
## as moedas que custaram (y); a coluna 0 são as casas e as do Group vêm deslocadas de 1.
static func new_works(sim: Simulation, groups: Dictionary[StringName, int], seen: Dictionary[int, bool]) -> Array[Vector2]:
	var spent: Array[Vector2] = []
	spent.resize(UPKEEP_COLUMNS.size() + 1)
	spent.fill(Vector2.ZERO)
	for record: BuildingRecord in sim.world.buildings.values():
		if seen.has(record.id):
			continue
		seen[record.id] = true
		var def := sim.data.building(record.def_id)
		var column := 0 if def.kind == BuildingDef.Kind.RESIDENCE else (groups[def.id] + 1 if groups.has(def.id) else -1)
		if column >= 0:
			spent[column] += Vector2(1.0, def.cost_money)
	return spent


## A manutenção por grupo (e, no fim, a das fábricas abaixo de 50%) e a renda por classe, agora.
static func breakdown(sim: Simulation, groups: Dictionary[StringName, int]) -> Dictionary:
	var upkeep: Array[float] = []
	upkeep.resize(UPKEEP_COLUMNS.size() + 1)
	upkeep.fill(0.0)
	var income: Dictionary[StringName, float] = {}
	for record: BuildingRecord in sim.world.buildings.values():
		var def := sim.data.building(record.def_id)
		if def.kind == BuildingDef.Kind.RESIDENCE:
			income[record.tier] = income.get(record.tier, 0.0) + record.tax_per_min
			continue
		if not groups.has(def.id):
			continue
		var cost := def.upkeep_per_min * (sim.config.paused_upkeep_factor if record.paused else 1.0)
		upkeep[groups[def.id]] += cost
		if def.is_production() and record.productivity < 0.5:
			upkeep[UPKEEP_COLUMNS.size()] += cost
	for ship: Ship in sim.world.ships.values():
		if ship.owner == Ship.Owner.PLAYER:
			upkeep[Group.LOGISTICS] += sim.data.ship(ship.def_id).upkeep_per_min
	return {"upkeep": upkeep, "income": income}
