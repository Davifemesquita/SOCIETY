extends Node
## Roteiro de verificação visual da Fase 196 (patos na água): na semente 1840, uma família (a pata com os patinhos) e um
## bando de patos nadando em roda na água rasa da costa, às 9h. Precisa de GPU; no PC do dono roda na área de trabalho
## escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase196.tscn -- <pasta>

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
	_set_hour(9.0)
	game.hud.visible = false
	for frame: int in 5:
		await get_tree().process_frame
	var ducks := game.duck_view
	print("bandos ", ducks.flocks_now.size(), " patos ", ducks.duck_count())
	var family: DuckView.Flock = null
	var adults: DuckView.Flock = null
	for flock: DuckView.Flock in ducks.flocks_now:
		if flock.kinds.has(DuckView.Duck.DUCKLING):
			if family == null:
				family = flock
		elif adults == null and flock.kinds.has(DuckView.Duck.DRAKE):
			adults = flock
	# um pato de cada bando mergulhando a cabeça
	ducks.advance(4.0)
	if family != null:
		await _shot(game, "patos_familia.png", family.center, 9.0, 0.6)
		await _shot(game, "patos_familia_longe.png", family.center, 26.0, 2.2)
	if adults != null:
		await _shot(game, "patos_bando.png", adults.center, 9.0, 4.0)
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = maxf(game.simulation.world.surface_height(focus.x, focus.z), 0.0)
	game.camera.apply()
	for frame: int in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
