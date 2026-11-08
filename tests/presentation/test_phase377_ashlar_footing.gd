extends GdUnitTestSuite
## Fase 377: com o MegaKit, o alicerce no pé do prédio, o plinto do barranco e os degraus da porta saem na cantaria do pacote
## (UV2.x = 5), em escala de verdade; sem o MegaKit seguem na pedra lisa da paleta.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(40, 40))


func after_test() -> void:
	BuildingKit.reset_megakit()


func _spec(tier: StringName) -> BuildingKit.Spec:
	var record := BuildingRecord.new(7, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


## Os vértices da cantaria do pacote abaixo de "below" e as UVs deles.
func _ashlar(mesh: Mesh, below: float) -> PackedVector2Array:
	var found := PackedVector2Array()
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		if not arrays[Mesh.ARRAY_TEX_UV2] is PackedVector2Array:
			continue
		var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i: int in uv2s.size():
			if is_equal_approx(uv2s[i].x, 5.0) and vertices[i].y < below:
				found.append(uvs[i])
	return found


func test_the_footing_is_ashlar_with_the_megakit() -> void:
	BuildingKit.use_megakit(true)
	var uvs := _ashlar(BuildingKit.mesh(_spec(&"workers")), BuildingKit.FOUNDATION_UP_M + 0.01)
	assert_int(uvs.size()).is_greater(0)
	# nas fiadas aparelhadas da textura
	for uv: Vector2 in uvs:
		assert_float(uv.y).is_between(BuildingKit.MEGAKIT_ASHLAR_V.x - 0.001, BuildingKit.MEGAKIT_ASHLAR_V.y + 0.001)


func test_the_plinth_and_steps_are_ashlar() -> void:
	BuildingKit.use_megakit(true)
	var spec := _spec(&"artisans")
	var mesh := BuildingKit.plinth(spec, 3.0, 1.2)
	var uvs := _ashlar(mesh, 1.0)
	assert_int(uvs.size()).is_greater(0)
	# a face de 3 m de altura vem em faixas: nenhuma UV passa da última fiada
	for uv: Vector2 in uvs:
		assert_float(uv.y).is_less_equal(BuildingKit.MEGAKIT_ASHLAR_V.y + 0.001)


func test_the_kenney_keeps_the_plain_stone() -> void:
	BuildingKit.use_megakit(false)
	var spec := _spec(&"artisans")
	assert_int(_ashlar(BuildingKit.plinth(spec, 3.0, 1.2), 1.0).size()).is_equal(0)
	assert_int(_ashlar(BuildingKit.mesh(spec), 1.0).size()).is_equal(0)
