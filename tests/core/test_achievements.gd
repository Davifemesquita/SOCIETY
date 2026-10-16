extends GdUnitTestSuite
## Conquistas (Fase 12): ficam num arquivo do jogador (fora do save), ganhas uma vez só; as de estado
## saem do mundo, as de acontecimento dos contadores; a de cenário só com aquele cenário vencido;
## construir de graça não ganha nada.

const PATH := "user://test_achievements.cfg"

var _store: Achievements
var _sim: Simulation


func before_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	_store = Achievements.new()
	_store.path = PATH
	_sim = SimFixture.simulation()
	_sim.free_build = false


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_store_keeps_unlocks_and_counters_and_survives_a_broken_file() -> void:
	assert_bool(_store.unlock(&"tycoon")).is_true()
	assert_bool(_store.unlock(&"tycoon")).is_false()
	_store.add("FIRES_PUT_OUT", 3)
	var again := Achievements.new()
	again.path = PATH
	again.load_file()
	assert_bool(again.is_unlocked(&"tycoon")).is_true()
	assert_int(again.count("FIRES_PUT_OUT")).is_equal(3)
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("[[[ isto não é um cfg")
	file.close()
	again.load_file()
	assert_bool(again.unlocked.is_empty()).is_true()


func test_state_achievements_come_from_the_world() -> void:
	var watcher := AchievementWatcher.new(_sim, _store)
	assert_array(watcher.check()).is_empty()
	_sim.world.money = 300000.0
	var fresh := watcher.check()
	assert_array(fresh.map(func(def: AchievementDef) -> StringName: return def.id)).contains([&"tycoon"])
	assert_bool(_store.is_unlocked(&"tycoon")).is_true()
	assert_array(watcher.check()).is_empty()


func test_event_achievements_count_up() -> void:
	var watcher := AchievementWatcher.new(_sim, _store)
	var needed := 0
	for def: AchievementDef in GameData.get_default().achievements:
		if def.id == &"fire_brigade":
			needed = def.amount
	for index: int in needed - 1:
		watcher.on_event(AchievementDef.Kind.FIRES_PUT_OUT)
	assert_bool(_store.is_unlocked(&"fire_brigade")).is_false()
	watcher.on_event(AchievementDef.Kind.FIRES_PUT_OUT)
	assert_bool(_store.is_unlocked(&"fire_brigade")).is_true()
	assert_int(watcher.check().size()).is_equal(1)


func test_scenario_victory_needs_that_scenario() -> void:
	var watcher := AchievementWatcher.new(_sim, _store)
	VictorySystem.start(_sim.world, _sim.config, GoalDef.Kind.MONEY, &"", 1, 0.0, &"island_race")
	watcher.on_event(AchievementDef.Kind.VICTORY)
	assert_bool(_store.is_unlocked(&"first_victory")).is_true()
	assert_bool(_store.is_unlocked(&"won_island_race")).is_true()
	assert_bool(_store.is_unlocked(&"won_poor_colony")).is_false()


func test_free_build_earns_nothing() -> void:
	_sim.free_build = true
	var watcher := AchievementWatcher.new(_sim, _store)
	_sim.world.money = 999999.0
	assert_array(watcher.check()).is_empty()
	assert_bool(_store.unlocked.is_empty()).is_true()
