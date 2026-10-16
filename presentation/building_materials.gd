class_name BuildingMaterials
extends RefCounted
## Materiais PBR dos prédios (Fase 9): um ShaderMaterial para as paredes e um para os telhados,
## os dois com as pilhas de texturas de assets/materials/. O que muda de um prédio para outro
## (camada, tom, base, fuligem) vai em instance uniform, então todos dividem o mesmo material.

## Camadas das pilhas (a ordem de tools/pack_material_textures.gd).
enum Wall { BRICK, PLASTER, WOOD, STONE }
enum Roof { TILES, PLANKS }

const SHADER := "res://shaders/building.gdshader"
const KIT_SHADER := "res://shaders/building_kit.gdshader"
const KIT_COLORMAP := "res://assets/models/buildings/Textures/colormap.png"

static var _walls: ShaderMaterial
static var _roofs: ShaderMaterial
static var _kit: ShaderMaterial


static func walls() -> ShaderMaterial:
	if _walls == null:
		_walls = _material("walls", 3.0)
	return _walls


static func roofs() -> ShaderMaterial:
	if _roofs == null:
		_roofs = _material("roofs", 2.5)
	return _roofs


## Prédios de modelo (BuildingKit): as duas pilhas de texturas e a paleta do kit num material só.
static func kit() -> ShaderMaterial:
	if _kit == null:
		_kit = ShaderMaterial.new()
		_kit.shader = load(KIT_SHADER) as Shader
		_kit.set_shader_parameter(&"colormap", load(KIT_COLORMAP))
		_kit.set_shader_parameter(&"wall_albedo_rough", load("res://assets/materials/walls_albedo_rough.png"))
		_kit.set_shader_parameter(&"wall_normals", load("res://assets/materials/walls_normal.png"))
		_kit.set_shader_parameter(&"roof_albedo_rough", load("res://assets/materials/roofs_albedo_rough.png"))
		_kit.set_shader_parameter(&"roof_normals", load("res://assets/materials/roofs_normal.png"))
	return _kit


## Dados da instância do prédio de modelo: parede e telhado (camada e tom), base e fuligem.
static func dress_kit(instance: GeometryInstance3D, layer: int, tint: Color, roof_layer: int, roof_tint: Color,
		base_height: float, soot: float = 0.0) -> void:
	dress(instance, layer, tint, base_height, soot)
	instance.set_instance_shader_parameter(&"roof_layer", float(roof_layer))
	instance.set_instance_shader_parameter(&"roof_tint", roof_tint)


## Passa os dados da instância ao material dividido.
static func dress(instance: GeometryInstance3D, layer: int, tint: Color, base_height: float, soot: float = 0.0) -> void:
	instance.set_instance_shader_parameter(&"layer", float(layer))
	instance.set_instance_shader_parameter(&"tint", tint)
	instance.set_instance_shader_parameter(&"base_height", base_height)
	instance.set_instance_shader_parameter(&"soot", soot)


static func _material(stack: String, meters: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(SHADER) as Shader
	material.set_shader_parameter(&"albedo_rough", load("res://assets/materials/%s_albedo_rough.png" % stack))
	material.set_shader_parameter(&"normals", load("res://assets/materials/%s_normal.png" % stack))
	material.set_shader_parameter(&"texture_meters", meters)
	return material
