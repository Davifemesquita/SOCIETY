extends GdUnitTestSuite
## Animais da cidade viva (Fase 13): ovelhas e porcos no pasto da fazenda dona dele, nenhum bicho no
## pasto sem fazenda, um cão na porta de parte das casas e um cavalo na frente de cada carroça.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _view() -> AnimalView:
	var view: AnimalView = auto_free(AnimalView.new())
	add_child(view)
	view.setup(_sim)
	return view


## A fazenda e os pastos que ela pede, em volta dela.
func _farm(def_id: StringName, origin: Vector2i) -> int:
	var farm := SimFixture.place(_sim, def_id, origin, 0)
	var def := _sim.data.building(def_id)
	var reach := Footprint.rect(origin, def.size, 0).grow(def.module_radius_cells)
	var placed := 0
	for y: int in range(reach.position.y, reach.end.y - 2):
		for x: int in range(reach.position.x, reach.end.x - 2):
			if placed < def.modules_required and _sim.execute(PlaceBuildingCommand.new(SimFixture.ISLAND,
					def.module_id, Vector2i(x, y), 0)).ok():
				placed += 1
	assert_int(placed).is_equal(def.modules_required)
	return farm


func test_the_animals_are_baked_with_their_colors() -> void:
	for animal: StringName in [&"sheep", &"pig", &"dog", &"horse"]:
		var model := AnimalView.model(animal)
		assert_object(model).override_failure_message(String(animal)).is_not_null()
		assert_int(model.clip_index("idle")).is_greater_equal(0)
		var arrays := model.mesh.surface_get_arrays(0)
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		assert_int(colors.size()).is_equal(model.vertex_count)
		assert_int(model.triangle_count).is_less_equal(1500)
	assert_int(AnimalView.model(&"horse").clip_index("walk")).is_greater_equal(0)
	# a escala leva o bicho ao tamanho dele no mundo
	var sheep := AnimalView.model(&"sheep")
	var vertices: PackedVector3Array = sheep.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var box := AABB(vertices[0], Vector3.ZERO)
	for vertex: Vector3 in vertices:
		box = box.expand(vertex)
	assert_float(box.size.z * AnimalView.scale_of(&"sheep")).is_equal_approx(AnimalView.LENGTH_M[&"sheep"], 0.01)


func test_sheep_and_pigs_graze_on_the_pastures_of_their_farms() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	_farm(&"sheep_farm", Vector2i(10, 21))
	_farm(&"pig_farm", Vector2i(50, 21))
	# pasto sozinho, longe das fazendas: sem dono, sem bicho
	SimFixture.place(_sim, &"pasture", Vector2i(70, 2), 0)
	var view := _view()
	var sheep_farm := _sim.data.building(&"sheep_farm")
	var pig_farm := _sim.data.building(&"pig_farm")
	assert_int(view.animal_count(&"sheep")).is_equal(sheep_farm.modules_required * AnimalView.PER_PASTURE)
	assert_int(view.animal_count(&"pig")).is_equal(pig_farm.modules_required * AnimalView.PER_PASTURE)
	# todos dentro de um pasto
	var grid := _sim.world.island(SimFixture.ISLAND)
	var layer := view.find_child("Sheep", false, false) as MultiMeshInstance3D
	for i: int in layer.multimesh.visible_instance_count:
		var cell := grid.world_to_cell(layer.multimesh.get_instance_transform(i).origin)
		var record := _sim.world.building(grid.building_at(cell))
		assert_object(record).is_not_null()
		assert_str(String(record.def_id)).is_equal("pasture")


func test_a_dog_waits_by_the_door_of_some_houses() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(79, 10))
	var houses: Array[int] = []
	for i: int in 12:
		houses.append(SimFixture.house(_sim, 2 + i * 3, 10, &"workers", 5.0))
	var view := _view()
	var expected := houses.filter(func(id: int) -> bool: return id % AnimalView.DOG_EVERY == 0).size()
	assert_int(expected).is_greater(0)
	assert_int(view.animal_count(&"dog")).is_equal(expected)
	# fora da casa, olhando para a rua (as casas da fixture olham para +Z)
	var grid := _sim.world.island(SimFixture.ISLAND)
	var layer := view.find_child("Dog", false, false) as MultiMeshInstance3D
	for i: int in layer.multimesh.visible_instance_count:
		var place := layer.multimesh.get_instance_transform(i)
		assert_int(grid.building_at(grid.world_to_cell(place.origin))).is_equal(0)
		assert_float((-place.basis.z.normalized()).dot(Vector3.BACK)).is_greater(0.99)


func test_new_buildings_bring_their_animals_without_rebuilding_by_hand() -> void:
	var view := _view()
	assert_int(view.animal_count()).is_equal(0)
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	_farm(&"sheep_farm", Vector2i(10, 21))
	await await_idle_frame()
	await await_idle_frame()
	assert_int(view.animal_count(&"sheep")).is_greater(0)


## Fase 19: os bichos andam pelo pasto (pastam, viram e caminham até outro ponto), sempre dentro dele; o
## cão anda ao longo da frente da casa. Sem o relógio andar, ninguém sai do lugar.
func test_the_animals_wander_inside_their_pasture_and_the_dog_paces_by_the_door() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	_farm(&"sheep_farm", Vector2i(10, 21))
	var houses: Array[int] = []
	for i: int in 10:
		houses.append(SimFixture.house(_sim, 2 + i * 3, 10, &"workers", 5.0))
	var view := _view()
	var grid := _sim.world.island(SimFixture.ISLAND)
	var count := view.animal_count(&"sheep")
	var start: Array[Vector3] = []
	for i: int in count:
		start.append(view.animal_transform(&"sheep", i).origin)
	view.advance(0.0)
	for i: int in count:
		assert_vector(view.animal_transform(&"sheep", i).origin).is_equal(start[i])
	var moved := 0
	var pastures := {}
	for i: int in count:
		pastures[i] = grid.building_at(grid.world_to_cell(start[i]))
	for second: int in 120:
		view.advance(1.0)
		for i: int in count:
			var origin := view.animal_transform(&"sheep", i).origin
			assert_int(grid.building_at(grid.world_to_cell(origin))).is_equal(pastures[i])
	for i: int in count:
		if view.animal_transform(&"sheep", i).origin.distance_to(start[i]) > 0.5:
			moved += 1
	assert_int(moved).is_greater(count / 2)
	var dogs := view.animal_count(&"dog")
	assert_int(dogs).is_greater(0)
	for i: int in dogs:
		assert_int(grid.building_at(grid.world_to_cell(view.animal_transform(&"dog", i).origin))).is_equal(0)
