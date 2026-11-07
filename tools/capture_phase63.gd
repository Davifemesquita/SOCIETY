extends Node
## Roteiro de verificação visual da Fase 63 (jornal): na semente 1840, a janela das encomendas com uma edição publicada
## (manchete de notícia) e depois com a propaganda comprada. Precisa de GPU; no PC do dono roda na área de trabalho
## escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase63.tscn -- <pasta>

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
	var sim := game.simulation
	var state := sim.world.events_state
	state.enabled = true
	state.edition_count = 1
	state.next_edition_tick = sim.world.tick + sim.config.ticks_of(sim.config.newspaper_interval_s * 0.7)
	state.headline = sim.data.headline(&"price_rumor")
	state.headline_id = state.headline.id
	game.hud.toggle_missions()
	await _shot("jornal_noticia.png")
	sim.execute(BuyPropagandaCommand.new(&"progress"))
	await _shot("jornal_propaganda.png")
	GameScreen.terrain_version = -1
	get_tree().quit()


func _shot(file_name: String) -> void:
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
