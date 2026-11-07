extends Node
## Roteiro de verificação visual da Fase 187 (placa na encruzilhada): na semente 1840, duas estradas de terra cruzando no
## campo da ilha principal, longe de casa, e um T ao lado; a placa de perto (a câmera posta à mão) e de meia distância.
## Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase187.tscn -- <pasta>

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
	# um lugar livre e plano para a encruzilhada: o do mercado (3×3) que o SiteFinder achar perto do meio
	var found := SiteFinder.find(sim, &"market", Simulation.MAIN_ISLAND, grid.size / 2)
	var center := grid.size / 2
	if not found.is_empty():
		var origin: Vector2i = found[0]
		center = origin + Vector2i(1, 1)
	for path: Array in [[center + Vector2i(-7, 0), center + Vector2i(7, 0)], [center + Vector2i(0, -7), center + Vector2i(0, 7)],
			[center + Vector2i(7, -5), center + Vector2i(7, 5)]]:
		var from: Vector2i = path[0]
		var to: Vector2i = path[1]
		sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(from, to)))
	await get_tree().process_frame
	game.signpost_view.rebuild()
	print("placas: ", game.signpost_view.post_count())
	var shot := 0
	for post: Transform3D in game.signpost_view.places:
		await _aimed(game, "placa_%d.png" % shot, post.origin + Vector3(0.0, 1.6, 0.0), 4.5, 0.7 + shot * 1.4)
		await _aimed(game, "placa_%d_longe.png" % shot, post.origin + Vector3(0.0, 1.0, 0.0), 16.0, 0.9 + shot * 1.4)
		shot += 1
	get_tree().quit()


## Põe a Camera3D à mão, um pouco acima do ponto, a distance metros dele no rumo yaw (o offset da câmera é (sen, ·, cos)).
func _aimed(game: GameScreen, file_name: String, at: Vector3, distance: float, yaw: float) -> void:
	game.camera.set_process(false)
	var eye := at + Vector3(sin(yaw), 0.35, cos(yaw)).normalized() * distance
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
