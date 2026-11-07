extends "res://tools/capture_phase280.gd"
## Roteiro de verificação visual do ciclo do mar e da costa II (Fases 295 a 299): as vistas da captura da Fase 280 (falésia,
## praia, mar de cima, tropical, rio) e a praia de perto. Com CAPTURA_MAR=espuma, a praia em cada combinação de FOAM_VARIANTS
## (parâmetros da água postos à mão), para achar de onde vem cada espuma. Precisa de GPU:
##   godot --path . --resolution 1920x1080 --quit-after 120000 res://tools/capture_phase295.tscn -- <pasta>

## [nome, {parâmetro: valor}] para o laboratório da espuma.
const FOAM_VARIANTS: Array = [
	["a_atual", {}],
	["b_espuma_da_costa_preta", {&"shore_foam_color": Color(0.0, 0.0, 0.0)}],
	["c_sem_anel", {&"rock_foam_m": 0.01}],
	["d_sem_beira", {&"shore_line_m": 0.01}],
]

## [nome, {parâmetro: valor}] para o laboratório do mar ao longe (Fase 298).
const FAR_VARIANTS: Array = [
	["a_atual", {}],
	["b_bem_escuro", {&"far_sea_dark": 0.25, &"far_sea_specular": 0.15}],
	["c_sem_fresnel", {&"albedo_fresnel": Color(0.0, 0.0, 0.0, 1.0)}],
	["d_fundo_e_fresnel", {&"far_sea_dark": 0.4, &"albedo_fresnel": Color(0.02, 0.06, 0.1, 1.0)}],
]


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	var world := game.simulation.world
	var grid := world.island(Simulation.MAIN_ISLAND)
	var cliff := grid.cell_world(_find_cliff(grid))
	var beach := points[2]
	if OS.get_environment("CAPTURA_MAR") == "perfil":
		var at := grid.world_to_cell(beach)
		for axis: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var row := ""
			for step: int in range(0, 50, 2):
				row += "%.2f " % grid.corner_height(at.x + axis.x * step, at.y + axis.y * step)
			print("perfil ", axis, ": ", row)
		get_tree().quit()
		return
	if OS.get_environment("CAPTURA_MAR") == "longe":
		var far_material: ShaderMaterial = game.water_view._material
		game.camera.rig.pitch_offset_deg = -22.0
		for variant: Array in FAR_VARIANTS:
			var prefix: String = variant[0]
			var params: Dictionary = variant[1]
			var saved := {}
			for key: StringName in params:
				saved[key] = far_material.get_shader_parameter(key)
				far_material.set_shader_parameter(key, params[key])
			await _shot(game, prefix + "_mar_ao_longe.png", cliff, 160.0, 0.3)
			for key: StringName in saved:
				far_material.set_shader_parameter(key, saved[key])
		get_tree().quit()
		return
	if OS.get_environment("CAPTURA_MAR") == "espuma":
		var material: ShaderMaterial = game.water_view._material
		for variant: Array in FOAM_VARIANTS:
			var prefix: String = variant[0]
			var params: Dictionary = variant[1]
			var saved := {}
			for key: StringName in params:
				saved[key] = material.get_shader_parameter(key)
				material.set_shader_parameter(key, params[key])
			await _shot(game, prefix + "_praia.png", beach, 70.0, 0.3)
			for key: StringName in saved:
				material.set_shader_parameter(key, saved[key])
		get_tree().quit()
		return
	await _shot(game, "01_falesia.png", cliff, 90.0, 0.3)
	await _shot(game, "01b_falesia_de_perto.png", cliff, 30.0, 0.3)
	await _shot(game, "02_praia.png", beach, 70.0, 0.3)
	await _shot(game, "02b_praia_de_perto.png", beach, 30.0, 0.5)
	await _shot(game, "03_mar_de_cima.png", points[3], 420.0, 0.3)
	# Fase 298: o mar ao longe, com a câmera mais deitada
	game.camera.rig.pitch_offset_deg = -22.0
	await _shot(game, "04_mar_ao_longe.png", cliff, 160.0, 0.3)
	game.camera.rig.pitch_offset_deg = 0.0
	get_tree().quit()
