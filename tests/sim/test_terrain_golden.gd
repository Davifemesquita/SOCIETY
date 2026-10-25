extends GdUnitTestSuite
## Fase 32: a assinatura do terreno de cada versão do gerador fica gravada aqui. O save refaz o terreno pela semente e
## confere a assinatura; se ela mudar, todo save antigo abre com terrain_mismatch. Este teste falha antes disso:
## quando o gerador muda sem subir ArchipelagoGenerator.VERSION, quando um ajuste no GameConfig mexe no relevo do v1
## (os patamares leem terrace_levels_m e terrace_flat_fraction) ou quando o motor muda o FastNoiseLite ou o hash().
## Mudança de propósito no gerador vira versão nova, com as assinaturas dela gravadas à parte; estas não mudam.

## v1, arquipélago padrão da semente do benchmark e das capturas: as 8 ilhas, na ordem do mundo.
const V1_SEED_1840: Array[int] = [1060486434, 694057621, 564538245, 848173728, 1467662185, 1989953138, 4148489170,
		867371288]
## v1 no arquipélago pequeno de _small_config, mais sementes em menos tempo.
const V1_SMALL: Dictionary[int, Array] = {
	1: [2466358484, 2478773186, 2082799911, 162790976, 2003374538],
	7: [2088712756, 3323589347, 3876217617, 3676110068, 2927762452],
	2026: [3310059599, 2060445528, 1600658934, 1669520624, 3074541662],
	999999: [3377939527, 472627424, 599751401, 255443132, 1817527836],
}
## v0: a ilha plana dos testes e dos saves de antes da Fase 5 (o save guarda 0 nela, mas a grade tem de continuar igual).
const V0_FLAT := 1645297472


func _small_config() -> GameConfig:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([70, 40, 30])
	config.tropical_island_sizes_cells = PackedInt32Array([30, 20])
	return config


func _fingerprints(world: WorldState) -> Array[int]:
	var found: Array[int] = []
	for index: int in world.islands.size():
		found.append(world.island(index).fingerprint)
	return found


func test_generator_version_is_still_one() -> void:
	# subiu a versão: grave as assinaturas da nova num teste dela e deixe as do v1 aqui
	assert_int(ArchipelagoGenerator.VERSION).is_equal(1)


func test_v1_seed_1840_keeps_its_fingerprints() -> void:
	var world := ArchipelagoGenerator.new_world(1840, GameConfig.get_default(), GameData.get_default())
	assert_array(_fingerprints(world)).is_equal(V1_SEED_1840)


func test_v1_small_archipelagos_keep_their_fingerprints() -> void:
	var config := _small_config()
	var data := GameData.get_default()
	for seed_value: int in V1_SMALL:
		var world := ArchipelagoGenerator.new_world(seed_value, config, data)
		assert_array(_fingerprints(world)).override_failure_message("semente %d" % seed_value).is_equal(V1_SMALL[seed_value])


func test_v0_flat_island_keeps_its_fingerprint() -> void:
	var simulation := Simulation.new(GameConfig.get_default(), GameData.get_default())
	assert_int(simulation.world.terrain_version).is_equal(0)
	assert_int(ArchipelagoGenerator.fingerprint(simulation.world.island(0))).is_equal(V0_FLAT)
