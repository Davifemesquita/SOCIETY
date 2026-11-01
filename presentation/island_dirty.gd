class_name IslandDirty
extends RefCounted
## Fases 178 e 180: as ilhas que uma vista do arquipélago inteiro precisa refazer. A obra, a estrada e as árvores mexem numa
## ilha só, e refazer todas a cada obra custava dezenas de ms no quadro seguinte. Guarda a ilha de cada prédio visto, para saber
## de onde saiu o demolido (sem ela, refaz todas).

var _stale: Dictionary[int, bool] = {}
var _all := true
var _island_of: Dictionary[int, int] = {}


func pending() -> bool:
	return _all or not _stale.is_empty()


func mark_all() -> void:
	_all = true


func mark_island(island_id: int) -> void:
	_stale[island_id] = true


## Obra ou demolição do prédio: a ilha dele (a do registro ou, se ele já saiu, a guardada; sem nenhuma, todas).
func mark_building(world: WorldState, building_id: int) -> void:
	var record := world.building(building_id)
	if record != null:
		_island_of[building_id] = record.island_id
		_stale[record.island_id] = true
	elif _island_of.has(building_id):
		_stale[_island_of[building_id]] = true
		_island_of.erase(building_id)
	else:
		_all = true


## As ilhas a refazer agora (todas, se tudo ficou velho), e zera a conta.
func take(world: WorldState) -> Array[int]:
	var result: Array[int] = []
	if _all:
		_island_of.clear()
		for id: int in world.buildings:
			var record := world.building(id)
			_island_of[id] = record.island_id
		for island_id: int in world.islands.size():
			result.append(island_id)
	else:
		for island_id: int in _stale:
			if island_id < world.islands.size():
				result.append(island_id)
	_all = false
	_stale.clear()
	return result
