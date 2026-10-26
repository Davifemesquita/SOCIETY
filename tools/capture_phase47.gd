extends Node
## Roteiro de verificação visual da Fase 47 (QoL de interface), na ilha plana: a busca no menu de construção, o painel
## com copiar, próximo igual e estatística, a janela de estatísticas com a dica que decompõe o pão aberta, a janela de
## rotas com o filtro, o duplicar e uma rota em destaque no mapa, e o modo foto (com o painel e depois limpo, ao
## entardecer). Precisa de GPU; no PC do dono roda na área de trabalho escondida (F:\ferramentas\desktop_oculto.ps1):
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase47.tscn -- <pasta>

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
	var sim := _game.simulation
	sim.free_build = true
	sim.config.instant_logistics = true
	_town(sim)
	_game.hud.goal_panel.visible = false
	for frame: int in 10:
		await get_tree().process_frame
	_game.hud.search("pa")
	await _shot("busca.png")
	_game.hud.search("")
	var bakery := sim.world.island(0).building_at(Vector2i(66, 21))
	_game.tool.select(bakery)
	_game.center_on_selected()
	await _shot("painel.png")
	_game.tool.select(0)
	_game.hud.statistics_window.show_good(&"bread", 0)
	await _shot("estatisticas.png")
	# a dica que decompõe, aberta como o Godot abriria no hover (o mesmo controle, posto ao lado do rótulo)
	var label := _game.hud.statistics_window.find_child("Good_bread", true, false) as BreakdownLabel
	if label != null:
		var tip := label._make_custom_tooltip("") as Control
		var panel := PanelContainer.new()
		panel.theme_type_variation = &"TooltipPanel"
		panel.add_child(tip)
		_game.hud.add_child(panel)
		panel.global_position = label.get_global_rect().end + Vector2(12, 0)
		await _shot("dica_pao.png")
		panel.queue_free()
		var money := _game.hud.statistics_window.find_child("FinanceLine", true, false) as BreakdownLabel
		var tabs := (_game.hud.statistics_window.find_child("Finances", true, false) as Control).get_parent() as TabContainer
		tabs.current_tab = 2
		await _shot("financas.png")
		if money != null:
			var money_tip := money._make_custom_tooltip("") as Control
			var money_panel := PanelContainer.new()
			money_panel.theme_type_variation = &"TooltipPanel"
			money_panel.add_child(money_tip)
			_game.hud.add_child(money_panel)
			money_panel.global_position = money.get_global_rect().position + Vector2(0, 40)
			await _shot("dica_dinheiro.png")
			money_panel.queue_free()
	_game.hud.statistics_window.visible = false
	var routes := _game.hud.route_window
	routes.toggle()
	routes.create_route()
	routes.add_stop_to_route()
	routes.add_stop_to_route()
	routes.add_order(routes.stops()[0], true)
	routes.duplicate_route()
	routes.hover_route(sim.world.route_ids()[0])
	await _shot("rotas.png")
	routes.visible = false
	_game.photo_mode.toggle()
	_game.photo_mode.set_hour(18.5)
	_game.camera.rig.distance = 70.0
	_game.camera.apply()
	await _shot("foto_com_painel.png")
	# o painel some sozinho depois de HIDE_AFTER_S sem mexer o mouse
	_game.photo_mode._idle = PhotoMode.HIDE_AFTER_S + 1.0
	await _shot("foto_limpa.png")
	_game.photo_mode.toggle()
	get_tree().quit()


## Uma vila pequena: a cadeia do pão, casas e um porto (para a rota e o navio).
func _town(sim: Simulation) -> void:
	sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(0, 20), Vector2i(139, 20))))
	for x: int in [8, 34]:
		sim.execute(PlaceBuildingCommand.new(0, &"wheat_farm", Vector2i(x, 21), 0))
	sim.execute(PlaceBuildingCommand.new(0, &"mill", Vector2i(60, 21), 0))
	sim.execute(PlaceBuildingCommand.new(0, &"bakery", Vector2i(66, 21), 0))
	sim.execute(PlaceBuildingCommand.new(0, &"bakery", Vector2i(72, 21), 0))
	for i: int in 6:
		var placed := sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(80 + i * 3, 17), 2))
		if placed.ok():
			var house := sim.world.building(placed.placed[0])
			house.tier = &"peasants" if i < 3 else &"workers"
			house.residents = 10.0 if i < 3 else 20.0
	sim.world.economy(0).stock[&"fish"] = 200.0
	sim.run_ticks(sim.config.ticks_per_second * 120)
	# as fazendas daqui não têm campos: a produtividade média posta à mão, para a dica do pão ter números
	for building_id: int in sim.derived_state().production:
		sim.world.building(building_id).productivity = 0.8 if building_id % 2 == 0 else 1.0


func _shot(file_name: String) -> void:
	for frame: int in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
