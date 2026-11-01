extends Node
## Roteiro de verificação visual da Fase 182 (galo do cata-vento): na semente 1840, uma fazenda de trigo, uma de ovelhas e uma
## de porcos na ilha principal (achadas pelo SiteFinder), com o galo no alto da cumeeira; a câmera posta à mão no alto do
## telhado (a da partida fica presa ao chão), de perto e de longe. Precisa de GPU; no PC do dono roda na área de trabalho
## escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase182.tscn -- <pasta>

const SEED := 1840

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	_set_hour(10.0)
	game.hud.visible = false
	var sim := game.simulation
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	sim.free_build = true
	var near := grid.size / 2
	for def_id: StringName in [&"wheat_farm", &"sheep_farm", &"pig_farm"]:
		var found := SiteFinder.find(sim, def_id, Simulation.MAIN_ISLAND, near)
		if found.is_empty():
			continue
		var origin: Vector2i = found[0]
		var rotation: int = found[1]
		# as fazendas caem às vezes numa mata: derruba as árvores em volta, para ver o telhado
		var area := Footprint.rect(origin, sim.data.building(def_id).size, rotation)
		var clearing := area.grow(8)
		var felled: Array[Vector2i] = []
		for y: int in range(clearing.position.y, clearing.end.y):
			for x: int in range(clearing.position.x, clearing.end.x):
				if grid.in_bounds(Vector2i(x, y)):
					felled.append(Vector2i(x, y))
		if grid.clear_trees(felled):
			EventBus.trees_changed.emit(Simulation.MAIN_ISLAND, clearing)
		sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
		near = origin + Vector2i(10, 0)
	await get_tree().process_frame
	game.weathercock_view.rebuild()
	print("galos: ", game.weathercock_view.cock_count())
	var shot := 0
	for spot: Vector3 in game.weathercock_view.spots:
		await _aimed(game, "galo_%d.png" % shot, spot + Vector3(0.0, 0.8, 0.0), 4.0, 0.6 + shot * 1.9)
		await _aimed(game, "galo_%d_telhado.png" % shot, spot, 14.0, 0.9 + shot * 1.9)
		shot += 1
	get_tree().quit()


## Põe a Camera3D à mão, um pouco acima do ponto, a distance metros dele no rumo yaw (o offset da câmera é (sen, ·, cos)).
func _aimed(game: GameScreen, file_name: String, at: Vector3, distance: float, yaw: float) -> void:
	game.camera.set_process(false)
	var eye := at + Vector3(sin(yaw), 0.45, cos(yaw)).normalized() * distance
	game.camera.camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
	for frame: int in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
	game.camera.set_process(true)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
