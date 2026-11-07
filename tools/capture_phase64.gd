extends Node
## Roteiro de verificação visual da Fase 64 (baleias e golfinhos): na semente 1840, a baleia 0 à tona com o esguicho,
## mergulhando com a cauda erguida, e um bando de golfinhos no meio dos saltos. Precisa de GPU; no PC do dono roda na
## área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase64.tscn -- <pasta>

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
	GameScreen.terrain_version = ArchipelagoGenerator.VERSION_V3
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(11.0 - clock.hour(), 24.0)
	game.hud.visible = false
	var marine := game.marine_view
	print("baleias ", marine.whale_count(), " bandos ", marine.pod_count())
	# a baleia 0 sobe no começo do ciclo: 1 s depois, à tona com o esguicho no ar
	marine.advance(1.0 - marine.time())
	await _shot(game, "baleia_tona.png", marine.whale_transform(0).origin, 45.0, 0.6, 0)
	marine.advance(MarineLifeView.WHALE_SURFACE_S + MarineLifeView.WHALE_DIVE_S * 0.7 - 1.0)
	await _shot(game, "baleia_mergulho.png", marine.whale_transform(0).origin, 45.0, 1.4, 0)
	# o golfinho 0 do bando 0 no meio de um salto
	for step: int in 400:
		var pose := marine.dolphin_transform(0)
		if pose.basis.determinant() != 0.0 and pose.origin.y > 0.8:
			break
		marine.advance(0.02)
	await _shot(game, "golfinhos.png", marine.dolphin_transform(0).origin, 18.0, 2.4, 0)
	GameScreen.terrain_version = -1
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float, _unused: int) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = 0.0
	game.camera.apply()
	for frame: int in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
