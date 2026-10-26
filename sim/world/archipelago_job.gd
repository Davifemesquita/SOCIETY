class_name ArchipelagoJob
extends RefCounted
## Jogo novo em etapas (Fase 42): o arquipélago da semente gerado com uma ilha por tarefa no WorkerThreadPool, enquanto
## a cortina mostra o progresso de verdade (pelo tamanho de cada ilha). As ilhas são independentes (cada uma com o
## ruído e o sorteio dela, a partir da semente) e o mundo é montado na mesma ordem do ArchipelagoGenerator.new_world:
## o resultado é idêntico com ou sem thread e com qualquer número delas. Nada aqui toca a árvore de cena nem a GPU.

var _seed: int
var _config: GameConfig
var _data: GameData
var _difficulty: int
## Fase 45: o gerador (1 ou 2).
var _version: int
var _specs: Array[ArchipelagoGenerator.IslandSpec] = []
var _grids: Array[IslandGrid] = []
var _tasks: PackedInt64Array = []
var _done: PackedByteArray = []
var _weights: PackedFloat64Array = []
var _total_weight: float = 0.0
var _progress: float = 0.0
var _started: bool = false
var _world: WorldState


func _init(seed_value: int, config: GameConfig, data: GameData, archipelago_size: int = -1, difficulty: int = -1,
		version: int = -1) -> void:
	_seed = seed_value
	_version = version if version > 0 else config.new_game_terrain_version
	_config = config
	_data = data
	_difficulty = difficulty
	var size_index := archipelago_size if archipelago_size >= 0 else config.default_archipelago_size
	_specs = ArchipelagoGenerator.layout(seed_value, config, data, config.island_count_for(size_index))
	_specs.append_array(ArchipelagoGenerator.tropical_layout(seed_value, config, data, _specs.size()))
	_grids.resize(_specs.size())
	_done.resize(_specs.size())
	for spec: ArchipelagoGenerator.IslandSpec in _specs:
		# o custo de uma ilha cresce com a área
		var weight := float(spec.size * spec.size)
		_weights.append(weight)
		_total_weight += weight


## Manda as ilhas para o WorkerThreadPool (threaded) ou faz tudo aqui mesmo, de uma vez.
func start(threaded: bool = true) -> void:
	_started = true
	if not threaded:
		for index: int in _specs.size():
			_build(index)
			_done[index] = 1
		_progress = 1.0
		return
	for index: int in _specs.size():
		_tasks.append(WorkerThreadPool.add_task(_build.bind(index), false, "ilha %d" % index))


## Confere as tarefas (no quadro, sem esperar); devolve se acabou. O progresso só sobe.
func poll() -> bool:
	if not _started:
		return false
	var finished := 0.0
	for index: int in _tasks.size():
		if _done[index] == 0 and WorkerThreadPool.is_task_completed(_tasks[index]):
			WorkerThreadPool.wait_for_task_completion(_tasks[index])
			_done[index] = 1
	for index: int in _done.size():
		if _done[index] == 1:
			finished += _weights[index]
	_progress = maxf(_progress, finished / maxf(_total_weight, 1.0))
	return is_done()


func is_done() -> bool:
	for flag: int in _done:
		if flag == 0:
			return false
	return _started


## De 0 a 1, pelo tamanho das ilhas prontas.
func progress() -> float:
	return _progress


func island_count() -> int:
	return _specs.size()


## Espera tudo (sem quadros: testes e o caminho direto).
func wait() -> void:
	for index: int in _tasks.size():
		if _done[index] == 0:
			WorkerThreadPool.wait_for_task_completion(_tasks[index])
			_done[index] = 1
	_progress = 1.0


## O mundo pronto (na thread principal, depois de terminar): as ilhas na ordem, as economias e a frota inicial.
func result() -> WorldState:
	if _world != null:
		return _world
	assert(is_done(), "ArchipelagoJob.result() antes de terminar")
	_world = ArchipelagoGenerator.assemble(_seed, _config, _data, _specs, _grids, _difficulty, _version)
	return _world


func _build(index: int) -> void:
	_grids[index] = ArchipelagoGenerator.build_island(_specs[index], _config, _version)
