class_name ValleyMistView
extends Node3D
## Fase 309: a névoa nos vales. De madrugada até o fim da manhã (`amount_at`: sobe de MIST_RISE_H, cheia até MIST_FULL_UNTIL_H e
## some até MIST_GONE_H; mais forte no dia de neblina do WeatherCycle), lençóis de névoa baixa e mole presos nos vales perto da
## mata das ilhas temperadas (`sites`: os pontos de uma rede a cada STEP células mais baixos que a volta deles, com mata perto).
## Cada lugar tem duas camadas (`sheets`), planas, deitadas acima do chão, desenhadas pelo `shaders/valley_mist.gdshader` (borda
## mole, ruído andando com o vento e o pé esmaecido contra o chão e as árvores). Só visual; nada no save.

## A rede dos pontos (células), o raio da volta comparada (células), quanto o ponto fica abaixo da média da volta (m) e quantas
## células de mata ele precisa a até FOREST_REACH células.
const STEP := 5
const RING_CELLS := 7
const VALLEY_M := 0.7
const FOREST_REACH := 4
const FOREST_MIN := 6
## As duas camadas: a altura acima do chão (m) e o lado (m).
const LAYERS: Array[Vector2] = [Vector2(1.2, 36.0), Vector2(2.6, 26.0)]
## As horas da névoa e a força que ela tem num dia sem neblina sorteada (o dia de neblina vai até 1).
const MIST_RISE_H := 4.0
const MIST_FULL_H := 5.5
const MIST_FULL_UNTIL_H := 8.0
const MIST_GONE_H := 11.0
const PLAIN_DAY := 0.5

var _simulation: Simulation
var _mesh := MultiMeshInstance3D.new()
var _material := ShaderMaterial.new()
var _count := 0
## Quanto a névoa aparece agora (testes e capturas).
var amount := 0.0
## Horas totais a usar no lugar do relógio (capturas); negativo segue o relógio.
var hours_override := -1.0


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	_material.shader = load("res://shaders/valley_mist.gdshader") as Shader
	_mesh.name = "ValleyMist"
	_mesh.material_override = _material
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.visible = false
	add_child(_mesh)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func sheet_count() -> int:
	return _count


func rebuild() -> void:
	var world := _simulation.world
	var transforms: Array[Transform3D] = []
	for island_id: int in world.islands.size():
		for site: Vector3 in sites(world, _simulation.data, island_id):
			transforms.append_array(sheets(site))
	_count = transforms.size()
	if _count == 0:
		_mesh.multimesh = null
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	multimesh.mesh = plane
	multimesh.instance_count = _count
	for i: int in _count:
		multimesh.set_instance_transform(i, transforms[i])
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	_mesh.multimesh = multimesh


func _process(_delta: float) -> void:
	if _simulation == null:
		return
	var hours := hours_override if hours_override >= 0.0 else GameClock.clock.total_hours()
	var today := WeatherCycle.day(_simulation.world.seed, floori(hours / 24.0), _simulation.config)
	amount = amount_at(fposmod(hours, 24.0), today.mist)
	_mesh.visible = amount > 0.01 and _count > 0
	_material.set_shader_parameter(&"amount", amount)


## Quanto a névoa dos vales aparece (0 a 1) na hora do dia, com a neblina sorteada do dia (0 a 1).
static func amount_at(hour: float, day_mist: float) -> float:
	var rise := smoothstep(MIST_RISE_H, MIST_FULL_H, hour)
	var fade := 1.0 - smoothstep(MIST_FULL_UNTIL_H, MIST_GONE_H, hour)
	return rise * fade * lerpf(PLAIN_DAY, 1.0, clampf(day_mist, 0.0, 1.0))


## Os pontos de névoa da ilha (no mundo, no chão): só nas temperadas; na rede a cada STEP células, em terra mais baixa que a
## média de oito pontos a RING_CELLS dela por VALLEY_M, com FOREST_MIN células de mata a até FOREST_REACH.
static func sites(world: WorldState, data: GameData, island_id: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var grid := world.island(island_id)
	if grid == null or grid.flat or world.is_tropical(island_id, data):
		return result
	var trees := grid.trees
	var ground := grid.ground
	var width := grid.size.x
	for y: int in range(RING_CELLS, grid.size.y - RING_CELLS, STEP):
		for x: int in range(RING_CELLS, grid.size.x - RING_CELLS, STEP):
			if ground[y * width + x] != IslandGrid.Ground.LAND:
				continue
			var cell := Vector2i(x, y)
			var forest := 0
			for dy: int in range(-FOREST_REACH, FOREST_REACH + 1):
				for dx: int in range(-FOREST_REACH, FOREST_REACH + 1):
					if trees[(y + dy) * width + x + dx] > 0:
						forest += 1
			if forest < FOREST_MIN:
				continue
			var around := 0.0
			for k: int in 8:
				var step := Vector2(RING_CELLS, 0.0).rotated(TAU * k / 8.0)
				around += grid.cell_height(cell + Vector2i(roundi(step.x), roundi(step.y)))
			var here := grid.cell_height(cell)
			if here > around / 8.0 - VALLEY_M:
				continue
			var at := grid.cell_world(cell)
			result.append(Vector3(at.x, here, at.z))
	return result


## As camadas de um ponto: o plano de 1 m deitado, esticado ao lado da camada e girado pelo lugar, na altura dela.
static func sheets(site: Vector3) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var turn := fposmod(site.x * 0.37 + site.z * 0.61, TAU)
	for k: int in LAYERS.size():
		var layer := LAYERS[k]
		var basis := Basis(Vector3.UP, turn + k * 1.3).scaled(Vector3(layer.y, 1.0, layer.y))
		result.append(Transform3D(basis, site + Vector3(0.0, layer.x, 0.0)))
	return result
