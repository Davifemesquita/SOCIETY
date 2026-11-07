extends GdUnitTestSuite
## Franja em tufos (Fase 320): a franja da Fase 312 deixa de ser um pente de folhas iguais e paralelas. As folhas saem em TUFTS
## tufos, cada um abrindo em leque, de comprimento, largura e tom diferentes; a malha é a mesma a cada vez; os pedaços saem um
## pouco girados, sem perder o rumo da queda.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([160])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))


func test_the_blades_come_in_fanned_tufts() -> void:
	var blades := CliffFringeView.tuft_blades()
	assert_int(blades.size()).is_equal(CliffFringeView.TUFTS * CliffFringeView.BLADES_PER_TUFT)
	for t: int in CliffFringeView.TUFTS:
		var lowest := INF
		var highest := -INF
		for b: int in CliffFringeView.BLADES_PER_TUFT:
			var heading: Vector3 = blades[t * CliffFringeView.BLADES_PER_TUFT + b][&"heading"]
			# todas para fora da queda
			assert_float(heading.z).is_greater(0.3)
			var angle := atan2(heading.x, heading.z)
			lowest = minf(lowest, angle)
			highest = maxf(highest, angle)
		# o leque: as folhas de um tufo não são paralelas
		assert_float(highest - lowest).override_failure_message("tufo %d" % t).is_greater(0.6)


func test_the_blades_differ_in_length_width_and_tone() -> void:
	var reaches: Array[float] = []
	var halves: Array[float] = []
	var tones: Array[float] = []
	for blade: Dictionary in CliffFringeView.tuft_blades():
		reaches.append(blade[&"reach"])
		halves.append(blade[&"half"])
		var color: Color = blade[&"color"]
		tones.append(color.r + color.g)
	assert_float(reaches.max() - reaches.min()).is_greater(0.3)
	assert_float(halves.max() - halves.min()).is_greater(0.01)
	assert_float(tones.max() - tones.min()).is_greater(0.15)


func test_the_mesh_is_the_same_every_time() -> void:
	var first := CliffFringeView.tuft_blades()
	var second := CliffFringeView.tuft_blades()
	assert_bool(first == second).is_true()
	# ainda pende para fora (Fase 312) e não passa muito dos lados do pedaço
	var box := CliffFringeView.fringe_mesh().get_aabb()
	assert_float(box.end.z).is_greater(0.5)
	assert_float(box.position.y).is_less(-0.1)
	assert_float(box.size.x).is_between(0.9, 1.2)


func test_pieces_are_turned_a_little_but_keep_facing_the_drop() -> void:
	var places := CliffFringeView.places_of(_sim.world, _config, 0)
	assert_int(places.size()).is_greater(20)
	var turned := 0
	for place: Transform3D in places:
		var out := place.basis.z.normalized()
		var axis := Vector3(roundf(out.x), 0.0, roundf(out.z))
		var off := out.angle_to(axis)
		assert_float(off).is_less_equal(CliffFringeView.YAW_JITTER_RAD + 0.001)
		if off > 0.05:
			turned += 1
		# de pé
		assert_float(place.basis.y.normalized().y).is_greater(0.99)
	# a maioria sai girada: a fileira não fica numa régua só
	assert_int(turned).is_greater(places.size() / 2)
