class_name FlatIsland
extends Node3D
## Ilha plana da Fase 1: chão, bloco da ilha e mar. O sol e o céu ficam no SkyAdapter (Fase 4).
## Desde a Fase 5 só a usam os testes e os saves de antes do arquipélago (TerrainView desenha o resto).

const GROUND_COLOR := Color(0.4, 0.5, 0.32)
const CLIFF_COLOR := Color(0.42, 0.38, 0.32)
const WATER_COLOR := Color(0.18, 0.33, 0.42)
const WATER_SIZE_M := 6000.0
const ISLAND_DEPTH_M := 2.0
const WATER_LEVEL_M := -0.6


func setup(size_m: Vector2) -> void:
	var center := Vector3(size_m.x * 0.5, 0.0, size_m.y * 0.5)
	var block := BoxMesh.new()
	block.size = Vector3(size_m.x, ISLAND_DEPTH_M, size_m.y)
	block.material = _material(CLIFF_COLOR)
	_add_mesh(block, center - Vector3(0.0, ISLAND_DEPTH_M * 0.5 + 0.01, 0.0))
	var ground := PlaneMesh.new()
	ground.size = size_m
	ground.material = _material(GROUND_COLOR)
	_add_mesh(ground, center)
	var water := PlaneMesh.new()
	water.size = Vector2(WATER_SIZE_M, WATER_SIZE_M)
	var water_material := _material(WATER_COLOR)
	water_material.roughness = 0.15
	water.material = water_material
	_add_mesh(water, Vector3(center.x, WATER_LEVEL_M, center.z))


func _add_mesh(mesh: Mesh, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	add_child(instance)
	return instance


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	return material

