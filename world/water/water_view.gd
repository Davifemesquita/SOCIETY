class_name WaterView
extends Node3D
## Adaptador da água (seção 13): o oceano do Boujie Water Shader (nó Ocean do addon, malha em
## anéis de detalhe que acompanha a câmera) com a cópia editada do shader em shaders/water.gdshader.
## Os valores de cor, espuma e refração vêm do material pronto do addon; as ondas são as de um
## porto, baixas. A poluição (seção 8: olaria, fundição e minas sujam a água em volta) é um mapa
## do arquipélago, refeito quando um prédio poluidor entra ou sai.
## Sem o addon, um plano simples na altura do mar.
## Fase 35: com o CoastField (o mesmo da TerrainView), a água rasa junto da costa ganha cor de plataforma, a espuma
## anda para a praia e as ondas se acalmam.

const OCEAN_SCRIPT := "res://addons/boujie_water_shader/types/ocean.gd"
const PREFAB_MATERIAL := "res://addons/boujie_water_shader/prefabs/deep_ocean_material.tres"
const SHADER := preload("res://shaders/water.gdshader")
## Ondas de porto: altura (m), alongamento, direção (graus), frequência (1/m), velocidade.
const WAVES: Array[Vector4] = [Vector4(0.18, 1.0, 15.0, 0.035), Vector4(0.08, 0.6, 140.0, 0.08), Vector4(0.04, 0.4, 300.0, 0.15)]
const WAVE_SPEEDS: Array[float] = [0.9, 1.4, 2.2]
## Um pixel do mapa de poluição cobre isto, em metros.
const POLLUTION_PIXEL_M := 4.0
const FALLBACK_COLOR := Color(0.18, 0.33, 0.42)
const FALLBACK_SIZE_M := 6000.0

var _simulation: Simulation
var _material: ShaderMaterial
var _ocean: Node3D
var _bounds := Rect2()
var _pollution := Image.new()
## Prédios poluidores no mapa: só eles refazem o mapa ao entrar ou sair.
var _polluters: Dictionary[int, bool] = {}


func setup(simulation: Simulation, coast: CoastField = null) -> void:
	_simulation = simulation
	for grid: IslandGrid in simulation.world.islands:
		_bounds = grid.world_rect() if _bounds.size == Vector2.ZERO else _bounds.merge(grid.world_rect())
	_bounds = _bounds.grow(64.0)
	if ResourceLoader.exists(OCEAN_SCRIPT):
		_create_ocean()
	else:
		_create_plane()
	if _material != null and coast != null and coast.size != Vector2i.ZERO:
		_material.set_shader_parameter(&"coast_field", coast.texture())
		_material.set_shader_parameter(&"coast_bounds", coast.bounds())
		_material.set_shader_parameter(&"coast_far_m", coast.max_m)
		_material.set_shader_parameter(&"has_coast", true)
	EventBus.building_placed.connect(_on_building_placed)
	EventBus.building_removed.connect(func(building_id: int) -> void:
		if _polluters.erase(building_id):
			refresh_pollution())
	EventBus.world_replaced.connect(refresh_pollution)
	refresh_pollution()


