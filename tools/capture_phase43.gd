extends Node
## Roteiro de verificação visual da Fase 43: a HUD da partida (ilha plana, a aba do porto aberta e um aviso repetido) em
## 80, 100, 150 e 200% de escala, na resolução da janela. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 2560x1440 --quit-after 20000 res://tools/capture_phase43.tscn -- <pasta>
## Os arquivos levam a resolução e a escala no nome (hud_2560x1440_150.png).

const SCALES: Array[float] = [0.8, 1.0, 1.5, 2.0]

var _out_dir: String
var _game: GameScreen


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	var hud := _game.hud
	hud._select_category(hud._categories().size() - 2)
	var notice := NoticeWatcher.Notice.new("shortage/0/fish", "notice_shortage", "NOTICE_SHORTAGE", ["peixe", "Ilha 1"])
	for i: int in 3:
		hud.notifications.push(notice)
	var before := Settings.ui_scale
	var size := DisplayServer.window_get_size()
	for scale: float in SCALES:
		Settings.ui_scale = scale
		Settings.apply()
		for frame: int in 20:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var file := "hud_%dx%d_%d.png" % [size.x, size.y, roundi(scale * 100.0)]
		get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file))
		print("capturado ", file)
	Settings.ui_scale = before
	Settings.apply()
	get_tree().quit()
