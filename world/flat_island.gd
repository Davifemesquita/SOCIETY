class_name FlatIsland
extends Node3D
## Ilha plana da Fase 1: chão, bloco da ilha, mar, sol e céu. O terreno de verdade
## (Terrain3D, arquipélago por semente) entra na Fase 5.

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
	_add_sun()
	_add_environment()


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


func _add_sun() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 600.0
	add_child(sun)


func _add_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.42, 0.58, 0.78)
	sky_material.sky_horizon_color = Color(0.8, 0.82, 0.8)
	sky_material.ground_horizon_color = Color(0.8, 0.82, 0.8)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.78, 0.8, 0.82)
	environment.fog_density = 0.00015
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
