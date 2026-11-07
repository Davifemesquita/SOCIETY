extends Node
## Roteiro de verificação visual da Fase 51 (fotos e retratos nos menus): os cartões com foto no menu de construção
## (residências e uma aba de produção), o painel de uma casa (foto da classe e retrato) e de uma fábrica, a aba de
## população com os retratos e o conselheiro. Precisa de GPU; no PC do dono, na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase51.tscn -- <pasta>

var _out_dir: String
var _game: GameScreen


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	Settings.edge_pan = false
	Settings.reduce_motion = true
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	var sim := _game.simulation
	sim.free_build = true
	await _shot("conselheiro.png")
	_game.hud.goal_panel.visible = false
	sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(60, 40), Vector2i(90, 40))))
	var house := sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(62, 37), 2)).placed[0]
	sim.world.building(house).tier = &"artisans"
	sim.world.building(house).residents = 25.0
	var bakery := sim.execute(PlaceBuildingCommand.new(0, &"bakery", Vector2i(70, 41), 0)).placed[0]
	_game.building_view.rebuild()
	await _shot("menu_residencias.png")
	_game.hud.call(&"_select_category", 2)
	await _shot("menu_producao.png")
	_game.tool.select(house)
	_game.center_on_selected()
	await _shot("painel_casa.png")
	_game.tool.select(bakery)
	await _shot("painel_fabrica.png")
	_game.tool.select(0)
	var stats := _game.hud.statistics_window
	stats.toggle()
	var tabs := (stats.find_child("Population", true, false) as Control).get_parent() as TabContainer
	tabs.current_tab = 1
	await _shot("populacao.png")
	get_tree().quit()


func _shot(file_name: String) -> void:
	for frame: int in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
