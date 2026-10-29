extends GdUnitTestSuite
## Palmas e cota da festa (Fase 84): a animação de ver os fogos (CheerClip) ergue a cabeça e bate as mãos diante do peito,
## fechando a volta sem salto; quem vê a festa usa ela; e a gente a mais na rua na hora dos fogos sai só da ilha da festa.

const BAKER := preload("res://tools/bake_pedestrians.gd")
const STRIDES := [1.4, 1.4, 0.0, 0.0, 0.0]
const NIGHT := 0.0

static var _source: VatBaker.Source
static var _idle: Animation


func before() -> void:
	var root := BAKER.load_gltf(ProjectSettings.globalize_path(
			"res://assets/source/quaternius/Superhero_Male_FullBody.gltf"), true)
	_source = VatBaker.from_scene(root, PackedStringArray(["SuperHero_Male"]))
	root.free()
	_idle = (load(BAKER.CLIPS_PATH) as AnimationLibrary).get_animation("idle")


func _hands(animation: Animation, time: float) -> float:
	var globals := VatBaker.pose(_source, animation, time)
	return globals[_source.bone_index("hand_l")].origin.distance_to(globals[_source.bone_index("hand_r")].origin)


func test_cheer_claps_in_front_of_the_chest_and_looks_up() -> void:
	assert_object(_source).is_not_null()
	var cheer := CheerClip.make(_source, _idle)
	var rest := VatBaker.pose(_source, _idle, 0.0)
	var frame := CheerClip.body_frame(_source, rest)
	var forward: Vector3 = frame[0]
	var up: Vector3 = frame[1]
	var shoulders := rest[_source.bone_index("upperarm_l")].origin.distance_to(rest[_source.bone_index("upperarm_r")].origin)
	# fechadas na palma (começo da batida) e abertas no meio dela
	var beat := _idle.length / CheerClip.CLAPS
	var shut := _hands(cheer, 0.0)
	var open := _hands(cheer, beat * 0.6)
	assert_float(shut).is_less(shoulders * 0.35)
	assert_float(open).is_greater(shut * 2.0)
	# as mãos ficam à frente do peito, não caídas do lado do corpo como na parada
	var posed := VatBaker.pose(_source, cheer, beat * 0.6)
	var chest := (rest[_source.bone_index("upperarm_l")].origin + rest[_source.bone_index("upperarm_r")].origin) * 0.5
	for side: String in ["l", "r"]:
		var hand := posed[_source.bone_index("hand_" + side)].origin
		assert_float((hand - chest).dot(forward)).is_greater(0.1 * shoulders)
		var idle_hand := rest[_source.bone_index("hand_" + side)].origin
		assert_float(hand.dot(up)).is_greater(idle_hand.dot(up))
	# a cabeça olha para cima: a frente dela (o eixo que antes apontava para a frente) sobe
	var head := _source.bone_index("Head")
	var before := rest[head].basis.inverse() * forward
	var raised := (posed[head].basis * before).normalized()
	assert_float(raised.dot(up)).is_greater(sin(0.4))
	# a volta fecha: o fim é o começo
	assert_float(absf(_hands(cheer, _idle.length) - shut)).is_less(0.001)


func test_hands_gap_shuts_fast_and_opens_slow() -> void:
	assert_float(CheerClip.hands_gap(0.0)).is_equal_approx(CheerClip.HANDS_SHUT, 0.0001)
	var beat := 1.0 / CheerClip.CLAPS
	assert_float(CheerClip.hands_gap(beat * 0.5)).is_greater(CheerClip.HANDS_OPEN * 0.8)
	assert_float(CheerClip.hands_gap(beat * 0.999)).is_less(CheerClip.HANDS_SHUT + 0.01)


func _houses(sim: Simulation, island: int, xs: Array) -> void:
	for x: int in xs:
		var result := sim.execute(PlaceBuildingCommand.new(island, &"house", Vector2i(x, 3), 2))
		assert_bool(result.ok()).is_true()
		var record := sim.world.building(result.placed[0])
		record.tier = &"peasants"
		record.residents = 10.0


func _square(sim: Simulation, island: int) -> int:
	var result := sim.execute(PlaceBuildingCommand.new(island, &"fountain_square", Vector2i(40, 7), 0))
	assert_bool(result.ok()).is_true()
	return result.placed[0]


func _festival(sim: Simulation, island: int) -> void:
	sim.world.events_state.enabled = true
	sim.world.events_state.next_edition_tick = 999_999_999
	var event := WorldEvent.new()
	event.def = sim.data.event(&"festival")
	event.def_id = &"festival"
	event.island_id = island
	event.ends_tick = sim.world.tick + 100000
	sim.world.events_state.events.append(event)


func _crowd(sim: Simulation) -> Crowd:
	var strides: Array[PackedFloat32Array] = [PackedFloat32Array(STRIDES), PackedFloat32Array(STRIDES)]
	return Crowd.new(sim, sim.config, strides, 4)


func test_watchers_cheer() -> void:
	var sim := SimFixture.two_islands(Vector2i(60, 30))
	_houses(sim, 0, [12, 16, 20, 24, 28])
	var square := _square(sim, 0)
	_festival(sim, 0)
	var crowd := _crowd(sim)
	crowd.activity_override = 1.0
	var cheering := 0
	for step: int in 400:
		crowd.update(0.5, NIGHT)
		for agent: Crowd.Agent in crowd.agents:
			if agent != null and agent.watching and agent.state == Crowd.State.WAITING:
				assert_int(agent.target_id).is_equal(square)
				assert_bool(agent.clip == Crowd.CLIP_CHEER or agent.clip == Crowd.CLIP_IDLE).is_true()
				cheering += int(agent.clip == Crowd.CLIP_CHEER)
			elif agent != null and agent.state == Crowd.State.WAITING:
				assert_int(agent.clip).is_not_equal(Crowd.CLIP_CHEER)
	assert_int(cheering).is_greater(0)


func test_the_extra_crowd_comes_only_from_the_festival_island() -> void:
	var sim := SimFixture.two_islands(Vector2i(60, 30))
	# a ilha sem festa primeiro: os pedestres dela vêm antes na fila de casa e levariam a cota extra
	_houses(sim, 1, [12, 16, 20, 24, 28])
	_houses(sim, 0, [12, 16, 20, 24, 28])
	_square(sim, 0)
	_festival(sim, 0)
	var crowd := _crowd(sim)
	var quiet_cap := 0
	var worst_quiet := 0
	var best_festive := 0
	for step: int in 300:
		crowd.update(0.5, NIGHT)
		var out := PackedInt32Array([0, 0])
		var total := PackedInt32Array([0, 0])
		for agent: Crowd.Agent in crowd.agents:
			if agent == null or agent.removed or agent.tourist:
				continue
			total[agent.island_id] += 1
			out[agent.island_id] += int(agent.state != Crowd.State.HOME)
		quiet_cap = roundi(total[1] * DayClock.activity(sim.config, NIGHT))
		worst_quiet = maxi(worst_quiet, out[1])
		best_festive = maxi(best_festive, out[0])
	# a ilha sem festa fica na noite de sempre (uma partida a mais entre duas contagens); a da festa enche
	assert_int(worst_quiet).is_less_equal(quiet_cap + 1)
	assert_int(best_festive).is_greater(quiet_cap + 2)
