extends Node
## Roteiro de verificação visual da Fase 12 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 9000 res://tools/capture_phase12.tscn -- <pasta>
## O menu principal com cenários e conquistas, a janela dos cenários, a das conquistas, o jogo novo com
## objetivo e prazo, e na partida o objetivo no painel das metas e a tela de vitória. As conquistas usam
## um arquivo à parte (não mexe no do jogador).

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var store := Achievements.new()
	store.path = "user://capture_achievements.cfg"
	store.unlock(&"tycoon")
	store.unlock(&"first_investor")
	store.unlock(&"won_poor_colony")
	Achievements.use(store)
	_run.call_deferred()


func _run() -> void:
	var boot := (load("res://ui/screens/boot_screen.tscn") as PackedScene).instantiate() as Control
	add_child(boot)
	await _shot("01_menu_principal.png")
	var scenarios: ScenarioDialog = boot.call(&"open_scenarios")
	await _shot("02_cenarios.png")
	scenarios.closed.emit()
	boot.call(&"open_achievements")
	await _shot("03_conquistas.png")
	for child: Node in boot.find_children("Modal_*", "", true, false):
		(child as Modal).close()
	var dialog: NewGameDialog = boot.call(&"open_new_game")
	dialog.objective_option.select(2)
	dialog.objective_option.item_selected.emit(2)
	dialog.deadline_option.select(2)
	await _shot("04_jogo_novo_com_objetivo.png")
	boot.queue_free()
	GameScreen.flat_world = true
	GameScreen.use_sky3d = false
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	var sim := game.simulation
	DemoVillage.build(sim)
	VictorySystem.start(sim.world, sim.config, GoalDef.Kind.MONEY, &"", 250000, 240.0)
	sim.run_ticks(sim.config.ticks_of(60.0))
	await _shot("05_objetivo_no_painel.png")
	sim.world.money = 300000.0
	sim.run_ticks(sim.config.goal_check_ticks)
	await _shot("06_vitoria.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://capture_achievements.cfg"))
	get_tree().quit()


func _shot(file_name: String) -> void:
	for frame: int in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