func _on_building_placed(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	if record != null and _simulation.def_of(record).pollution_radius_cells > 0:
		refresh_pollution()


func uses_boujie() -> bool:
	return _ocean != null


## Material da água (testes).
func material() -> ShaderMaterial:
	return _material


## Poluição da água no ponto (0 a 1), a mesma que o shader lê.
func pollution_at(x: float, z: float) -> float:
	var pixel := Vector2i(floori((x - _bounds.position.x) / POLLUTION_PIXEL_M), floori((z - _bounds.position.y) / POLLUTION_PIXEL_M))
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= _pollution.get_width() or pixel.y >= _pollution.get_height():
		return 0.0
	return _pollution.get_pixelv(pixel).r


func _create_ocean() -> void:
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	var prefab := load(PREFAB_MATERIAL) as ShaderMaterial
	if prefab != null:
		for uniform: Dictionary in SHADER.get_shader_uniform_list():
			var uniform_name: StringName = uniform["name"]
			var value: Variant = prefab.get_shader_parameter(uniform_name)
			if value != null:
				_material.set_shader_parameter(uniform_name, value)
	_material.set_shader_parameter(&"WaveCount", WAVES.size())
	var heights := PackedFloat32Array()
	var stretches := PackedFloat32Array()
	var directions := PackedFloat32Array()
	var frequencies := PackedFloat32Array()
	for wave: Vector4 in WAVES:
		heights.append(wave.x)
		stretches.append(wave.y)
		directions.append(wave.z)
		frequencies.append(wave.w)
	_material.set_shader_parameter(&"WaveSteepnesses", heights)
	_material.set_shader_parameter(&"WaveAmplitudes", stretches)
	_material.set_shader_parameter(&"WaveDirectionsDegrees", directions)
	_material.set_shader_parameter(&"WaveFrequencies", frequencies)
	_material.set_shader_parameter(&"WaveSpeeds", PackedFloat32Array(WAVE_SPEEDS))
	_material.set_shader_parameter(&"WavePhases", PackedFloat32Array([0.0, 0.0, 0.0]))
	# porto, não oceano: sem espuma de mar aberto (a do litoral continua)
	_material.set_shader_parameter(&"FoamWaveCount", 0)
	# perto do litoral o fundo aparece: a cor funda chega mais devagar
	_material.set_shader_parameter(&"beers_law", 0.12)
	_material.set_shader_parameter(&"depth_offset", -1.0)
	_material.set_shader_parameter(&"color_shallow", Color(0.25, 0.55, 0.55, 0.35))
	var script := load(OCEAN_SCRIPT) as GDScript
	var created: Variant = script.new()
	if not created is Node3D:
		_create_plane()
		return
	_ocean = created
	_ocean.name = "Ocean"
	_ocean.set(&"levels_of_detail", 5)
	_ocean.set(&"outermost_resolution", 12)
	_ocean.set(&"unit_size", 2.0)
	_ocean.set(&"far_edge", 4000)
	_ocean.set(&"material", _material)
	add_child(_ocean)


func _create_plane() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(FALLBACK_SIZE_M, FALLBACK_SIZE_M)
	var material := StandardMaterial3D.new()
	material.albedo_color = FALLBACK_COLOR
	material.roughness = 0.15
	plane.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = plane
	instance.position = Vector3(_bounds.get_center().x, 0.0, _bounds.get_center().y)
	add_child(instance)


## O oceano acompanha a câmera, em passos do maior ladrilho (a textura não escorrega).
func _process(_delta: float) -> void:
	if _ocean == null:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var snap: float = _ocean.get(&"max_unit_size")
	var at := camera.global_position
	_ocean.global_position = Vector3(snappedf(at.x, snap), 0.0, snappedf(at.z, snap))


## Mapa de poluição: em volta de cada prédio poluidor, no raio dele, cai do centro para a borda.
func refresh_pollution() -> void:
	var size := Vector2i(ceili(_bounds.size.x / POLLUTION_PIXEL_M), ceili(_bounds.size.y / POLLUTION_PIXEL_M))
	_pollution = Image.create_empty(size.x, size.y, false, Image.FORMAT_R8)
	var world := _simulation.world
	_polluters.clear()
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		var def := _simulation.def_of(record)
		if def.pollution_radius_cells <= 0:
			continue
		_polluters[building_id] = true
		var grid := world.island(record.island_id)
		var center := grid.rect_world(Footprint.rect(record.origin, def.size, record.rotation))
		var radius := def.pollution_radius_cells * grid.cell_size
		var reach := ceili(radius / POLLUTION_PIXEL_M)
		var middle := Vector2i(floori((center.x - _bounds.position.x) / POLLUTION_PIXEL_M), floori((center.z - _bounds.position.y) / POLLUTION_PIXEL_M))
		for y: int in range(middle.y - reach, middle.y + reach + 1):
			for x: int in range(middle.x - reach, middle.x + reach + 1):
				if x < 0 or y < 0 or x >= size.x or y >= size.y:
					continue
				var gap := Vector2(x - middle.x, y - middle.y).length() * POLLUTION_PIXEL_M
				var amount := clampf(1.0 - gap / radius, 0.0, 1.0) * def.pollution_strength
				if amount > _pollution.get_pixel(x, y).r:
					_pollution.set_pixel(x, y, Color(amount, 0.0, 0.0))
	if _material != null:
		_material.set_shader_parameter(&"pollution_map", ImageTexture.create_from_image(_pollution))
		_material.set_shader_parameter(&"pollution_bounds", Vector4(_bounds.position.x, _bounds.position.y,
				size.x * POLLUTION_PIXEL_M, size.y * POLLUTION_PIXEL_M))
