extends Node
## Roteiro de verificação visual da Fase 2 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 res://tools/capture_phase2.tscn -- <pasta>
## Monta uma vila no litoral norte (pesca, lã, mercado, madeira e a cadeia do pão), deixa a
## economia rodar 30 minutos de jogo e captura a vila, os painéis, as estatísticas e os destaques.

const MINUTES := 30

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _place(def_id: StringName, origin: Vector2i, rotation: int = 0) -> int:
	var result := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
	return result.placed[0] if result.ok() else 0


func _road(from: Vector2i, to: Vector2i) -> void:
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(from, to)))


func _farm(def_id: StringName, origin: Vector2i) -> int:
	var farm := _place(def_id, origin)
	var def := _sim.data.building(def_id)
	var reach := Footprint.rect(origin, def.size, 0).grow(def.module_radius_cells)
	var placed := 0
	for y: int in range(reach.position.y, reach.end.y - 2):
		for x: int in range(reach.position.x, reach.end.x - 2):
			if placed < def.modules_required and _place(def.module_id, Vector2i(x, y)) != 0:
				placed += 1
	return farm


func _build_village() -> Dictionary:
	_sim.free_build = true
	_road(Vector2i(40, 3), Vector2i(170, 3))
	_road(Vector2i(60, 3), Vector2i(60, 40))
	_road(Vector2i(60, 12), Vector2i(150, 12))
	_road(Vector2i(60, 26), Vector2i(150, 26))
	_road(Vector2i(60, 40), Vector2i(150, 40))
	_place(&"fishery", Vector2i(70, 0), 2)
	_place(&"fishery", Vector2i(80, 0), 2)
	var market := _place(&"market", Vector2i(100, 13), 0)
	var houses: Array[int] = []
	for x: int in range(62, 146, 3):
		houses.append(_place(&"house", Vector2i(x, 9), 2))
	for x: int in range(62, 98, 3):
		houses.append(_place(&"house", Vector2i(x, 13), 0))
	_place(&"tavern", Vector2i(130, 13), 0)
	_place(&"lumberjack", Vector2i(62, 23), 2)
	_place(&"lumberjack", Vector2i(66, 23), 2)
	_place(&"sawmill", Vector2i(70, 22), 2)
	_place(&"weavery", Vector2i(75, 22), 2)
	_place(&"mill", Vector2i(90, 22), 2)
	var bakery := _place(&"bakery", Vector2i(110, 22), 2)
	_place(&"bakery", Vector2i(116, 22), 2)
	_place(&"school", Vector2i(140, 13), 0)
	# fazendas por último: os campos e pastos ocupam o que sobra em volta
	var sheep := _farm(&"sheep_farm", Vector2i(80, 27))
	var wheat := [_farm(&"wheat_farm", Vector2i(100, 27)), _farm(&"wheat_farm", Vector2i(124, 27))]
	_sim.free_build = false
	_sim.world.economy(0).stock[&"planks"] = 50.0
	return {"market": market, "houses": houses, "sheep": sheep, "wheat": wheat, "bakery": bakery}


func _run() -> void:
	_sim = _game.simulation
	var village := _build_village()
	var started := Time.get_ticks_msec()
	_sim.run_ticks(roundi(MINUTES * 60.0 / _sim.config.tick_interval()))
	print("%d min de jogo simulados em %.1f s" % [MINUTES, (Time.get_ticks_msec() - started) / 1000.0])
	var report := _sim.statistics()
	print("população: %s · dinheiro %d · saldo %+.0f/min" % [report.population, _sim.world.money, report.balance_per_min()])
	for good: StringName in [&"fish", &"woolen_clothes", &"planks", &"wheat", &"flour", &"bread"]:
		var line := report.line(good)
		print("  %s: produção %.2f / potencial %.2f / consumo %.2f / estoque %.1f t" % [good, line.produced, line.potential, line.consumed(), line.stock])
	var rig := _game.camera.rig
	rig.focus = Vector3(205, 0, 40)
	rig.distance = 150.0
	_game.camera.apply()
	await _settle()
	await _capture("01_vila.png")
	rig.rotate_quarter(1)
	await _settle()
	await _capture("02_vila_girada.png")
	rig.rotate_quarter(-1)
	var houses: Array[int] = village["houses"]
	_game.tool.select(houses[5])
	await _settle()
	await _capture("03_painel_casa.png")
	var bakery: int = village["bakery"]
	_game.tool.select(bakery)
	await _settle()
	await _capture("04_painel_padaria.png")
	var market: int = village["market"]
	_game.tool.select(market)
	await _settle()
	await _capture("05_alcance_mercado.png")
	_game.tool.select(0)
	_game.hud.toggle_statistics()
	await _settle()
	await _capture("06_estatisticas.png")
	_game.hud.toggle_statistics()
	_game.tool.start_building(_sim.data.building(&"wheat_farm"))
	_game.tool.hover(Vector2i(140, 30))
	await _settle()
	await _capture("07_fazenda_area_campos.png")
	_game.tool.cancel()
	_game.hud._select_category(2)
	await _settle()
	await _capture("08_menu_operarios.png")
	get_tree().quit()


func _settle() -> void:
	for frame: int in 30:
		await get_tree().process_frame


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
