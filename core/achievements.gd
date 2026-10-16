class_name Achievements
extends RefCounted
## Conquistas do jogador (Fase 12): as já ganhas e os contadores (incêndios apagados, navios
## afundados, vitórias) em user://achievements.cfg, fora do save da partida — valem para todas.
## Arquivo estragado ou ausente começa do zero, sem erro.

const DEFAULT_PATH := "user://achievements.cfg"

var path: String = DEFAULT_PATH
## Conquista → data em que foi ganha (unix).
var unlocked: Dictionary[StringName, int] = {}
## Contador (AchievementDef.Kind como texto) → valor.
var counters: Dictionary[String, int] = {}

static var _shared: Achievements


## A instância do jogo (carregada uma vez).
static func shared() -> Achievements:
	if _shared == null:
		_shared = Achievements.new()
		_shared.load_file()
	return _shared


## Troca a instância do jogo (testes, para não mexer no arquivo do jogador).
static func use(instance: Achievements) -> void:
	_shared = instance


func is_unlocked(id: StringName) -> bool:
	return unlocked.has(id)


## Ganha a conquista (devolve false se já tinha) e grava.
func unlock(id: StringName) -> bool:
	if unlocked.has(id):
		return false
	unlocked[id] = int(Time.get_unix_time_from_system())
	save_file()
	return true


func count(key: String) -> int:
	return counters.get(key, 0)


func add(key: String, amount: int = 1) -> int:
	counters[key] = counters.get(key, 0) + amount
	save_file()
	return counters[key]


func save_file() -> Error:
	var file := ConfigFile.new()
	for id: StringName in unlocked:
		file.set_value("unlocked", String(id), unlocked[id])
	for key: String in counters:
		file.set_value("counters", key, counters[key])
	return file.save(path)


func load_file() -> void:
	unlocked.clear()
	counters.clear()
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	if file.has_section("unlocked"):
		for key: String in file.get_section_keys("unlocked"):
			var value: Variant = file.get_value("unlocked", key)
			if value is int:
				var when: int = value
				unlocked[StringName(key)] = when
	if file.has_section("counters"):
		for key: String in file.get_section_keys("counters"):
			var value: Variant = file.get_value("counters", key)
			if value is int:
				var amount: int = value
				counters[key] = amount
