class_name PlanView
extends Node3D
## As plantas no mapa (Fase 49): o fantasma de cada uma, o mesmo da prévia de construção (o modelo do kit girado como vai
## ficar, ou a caixa para quem não tem modelo, shaders/build_ghost.gdshader), em azul; listrado em vermelho a que não
## pode mais ser construída (um prédio no lugar, a ilha mudou). Refeito quando as plantas ou os prédios mudam.

const PLAN_COLOR := Color(0.35, 0.6, 0.95, 0.4)
const BLOCKED_COLOR := Color(0.95, 0.25, 0.2, 0.45)

var _simulation: Simulation
var _cell_size: float
var _valid := ShaderMaterial.new()
var _blocked := ShaderMaterial.new()
## Fantasma de cada planta, pelo id (testes).
var _ghosts: Dictionary[int, MeshInstance3D] = {}


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	_cell_size = cell_size
	name = "Plans"
	for pair: Array in [[_valid, PLAN_COLOR, false], [_blocked, BLOCKED_COLOR, true]]:
		var material: ShaderMaterial = pair[0]
		var color: Color = pair[1]
		var striped: bool = pair[2]
		material.shader = preload("res://shaders/build_ghost.gdshader")
		material.render_priority = BuildPreviewView.RENDER_PRIORITY - 1
		material.set_shader_parameter(&"tint", color)
		material.set_shader_parameter(&"striped", striped)
	EventBus.plans_changed.connect(rebuild)
	EventBus.world_replaced.connect(rebuild)
	EventBus.building_placed.connect(func(_id: int) -> void: rebuild())
	EventBus.building_removed.connect(func(_id: int) -> void: rebuild())
	rebuild()


func rebuild() -> void:
	for ghost: MeshInstance3D in _ghosts.values():
		remove_child(ghost)
		ghost.queue_free()
	_ghosts.clear()
	for plan: PlanRecord in _simulation.world.plans.values():
		var ghost := _ghost_of(plan)
		ghost.name = "Plan_%d" % plan.id
		add_child(ghost)
		_ghosts[plan.id] = ghost


func ghost_count() -> int:
	return _ghosts.size()


## A planta aparece listrada (não dá mais para construir)?
func is_blocked(plan_id: int) -> bool:
	return _ghosts.has(plan_id) and _ghosts[plan_id].material_override == _blocked


func _ghost_of(plan: PlanRecord) -> MeshInstance3D:
	var grid := _simulation.world.island(plan.island_id)
	var def := _simulation.data.building(plan.def_id)
	var area := Footprint.rect(plan.origin, def.size, plan.rotation)
	var inside := area.intersection(Rect2i(Vector2i.ZERO, grid.size))
	var base := grid.area_height(inside) if inside.has_area() else 0.0
	var center := grid.rect_world(area)
	var ghost := MeshInstance3D.new()
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var blocked := PlacementRules.check_building(grid, def, plan.origin, plan.rotation) != PlacementRules.OK
	ghost.material_override = _blocked if blocked else _valid
	var record := BuildingRecord.new(0, def.id, plan.island_id, plan.origin, plan.rotation)
	if def.kind == BuildingDef.Kind.RESIDENCE:
		record.tier = _simulation.data.tiers[0].id
	var spec := BuildingKit.spec_for(_simulation, record, _cell_size)
	if spec != null:
		ghost.mesh = BuildingKit.mesh(spec)
		if inside.has_area():
			base += BuildingKit.seat_lift(grid, inside)
		ghost.position = Vector3(center.x, base, center.z)
		ghost.rotation.y = -PI * 0.5 * posmod(plan.rotation, 4)
	else:
		var box := BoxMesh.new()
		box.size = Vector3(area.size.x * _cell_size, def.height_m, area.size.y * _cell_size)
		ghost.mesh = box
		ghost.position = Vector3(center.x, base + def.height_m * 0.5, center.z)
	return ghost
