class_name ArchipelagoPreview
extends RefCounted
## Prévia do arquipélago (Fase 44): o mundo da semente gerado numa tarefa do WorkerThreadPool — o mesmo
## ArchipelagoGenerator.new_world que a partida usa, as mesmas alturas — e a carta náutica dele gravada
## (ArchipelagoMap.engrave, numa escala menor). Nada aqui toca a árvore de cena. Trocar a semente faz uma prévia nova; a
## velha é cancelada: o resultado dela é descartado, e a tarefa é recolhida quando termina (nenhuma fica sem
## wait_for_task_completion). Também serve ao fundo do menu (uma semente fixa).

const SCALE := 1

var seed_value: int
var archipelago_size: int
## Pixels por célula da carta gravada (o diálogo usa SCALE; o fundo do menu, mais).
var engrave_scale: int = SCALE
## Fase 45: o gerador da prévia (o mesmo que a partida vai usar).
var terrain_version: int = -1
var _config: GameConfig
var _data: GameData
var _task: int = -1
var _cancelled: bool = false
var _collected: bool = false
## Escrito pela tarefa, lido depois que ela termina.
var _world: WorldState
var _image: Image


func _init(seed_number: int, size_index: int, config: GameConfig, data: GameData, scale: int = SCALE,
		version: int = -1) -> void:
	seed_value = seed_number
	terrain_version = version
	engrave_scale = scale
	archipelago_size = size_index
	_config = config
	_data = data


func start(threaded: bool = true) -> void:
	if threaded:
		_task = WorkerThreadPool.add_task(_build, false, "prévia %d" % seed_value)
	else:
		_build()
		_collected = true


## Terminou (e foi recolhida)? Chame a cada quadro.
func poll() -> bool:
	if _collected:
		return true
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_collected = true
	return _collected


## A semente mudou: o resultado desta não interessa mais (a tarefa ainda é recolhida pelo poll()).
func cancel() -> void:
	_cancelled = true


func is_cancelled() -> bool:
	return _cancelled


## A carta gravada (null se cancelada ou ainda não pronta).
func image() -> Image:
	return _image if _collected and not _cancelled else null


## O mundo gerado (testes: as mesmas alturas da partida).
func world() -> WorldState:
	return _world if _collected else null


## Prévias de quem já saiu da tela (o diálogo fechado no meio de uma): recolhidas por reap(), que o SceneFader chama
## a cada quadro.
static var _orphans: Array[ArchipelagoPreview] = []


static func adopt(orphan: ArchipelagoPreview) -> void:
	orphan.cancel()
	if not orphan.poll():
		_orphans.append(orphan)


static func reap() -> void:
	for orphan: ArchipelagoPreview in _orphans.duplicate():
		if orphan.poll():
			_orphans.erase(orphan)


static func orphan_count() -> int:
	return _orphans.size()


func _build() -> void:
	_world = ArchipelagoGenerator.new_world(seed_value, _config, _data, archipelago_size, -1, terrain_version)
	if _cancelled:
		return
	_image = ArchipelagoMap.engrave(SeaChart.new(_world, _config), engrave_scale)
