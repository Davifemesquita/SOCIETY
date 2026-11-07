extends GdUnitTestSuite
## Telhado de tábuas (Fase 303; Fase 350: a parte por classe de SHINGLE_SIXTHS): casas dos operários e artesãos das temperadas ganham o parâmetro de instância
## shingle, e o shader troca as telhas por tábuas cinzentas nas águas, na capa e no beiral; as outras classes, os outros prédios e
## as tropicais ficam com o telhado de antes.

const KIT := "res://shaders/building_kit.gdshader"

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70])
	_config.tropical_island_sizes_cells = PackedInt32Array([50])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))


func _record(id: int, tier: StringName, island_id: int, def_id: StringName = &"house") -> BuildingRecord:
	var record := BuildingRecord.new(id, def_id, island_id, Vector2i.ZERO, 0)
	record.tier = tier
	return record


func _tropical() -> int:
	for index: int in _sim.world.islands.size():
		if _sim.world.is_tropical(index, _sim.data):
			return index
	return -1


func test_part_of_the_temperate_worker_houses_get_shingles() -> void:
	# (Fase 350: dois terços dos operários e um terço dos artesãos)
	var shingled := 0
	var artisans := 0
	for id: int in range(1, 201):
		if BuildingView.shingled(_sim, _record(id, &"workers", 0)):
			shingled += 1
		if BuildingView.shingled(_sim, _record(id, &"artisans", 0)):
			artisans += 1
		# os camponeses (sapê), as classes de cima e as tropicais nunca
		assert_bool(BuildingView.shingled(_sim, _record(id, &"peasants", 0))).is_false()
		assert_bool(BuildingView.shingled(_sim, _record(id, &"engineers", 0))).is_false()
		assert_bool(BuildingView.shingled(_sim, _record(id, &"workers", _tropical()))).is_false()
	assert_int(shingled).is_between(200 * 4 / 6 - 30, 200 * 4 / 6 + 30)
	assert_int(artisans).is_between(200 * 2 / 6 - 30, 200 * 2 / 6 + 30)
	assert_bool(BuildingView.shingled(_sim, _record(1, &"", 0, &"market"))).is_false()


func test_the_shader_draws_boards_on_the_slopes_and_caps() -> void:
	var code := FileAccess.get_file_as_string(KIT)
	assert_str(code).contains("instance uniform float shingle = 0.0;")
	var slopes := code.find("color = shingle_shade(world_position, world_normal, near,")
	assert_int(slopes).is_greater(code.find("} else if (slate > 0.5) {"))
	assert_int(slopes).is_less(code.find("} else if (corrugated > 0.5) {"))
	assert_str(code).contains("} else if (roof && shingle > 0.5) {")
	var view := FileAccess.get_file_as_string("res://presentation/building_view.gd")
	# (Fase 350: o tom cinza ou marrom pelo valor)
	assert_str(view).contains("body.set_instance_shader_parameter(&\"shingle\", shingle_tone(_simulation, record))")


func test_the_shader_compiles_with_the_shingle_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(KIT) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	assert_array(names).is_not_empty()
	for name: StringName in [&"shingle_color", &"shingle_row_m", &"shingle_width_m"]:
		assert_bool(names.has(name)).is_true()
