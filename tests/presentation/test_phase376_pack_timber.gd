extends GdUnitTestSuite
## Fase 376: com o MegaKit, o madeiramento gerado (as vigas dos pisos, o enxaimel saliente, a varanda) vai para a madeira do
## pacote (UV2.x = 2) e sai da célula UV_TIMBER da paleta; sem o MegaKit tudo segue na paleta.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func after_test() -> void:
	BuildingKit.reset_megakit()


func _house(tier: StringName, jetty: bool) -> BuildingKit.Spec:
	var record := BuildingRecord.new(5, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	var spec := BuildingKit.spec_for(_sim, record, 2.0)
	spec.roof = BuildingKit.Roof.GABLE_X
	spec.wing = 0
	spec.awning = 0
	spec.jetty = jetty
	return spec


## [vértices na célula UV_TIMBER fora do pacote, vértices na madeira do pacote]
func _counts(spec: BuildingKit.Spec) -> Array[int]:
	var cell := Vector2i(floori(BuildingKit.UV_TIMBER.x * 8.0), floori(BuildingKit.UV_TIMBER.y * 4.0))
	var palette := 0
	var packed := 0
	var mesh := BuildingKit.mesh(spec)
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var uv2 := PackedVector2Array()
		if arrays[Mesh.ARRAY_TEX_UV2] is PackedVector2Array:
			uv2 = arrays[Mesh.ARRAY_TEX_UV2]
		for i: int in uvs.size():
			if not uv2.is_empty() and uv2[i].x > 0.5:
				packed += int(is_equal_approx(uv2[i].x, 2.0))
			elif Vector2i(floori(uvs[i].x * 8.0), floori(uvs[i].y * 4.0)) == cell:
				palette += 1
	return [palette, packed]


func test_the_jetty_timber_takes_the_pack_wood() -> void:
	BuildingKit.use_megakit(true)
	var plain := _counts(_house(&"workers", false))
	var jettied := _counts(_house(&"workers", true))
	assert_int(jettied[1]).is_greater(plain[1])
	# nenhuma viga do balanço nem esteio a mais na paleta
	assert_int(jettied[0]).is_equal(plain[0])


func test_the_kenney_keeps_the_palette() -> void:
	BuildingKit.use_megakit(false)
	var plain := _counts(_house(&"workers", false))
	var jettied := _counts(_house(&"workers", true))
	assert_int(jettied[0]).is_greater(plain[0])
	assert_int(jettied[1]).is_equal(0)
