extends "res://tools/capture_phase260.gd"
## Roteiro de verificação visual do ciclo do mar e do rio (Fases 280 a 284): na semente 1840, às 10h30, a falésia e a praia da
## ilha principal, o mar de cima, a praia da primeira ilha tropical, o rio de perto e a falésia à noite. As mesmas vistas antes e
## depois de cada fase. Com CAPTURA_MAR=lab, as vistas de dia em cada combinação de VARIANTS (a cor da água posta à mão no
## material), com o nome dela na frente. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 120000 res://tools/capture_phase280.tscn -- <pasta>

## [nome, cor do fundo, cor da plataforma, largura da plataforma em m] para o laboratório.
const VARIANTS: Array = [
	["a_atual", Color(0.05, 0.19, 0.42, 1.0), Color(0.24, 0.76, 0.72, 0.62), 40.0],
	["b_petroleo", Color(0.05, 0.2, 0.31, 1.0), Color(0.2, 0.55, 0.55, 0.55), 28.0],
	["c_fundo", Color(0.04, 0.16, 0.26, 1.0), Color(0.18, 0.48, 0.5, 0.5), 22.0],
	["d_escuro", Color(0.03, 0.12, 0.2, 1.0), Color(0.16, 0.42, 0.44, 0.45), 18.0],
]


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	var world := game.simulation.world
	var grid := world.island(Simulation.MAIN_ISLAND)
	var cliff := grid.cell_world(_find_cliff(grid))
	var beach := points[2]
	var river := grid.cell_world(_find_river(grid, true))
	var dry_bed := grid.cell_world(_find_river(grid, false))
	var tropical := Vector3.ZERO
	for island_id: int in world.islands.size():
		if world.is_tropical(island_id, game.simulation.data):
			var island := world.island(island_id)
			tropical = island.cell_world(_find_beach(island))
			break
	if OS.get_environment("CAPTURA_MAR") == "lab":
		var material: ShaderMaterial = game.water_view._material
		for variant: Array in VARIANTS:
			var prefix: String = variant[0]
			material.set_shader_parameter(&"color_deep", variant[1])
			material.set_shader_parameter(&"color_shelf", variant[2])
			material.set_shader_parameter(&"shelf_m", variant[3])
			await _shot(game, prefix + "_falesia.png", cliff, 90.0, 0.3)
			await _shot(game, prefix + "_mar_de_cima.png", points[3], 420.0, 0.3)
		get_tree().quit()
		return
	await _shot(game, "01_falesia.png", cliff, 90.0, 0.3)
	await _shot(game, "02_praia.png", beach, 70.0, 0.3)
	await _shot(game, "03_mar_de_cima.png", points[3], 420.0, 0.3)
	await _shot(game, "04_tropical.png", tropical, 90.0, 0.3)
	await _shot(game, "05_rio.png", river, 45.0, 0.3)
	await _shot(game, "05b_leito_seco.png", dry_bed, 45.0, 0.3)
	_set_hour(22.0)
	# o Sky3D passa a luz ambiente do dia para a da noite em 3 s
	await get_tree().create_timer(3.5).timeout
	await _shot(game, "06_falesia_noite.png", cliff, 90.0, 0.3)
	await _shot(game, "07_mar_de_cima_noite.png", points[3], 420.0, 0.3)
	get_tree().quit()


## A célula de rio com água (wet: o leito abaixo de -0,5 m) ou do leito seco (acima de 0,3 m, a cabeceira) mais perto do meio da
## ilha, com terra dos dois lados (ao longo de x ou de z).
func _find_river(grid: IslandGrid, wet: bool) -> Vector2i:
	var best := grid.size / 2
	var best_score := INF
	for y: int in range(3, grid.size.y - 3):
		for x: int in range(3, grid.size.x - 3):
			var cell := Vector2i(x, y)
			# Fase 283: com água de verdade (o leito abaixo do mar; na cabeceira o rio é só o leito seco)
			if grid.ground_at(cell) != IslandGrid.Ground.RIVER or (grid.cell_height(cell) > -0.5 if wet else grid.cell_height(cell) < 0.3):
				continue
			var banks := (grid.ground_at(cell + Vector2i(3, 0)) == IslandGrid.Ground.LAND and grid.ground_at(cell - Vector2i(3, 0)) == IslandGrid.Ground.LAND) \
					or (grid.ground_at(cell + Vector2i(0, 3)) == IslandGrid.Ground.LAND and grid.ground_at(cell - Vector2i(0, 3)) == IslandGrid.Ground.LAND)
			var score := Vector2(cell - grid.size / 2).length()
			if banks and score < best_score:
				best_score = score
				best = cell
	return best
