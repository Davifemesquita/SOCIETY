extends SceneTree
## Gera os animais da cidade viva (VatModel, Fase 13) a partir do Farm Animals Pack da Quaternius (CC0):
##   tools/godot.sh godot --headless --path . --script res://tools/bake_animals.gd
## Lê os FBX de assets/source/quaternius/animals/ (com .gdignore: o Godot não os importa) e grava
## assets/vat/animal_<bicho>.res. A cor vem do material de cada superfície (cor do vértice).

const SOURCE_DIR := "res://assets/source/quaternius/animals"
const OUT_DIR := "res://assets/vat"
## Os bichos são baixo polígono; o teto só segura um modelo novo maior.
const TARGET_TRIANGLES := 1500
const FPS := 12.0
## Bicho ← (arquivo, malha, animações: nome no modelo ← nome no FBX).
const ANIMALS := {
	"sheep": ["Sheep.fbx", "Sheep", {"idle": "Armature|Idle"}],
	"pig": ["Pig.fbx", "Pig", {"idle": "Armature|Idle"}],
	"dog": ["Pug.fbx", "Pug", {"idle": "Armature|Idle"}],
	"horse": ["Horse.fbx", "Horse", {"idle": "Armature|Idle", "walk": "Armature|Walk"}],
}


func _initialize() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for animal: String in ANIMALS:
		var spec: Array = ANIMALS[animal]
		var file_name: String = spec[0]
		var mesh_name: String = spec[1]
		var wanted: Dictionary = spec[2]
		var document := FBXDocument.new()
		var state := FBXState.new()
		var path := ProjectSettings.globalize_path(SOURCE_DIR.path_join(file_name))
		if document.append_from_file(path, state) != OK:
			push_error("não abri %s" % path)
			quit(1)
			return
		var root := document.generate_scene(state)
		var source := VatBaker.from_scene(root, PackedStringArray([mesh_name]), true)
		var players := root.find_children("*", "AnimationPlayer", true, false)
		var player := players[0] as AnimationPlayer if not players.is_empty() else null
		if source == null or player == null:
			push_error("sem malha %s ou sem animações em %s" % [mesh_name, file_name])
			root.free()
			quit(1)
			return
		var clips: Array[VatBaker.ClipSource] = []
		for clip_name: String in wanted:
			var animation_name: String = wanted[clip_name]
			var animation := player.get_animation(animation_name).duplicate(true) as Animation
			clips.append(VatBaker.ClipSource.new(clip_name, animation, false))
		root.free()
		var reduced := VatBaker.reduce(source, TARGET_TRIANGLES)
		var model := VatBaker.bake(reduced, clips, FPS, "Head")
		var out := OUT_DIR.path_join("animal_%s.res" % animal)
		var error := ResourceSaver.save(model, out, ResourceSaver.FLAG_COMPRESS)
		print("%s: %d → %d triângulos, %d vértices, %d quadros, caixa %s → %s (%s)" % [animal,
				source.triangle_count(), model.triangle_count, model.vertex_count, model.positions.get_height(),
				model.mesh.get_aabb(), out, error_string(error)])
	quit()
