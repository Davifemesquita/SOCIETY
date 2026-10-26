extends Node3D
## Custo de GPU do shader do terreno (Fase 34), efeito por efeito: desenha só o arquipélago da semente 1840 (terreno,
## sol e céu simples) com a câmera a 40, 120 e 300 m, e mede o tempo de GPU do viewport em cada variante. Precisa de
## GPU de verdade; a janela pode ficar fora do monitor (--position -6000,0).
##
##   godot --path . --position -6000,0 --resolution 1920x1080 res://tools/terrain_cost.tscn -- saida.md [shader_antigo]
##
## shader_antigo (opcional): caminho de um .gdshader de outra versão, medido como a variante "antigo".

const WARM_FRAMES := 40
const MEASURED_FRAMES := 180
const DISTANCES: Array[float] = [40.0, 120.0, 300.0]
const PITCH_DEG := 55.0

var _terrain: TerrainView
var _camera := Camera3D.new()
var _focus := Vector3.ZERO
var _lines: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var output: String = args[0] if args.size() > 0 else "user://terrain_cost.md"
	var old_shader: Shader = null
	if args.size() > 1:
		old_shader = Shader.new()
		old_shader.code = FileAccess.get_file_as_string(args[1])
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, data)
	_terrain = TerrainView.new()
	add_child(_terrain)
	_terrain.setup(world, config, data)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.5, 0.6, 0.7)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	add_child(environment)
	add_child(_camera)
	_camera.far = 4000.0
	_camera.make_current()
	var rect := world.island(Simulation.MAIN_ISLAND).world_rect()
	_focus = Vector3(rect.get_center().x, world.surface_height(rect.get_center().x, rect.get_center().y), rect.get_center().y)
	var viewport := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport, true)
	var new_shader: Shader = _terrain.materials()[0].shader
	var variants: Array[Dictionary] = [
		{"name": "completo", "params": {}},
		{"name": "sem hex-tiling", "params": {"hex_tiling": false}},
		{"name": "sem ruído nas bordas", "params": {"use_edge_noise": false}},
		{"name": "sem macro-variação", "params": {"use_macro": false}},
		{"name": "sem reamostragem de longe", "params": {"use_far": false}},
		{"name": "sem triplanar", "params": {"use_triplanar": false}},
		{"name": "tudo desligado", "params": {"hex_tiling": false, "use_edge_noise": false, "use_macro": false,
				"use_far": false, "use_triplanar": false}},
	]
	if old_shader != null:
		variants.append({"name": "antigo", "params": {}, "shader": old_shader})
	_lines.append("| Variante | GPU a %s (ms) |" % " / ".join(DISTANCES.map(func(d: float) -> String: return "%d m" % d)))
	_lines.append("|---|---|")
	for variant: Dictionary in variants:
		var params: Dictionary = variant["params"]
		for material: ShaderMaterial in _terrain.materials():
			material.shader = variant.get("shader", new_shader)
			for key: String in ["hex_tiling", "use_edge_noise", "use_macro", "use_far", "use_triplanar"]:
				material.set_shader_parameter(StringName(key), params.get(key, true))
		var times: Array[String] = []
		for distance: float in DISTANCES:
			times.append("%.2f" % await _measure(viewport, distance))
		_lines.append("| %s | %s |" % [variant["name"], " / ".join(times)])
		print(_lines[-1])
	var text := "\n### %s — %s\n\n%s\n" % [Time.get_datetime_string_from_system(false, true), RenderingServer.get_video_adapter_name(),
			"\n".join(_lines)]
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print(text)
	get_tree().quit()


## Tempo médio de GPU (ms) com a câmera na distância dada, olhando o centro da ilha principal.
func _measure(viewport: RID, distance: float) -> float:
	var pitch := deg_to_rad(PITCH_DEG)
	_camera.position = _focus + Vector3(0.0, sin(pitch), cos(pitch)) * distance
	_camera.look_at(_focus)
	for frame: int in WARM_FRAMES:
		await get_tree().process_frame
	var total := 0.0
	for frame: int in MEASURED_FRAMES:
		await get_tree().process_frame
		total += RenderingServer.viewport_get_measured_render_time_gpu(viewport)
	return total / MEASURED_FRAMES
