extends Node
## Fase 51: a "foto" de cada prédio para os menus (no espírito dos cartões ilustrados do Anno 1800, mas dos nossos
## modelos): um prédio por vez na ilha plana, com tudo o que o mapa desenha em volta (os campos da fazenda, o quintal,
## a rua na frente), às 16h30, de três quartos e da frente, sem interface nem ícones. O quadro é recortado em 4:3,
## reduzido para PHOTO_SIZE e ganha o acabamento de pintura (PhotoGrade). As casas saem uma por classe.
## Precisa de GPU; no PC do dono roda na área de trabalho escondida (F:\ferramentas\desktop_oculto.ps1):
##   godot --path . --resolution 1920x1080 res://tools/bake_building_photos.tscn -- <pasta, padrão ui/photos>

const PHOTO_SIZE := Vector2i(320, 240)
const SPOT := Vector2i(150, 150)
const HOUR := 16.5
## Tempo para a poeira da obra e da demolição assentar (s) e o quanto do quadro o prédio ocupa.
const SETTLE_S := 4.0
const FILL := 0.62

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else ProjectSettings.globalize_path("res://ui/photos")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	Settings.edge_pan = false
	Settings.max_fps = 0
	# sem o pulo da obra; a poeira da obra e da demolição assenta antes da foto (SETTLE_S)
	Settings.reduce_motion = true
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	_sim.free_build = true
	_sim.ignore_terrain = true
	_game.hud.visible = false
	_game.building_view.hide_icons = true
	_set_hour(HOUR)
	var count := 0
	for def: BuildingDef in _sim.data.buildings:
		# o píer precisa de água (a ilha plana não tem): segue com o ícone
		if def.kind == BuildingDef.Kind.MODULE or def.is_pier():
			continue
		if def.kind == BuildingDef.Kind.RESIDENCE:
			for tier: TierDef in _sim.data.tiers:
				if await _photo(def, tier.id, "house_%s.png" % tier.id):
					count += 1
		elif await _photo(def, &"", "building_%s.png" % def.id):
			count += 1
	print("bake_building_photos: %d fotos em %s" % [count, _out_dir])
	get_tree().quit()


## Põe o prédio (com os módulos e a rua da frente), fotografa e tira tudo. false se não coube.
func _photo(def: BuildingDef, tier: StringName, file_name: String) -> bool:
	var placed := _sim.execute(PlaceBuildingCommand.new(0, def.id, SPOT, 0))
	if not placed.ok():
		push_warning("bake_building_photos: %s não coube (%s)" % [def.id, placed.reason])
		return false
	var building_id := placed.placed[0]
	var area := Footprint.rect(SPOT, def.size, 0)
	# a frente (rotação 0) olha para −z: a rua passa logo na frente
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(area.position.x - 2, area.position.y - 1),
			Vector2i(area.end.x + 1, area.position.y - 1))))
	var reach := area
	if def.modules_required > 0:
		reach = _modules(def, area)
	if tier != &"":
		var record := _sim.world.building(building_id)
		record.tier = tier
		record.residents = 10.0
		_game.building_view.rebuild()
	var center := _sim.world.island(0).rect_world(reach)
	var cell := _sim.config.cell_size_m
	var height := def.height_m
	if tier != &"":
		height = _sim.data.tier(tier).house_height_m
	# o quadro recortado (0,86 da altura, campo de visão de 45°) vê 0,71 × a distância: o maior lado ocupa FILL dele
	var span := maxf(maxf(reach.size.x, reach.size.y) * cell, height * 1.7)
	if def.modules_required > 0:
		# a fazenda: a casa com folga para os primeiros campos (todos eles deixavam a casa pequena demais)
		span = maxf(maxf(area.size.x, area.size.y) * cell * 2.6, height * 1.7)
		center = _sim.world.island(0).rect_world(area) + Vector3(0.0, 0.0, cell * 1.5)
	var distance := clampf(span / (FILL * 0.71), 7.0, 120.0)
	await _settle()
	await _shot(file_name, Vector3(center.x, height * 0.45, center.z), distance)
	_sim.execute(DemolishCommand.new(0, Rect2i(SPOT - Vector2i(30, 30), Vector2i(70, 70))))
	await _settle()
	return true


## Os módulos da fazenda atrás dela; devolve o retângulo da fazenda com os módulos que entraram (o enquadramento).
func _modules(def: BuildingDef, area: Rect2i) -> Rect2i:
	var module := _sim.data.building(def.module_id)
	var reach := area.grow(def.module_radius_cells)
	var used := area
	var placed := 0
	# encostados na casa: as fileiras de trás, do lado dela para fora (não do canto mais longe do raio)
	for y: int in range(area.end.y, reach.end.y - module.size.y + 1):
		for x: int in range(area.position.x - module.size.x, mini(area.end.x + module.size.x, reach.end.x - module.size.x + 1)):
			if placed >= def.modules_required:
				return used
			if _sim.execute(PlaceBuildingCommand.new(0, def.module_id, Vector2i(x, y), 0)).ok():
				placed += 1
				used = used.merge(Rect2i(Vector2i(x, y), module.size))
	return used


func _settle() -> void:
	await get_tree().create_timer(SETTLE_S).timeout


func _shot(file_name: String, focus: Vector3, distance: float) -> void:
	var rig := _game.camera.rig
	rig.focus = focus
	rig.distance = distance
	rig.target_distance = distance
	# de frente (a câmera em −z olha para +z) e um pouco de lado; mais baixa que a do jogo, para a fachada
	rig.yaw = PI + 0.55
	rig.target_yaw = rig.yaw
	rig.pitch_offset_deg = -14.0
	# a altura do olhar vai no foco (a câmera segue o chão plano, em 0)
	_game.camera.apply()
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var frame_image := get_viewport().get_texture().get_image()
	var photo := PhotoGrade.crop_4_3(frame_image, 0.86)
	photo.resize(PHOTO_SIZE.x, PHOTO_SIZE.y, Image.INTERPOLATE_LANCZOS)
	PhotoGrade.apply(photo)
	photo.save_png(_out_dir.path_join(file_name))
	print("foto ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
