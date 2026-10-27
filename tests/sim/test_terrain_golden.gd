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
	var world := ArchipelagoGenerator.new_world(1840, GameConfig.get_default(), GameData.get_default(), -1, -1, 1)
	assert_array(_fingerprints(world)).is_equal(V1_SEED_1840)


func test_v1_small_archipelagos_keep_their_fingerprints() -> void:
	var config := _small_config()
	var data := GameData.get_default()
	for seed_value: int in V1_SMALL:
		var world := ArchipelagoGenerator.new_world(seed_value, config, data, -1, -1, 1)
		assert_array(_fingerprints(world)).override_failure_message("semente %d" % seed_value).is_equal(V1_SMALL[seed_value])


func test_v0_flat_island_keeps_its_fingerprint() -> void:
	var simulation := Simulation.new(GameConfig.get_default(), GameData.get_default())
	assert_int(simulation.world.terrain_version).is_equal(0)
	assert_int(ArchipelagoGenerator.fingerprint(simulation.world.island(0))).is_equal(V0_FLAT)


## Fase 45: o v2, gravado na fase em que entrou — provisório até o dono aprovar a forma pela prévia. Mudou de propósito
## (um número do TerrainV2Params ou o algoritmo), regrave e diga no registro que os saves v2 de antes refazem outro mapa.
## Regravadas na Fase 47: o seno, o cosseno e a potência do v2 passaram ao DetMath (as de antes só valiam no Windows; o
## CI, no Linux, achava outras). Conferidas iguais no Windows e no Linux (WSL).
const V2_SEED_1840: Array[int] = [2416620335, 1269248779, 133699629, 2547657075, 1997851754, 3452346283, 1737728329,
		1469169662]
const V2_SMALL: Dictionary[int, Array] = {
	1: [1498920321, 3013886534, 1543284774, 1891576992, 4135802540],
	7: [1263080395, 3798312591, 2885263031, 3872454351, 3844956388],
	2026: [4023742354, 2818023564, 1461733098, 3234505744, 3792402598],
	999999: [2614906438, 150869837, 320615659, 4008049540, 1490233757],
}


func test_v2_seed_1840_keeps_its_fingerprints() -> void:
	var world := ArchipelagoGenerator.new_world(1840, GameConfig.get_default(), GameData.get_default(), -1, -1, 2)
	assert_array(_fingerprints(world)).is_equal(V2_SEED_1840)


func test_v2_small_archipelagos_keep_their_fingerprints() -> void:
	var config := _small_config()
	for seed_value: int in V2_SMALL:
		var world := ArchipelagoGenerator.new_world(seed_value, config, GameData.get_default(), -1, -1, 2)
		assert_array(_fingerprints(world)).override_failure_message("semente %d" % seed_value).is_equal(V2_SMALL[seed_value])

## Fase 52: o v3 (ilhas alongadas, enseadas, falésias, rochedos), gravado na fase em que entrou e conferido igual no
## Windows e no Linux (WSL). Mudou de propósito (um número do TerrainV3Params ou o algoritmo), regrave e diga no registro
## que os saves v3 de antes refazem outro mapa. Regravadas na Fase 53 (a falésia desce em 1,6 célula, não 0,8).
const V3_SEED_1840: Array[int] = [3367206289, 1450471548, 3766615438, 2352703255, 2902494946, 3964152210, 1566865390,
		1505054608]
const V3_SMALL: Dictionary[int, Array] = {
	1: [2039150493, 1662957455, 3768358827, 3250197690, 1120289341],
	7: [1628227579, 4173651663, 1513721506, 233982599, 2161096221],
	2026: [502928890, 77928081, 4188060032, 1516317686, 3298660580],
	999999: [2433594250, 101362162, 3752159171, 2564319341, 1377263279],
}

func test_v3_seed_1840_keeps_its_fingerprints() -> void:
	var world := ArchipelagoGenerator.new_world(1840, GameConfig.get_default(), GameData.get_default(), -1, -1, 3)
	assert_array(_fingerprints(world)).is_equal(V3_SEED_1840)


func test_v3_small_archipelagos_keep_their_fingerprints() -> void:
	var config := _small_config()
	for seed_value: int in V3_SMALL:
		var world := ArchipelagoGenerator.new_world(seed_value, config, GameData.get_default(), -1, -1, 3)
		assert_array(_fingerprints(world)).override_failure_message("semente %d" % seed_value).is_equal(V3_SMALL[seed_value])