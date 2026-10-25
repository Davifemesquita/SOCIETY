class_name WarmUp
extends Node3D
## Fase 32: a primeira vez de cada coisa desenhada atrás da cortina. O Forward+ compila o shader e as pipelines na
## primeira vez que um material aparece; sem isto, o soluço cai no meio da partida, no primeiro prédio de cada tipo, na
## primeira obra e na primeira plantação. No jogo novo e no carregar, a GameScreen monta este nó: um mundo de rascunho
## (uma ilha plana, fora da partida) com um prédio de cada tipo e uma casa de cada classe, estradas de terra e de
## pedra, o andaime com a poeira, desenhado pelas mesmas vistas da partida, encolhido na frente da câmera por FRAMES
## quadros. Depois some sozinho. A SceneFader espera os nós do grupo HOLD_GROUP antes de clarear.
## Nada aqui toca na simulação da partida: o rascunho é construído pelos comandos direto (sem o Simulation.execute,
## que avisaria o EventBus), e as vistas de rascunho são desligadas do EventBus logo depois de montadas.

signal finished

## Grupo que segura a cortina (SceneFader) enquanto houver alguém nele.
const HOLD_GROUP := &"curtain_hold"
## Quadros desenhados antes de sumir (a sombra e a profundidade compilam no quadro seguinte ao da cor).
const FRAMES := 4
## O rascunho (uma ilha de ~500 m) encolhido a isto, a WARM_DISTANCE_M na frente da câmera: cabe todo na tela.
const SHRINK := 0.04
const WARM_DISTANCE_M := 30.0
## Distância entre os prédios do rascunho, em células.
const STEP_CELLS := 12

var simulation: Simulation
var views: Array[Node3D] = []

var _frames_left: int = FRAMES


## A primeira vez fica atrás da cortina? Sem tela não há o que compilar; a suíte desliga (SOCIETY_SEM_WARMUP=1,
## posto pelo tools/godot.sh testes), porque cada partida dos testes pagaria o rascunho inteiro.
static func enabled() -> bool:
	return DisplayServer.get_name() != "headless" and OS.get_environment("SOCIETY_SEM_WARMUP") != "1"


## O mundo de rascunho: um de cada prédio (a casa em cada classe), sem custo nem terreno, e uma rua de terra e uma
## calçada passando na frente de todos. Pelos comandos direto: nenhum sinal sai para a partida.
static func scratch(config: GameConfig, data: GameData) -> Simulation:
	var sim := Simulation.new(config, data)
	var context := CommandContext.new(sim.world, data, config, true)
	context.ignore_terrain = true
	var size := sim.world.island(Simulation.MAIN_ISLAND).size
	var at := Vector2i(2, 4)
	PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"trading_post", Vector2i(2, 4), 0).execute(context)
	var row_starts: Array[int] = []
	var placed: Array[int] = []
	var wanted: Array[Array] = []
	for def: BuildingDef in data.buildings:
		if def.id == &"trading_post":
			continue
		if def.kind == BuildingDef.Kind.RESIDENCE:
			for tier: TierDef in data.tiers:
				wanted.append([def.id, tier.id])
		else:
			wanted.append([def.id, &""])
	at.x += STEP_CELLS
	row_starts.append(at.y)
	for item: Array in wanted:
		if at.x + STEP_CELLS >= size.x:
			at = Vector2i(2, at.y + STEP_CELLS)
			row_starts.append(at.y)
		if at.y + STEP_CELLS >= size.y:
			break
		var def_id: StringName = item[0]
		var result := PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, def_id, at, 0).execute(context)
		if result.ok() and not result.placed.is_empty():
			var tier: StringName = item[1]
			if tier != &"":
				sim.world.building(result.placed[0]).tier = tier
			placed.append(result.placed[0])
		at.x += STEP_CELLS
	# a rua na frente de cada fileira: metade de terra, metade calçada
	for y: int in row_starts:
		var road_y := y - 1
		var half := floori(size.x / 2.0)
		BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(Vector2i(1, road_y), Vector2i(half, road_y))).execute(context)
		BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(Vector2i(half + 1, road_y), Vector2i(size.x - 2, road_y)),
				true).execute(context)
	return sim


## Monta o rascunho na frente da câmera e começa a contar os quadros.
func start(config: GameConfig, data: GameData, camera: Camera3D) -> void:
	name = "WarmUp"
	add_to_group(HOLD_GROUP)
	simulation = scratch(config, data)
	var cell := config.cell_size_m
	var road_view := RoadView.new()
	road_view.setup(simulation, cell)
	var building_view := BuildingView.new()
	building_view.setup(simulation, cell)
	var window_view := WindowLightsView.new()
	window_view.setup(simulation, config)
	var stockpiles := StockpileView.new()
	var lamps := LampView.new()
	var crops := CropView.new()
	var harbor := HarborView.new()
	var yards := YardView.new()
	var decorations := DecorationView.new()
	for view: Node3D in [road_view, building_view, window_view, stockpiles, lamps, crops, harbor, yards, decorations]:
		add_child(view)
		views.append(view)
	stockpiles.setup(simulation, cell)
	lamps.setup(simulation, cell)
	crops.setup(simulation)
	harbor.setup(simulation)
	yards.setup(simulation)
	decorations.setup(simulation)
	for view: Node3D in views:
		disconnect_from_bus(view)
	# a obra (andaime e poeira) numa das casas
	for building_id: int in simulation.world.building_ids():
		if simulation.world.building(building_id).is_house():
			building_view.show_scaffold(building_id)
			break
	if camera != null and camera.is_inside_tree():
		var forward := -camera.global_basis.z
		var size := Vector2(simulation.world.island(Simulation.MAIN_ISLAND).size) * cell * SHRINK
		global_position = camera.global_position + forward * WARM_DISTANCE_M - Vector3(size.x, 0.0, size.y) * 0.5
	scale = Vector3.ONE * SHRINK


## Tira as ligações do EventBus que apontam para "node": a vista de rascunho não pode reagir aos prédios da partida.
static func disconnect_from_bus(node: Object) -> void:
	for info: Dictionary in EventBus.get_signal_list():
		var signal_name: StringName = info.name
		for connection: Dictionary in EventBus.get_signal_connection_list(signal_name):
			var callable: Callable = connection.callable
			if callable.get_object() == node:
				EventBus.disconnect(signal_name, callable)


## Quantas ligações do EventBus ainda apontam para "node" (teste).
static func bus_connections(node: Object) -> int:
	var count := 0
	for info: Dictionary in EventBus.get_signal_list():
		var signal_name: StringName = info.name
		for connection: Dictionary in EventBus.get_signal_connection_list(signal_name):
			var callable: Callable = connection.callable
			if callable.get_object() == node:
				count += 1
	return count


func _process(_delta: float) -> void:
	_frames_left -= 1
	if _frames_left > 0:
		return
	set_process(false)
	remove_from_group(HOLD_GROUP)
	finished.emit()
	queue_free()
