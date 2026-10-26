class_name AssetRules
extends RefCounted
## Regras de importação do kit de época (Fase 50): o que uma peça de prédio precisa para entrar no jogo sem quebrar a
## montagem por célula. Orçamento de triângulos por categoria (o teto é erro; abaixo do piso só avisa), uma malha só
## (a BuildingView usa uma por prédio), a frente marcada (um nó "Front" em −Z: a rotação 0 do jogo olha para −Z), o
## pivô no centro do lote e no chão, o tamanho dentro do lote, LOD ligado na importação, o nome começando pelo id do
## prédio e o arquivo no CREDITS.md. Estático para os testes e para tools/import/validate_assets.tscn.

enum Category { PROP, HOUSE, FACTORY, SHIP }

## Triângulos do LOD0: mínimo (só aviso) e máximo (erro), da especificação.
const BUDGETS: Dictionary[Category, Vector2i] = {
	Category.PROP: Vector2i(0, 1000),
	Category.HOUSE: Vector2i(3000, 8000),
	Category.FACTORY: Vector2i(8000, 20000),
	Category.SHIP: Vector2i(4000, 8000),
}
## Folga do tamanho e do pivô (m).
const FIT_TOLERANCE_M := 0.3
const FRONT_NODE := "Front"


## A categoria do orçamento de um prédio.
static func category_for(def: BuildingDef) -> Category:
	if def.kind == BuildingDef.Kind.RESIDENCE:
		return Category.HOUSE
	if def.is_decoration() or def.kind == BuildingDef.Kind.MODULE:
		return Category.PROP
	return Category.FACTORY


## As malhas da cena, em ordem.
static func meshes(root: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		found.append(root as MeshInstance3D)
	for child: Node in root.find_children("*", "MeshInstance3D", true, false):
		found.append(child as MeshInstance3D)
	return found


## Triângulos de uma malha (com índice ou sem).
static func triangles_of(mesh: Mesh) -> int:
	var total := 0
	if mesh == null:
		return 0
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var raw_indices: Variant = arrays[Mesh.ARRAY_INDEX]
		var indices := PackedInt32Array()
		if raw_indices is PackedInt32Array:
			indices = raw_indices
		if not indices.is_empty():
			total += indices.size() / 3
		else:
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			total += vertices.size() / 3
	return total


static func triangles(root: Node) -> int:
	var total := 0
	for instance: MeshInstance3D in meshes(root):
		total += triangles_of(instance.mesh)
	return total


## Os problemas da peça (vazio: pode entrar) e os avisos (abaixo do piso do orçamento), em [problemas, avisos].
## import_options: as opções do .import (null numa cena .tscn, que não tem LOD de importação).
static func check(root: Node, path: String, def: BuildingDef, cell_m: float, credits: String,
		import_options: ConfigFile) -> Array[PackedStringArray]:
	var problems := PackedStringArray()
	var warnings := PackedStringArray()
	var found := meshes(root)
	if found.size() != 1:
		problems.append("uma malha só (achou %d)" % found.size())
	var budget := BUDGETS[category_for(def)]
	var count := triangles(root)
	if count > budget.y:
		problems.append("%d triângulos, acima do teto de %d" % [count, budget.y])
	elif count < budget.x:
		warnings.append("%d triângulos, abaixo do piso de %d" % [count, budget.x])
	var front := root.find_child(FRONT_NODE, true, false) as Node3D
	if front == null:
		problems.append("sem o nó %s (a frente, em −Z)" % FRONT_NODE)
	elif front.position.z >= 0.0:
		problems.append("a frente está em +Z (o jogo olha para −Z na rotação 0)")
	if found.size() == 1 and found[0].mesh != null:
		var box := found[0].mesh.get_aabb()
		var lot := Vector2(def.size) * cell_m
		if box.size.x > lot.x + FIT_TOLERANCE_M or box.size.z > lot.y + FIT_TOLERANCE_M:
			problems.append("%.1f × %.1f m, maior que o lote de %.1f × %.1f m" % [box.size.x, box.size.z, lot.x, lot.y])
		var center := box.get_center()
		if absf(center.x) > FIT_TOLERANCE_M or absf(center.z) > FIT_TOLERANCE_M or absf(box.position.y) > FIT_TOLERANCE_M:
			problems.append("o pivô fica no centro do lote e no chão (a caixa começa em %s)" % box.position)
	if import_options != null:
		var lods: Variant = import_options.get_value("params", "meshes/generate_lods", false)
		if not (lods is bool and lods):
			problems.append("LOD desligado na importação (meshes/generate_lods)")
	if not path.get_file().get_basename().begins_with(String(def.id)):
		problems.append("o nome do arquivo começa pelo id do prédio (%s)" % def.id)
	if not credits.contains(path.get_file()) and not credits.contains(path.get_base_dir().trim_prefix("res://")):
		problems.append("sem crédito no CREDITS.md (o arquivo ou a pasta dele)")
	return [problems, warnings]


## O prédio de um arquivo do kit: o id mais longo que abre o nome (casa_<classe> → house), ou null.
static func def_for(path: String, data: GameData) -> BuildingDef:
	var stem := path.get_file().get_basename()
	var best: BuildingDef = null
	for def: BuildingDef in data.buildings:
		if stem == String(def.id) or stem.begins_with(String(def.id) + "_"):
			if best == null or String(def.id).length() > String(best.id).length():
				best = def
	return best


## Varre a pasta do kit: {arquivo: [problemas, avisos]} de cada .glb, .gltf, .tscn e .scn.
static func scan(root_dir: String, data: GameData, cell_m: float, credits: String) -> Dictionary[String, Array]:
	var report: Dictionary[String, Array] = {}
	for path: String in files(root_dir):
		var def := def_for(path, data)
		if def == null:
			report[path] = [PackedStringArray(["nenhum prédio com esse id no começo do nome"]), PackedStringArray()]
			continue
		var scene := load(path) as PackedScene
		if scene == null:
			report[path] = [PackedStringArray(["não abriu como cena"]), PackedStringArray()]
			continue
		var root := scene.instantiate()
		var options: ConfigFile = null
		if path.get_extension() in ["glb", "gltf"]:
			options = ConfigFile.new()
			options.load(path + ".import")
		report[path] = check(root, path, def, cell_m, credits, options)
		root.free()
	return report


static func files(root_dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(root_dir)
	if dir == null:
		return found
	for file_name: String in dir.get_files():
		if file_name.get_extension() in ["glb", "gltf", "tscn", "scn"]:
			found.append(root_dir.path_join(file_name))
	for sub: String in dir.get_directories():
		found.append_array(files(root_dir.path_join(sub)))
	return found
