extends SceneTree
## Gera os pedestres da multidão (VatModel) a partir dos personagens da Quaternius:
##   tools/godot.sh godot --headless --path . --script res://tools/bake_pedestrians.gd
## Com a pasta dos pacotes baixados, refaz antes as animações guardadas no repositório:
##   ... --script res://tools/bake_pedestrians.gd -- /pasta/com/UAL1_Standard.glb/e/UAL2_Standard.glb
## Saída: assets/vat/pedestrian_male.res e pedestrian_female.res.

const SOURCE_DIR := "res://assets/source/quaternius"
const CLIPS_PATH := "res://assets/source/quaternius/pedestrian_clips.res"
const OUT_DIR := "res://assets/vat"
## Orçamento do pedestre na seção 14: de 1.000 a 3.000 triângulos.
const TARGET_TRIANGLES := 2000
const FPS := 24.0
## Animação no modelo ← (arquivo da biblioteca, nome lá dentro).
const CLIPS := {
	"walk": ["UAL1_Standard.glb", "Walk_Loop"],
	"walk_carry": ["UAL2_Standard.glb", "Walk_Carry_Loop"],
	"idle": ["UAL1_Standard.glb", "Idle_Loop"],
	"talk": ["UAL1_Standard.glb", "Idle_Talking_Loop"],
}
const WALKING := ["walk", "walk_carry"]
const BODIES := {
	"male": ["Superhero_Male_FullBody.gltf", "SuperHero_Male"],
	"female": ["Superhero_Female_FullBody.gltf", "Superhero_Female"],
}


func _initialize() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and not _extract_clips(args[0]):
		quit(1)
		return
	var library := load(CLIPS_PATH) as AnimationLibrary
	if library == null:
		push_error("sem %s: rode uma vez com a pasta dos pacotes da Quaternius" % CLIPS_PATH)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for body: String in BODIES:
		var files: Array = BODIES[body]
		var file_name: String = files[0]
		var mesh_name: String = files[1]
		var root := _load_gltf(ProjectSettings.globalize_path(SOURCE_DIR.path_join(file_name)), true)
		var source := VatBaker.from_scene(root, PackedStringArray([mesh_name]))
		root.free()
		if source == null:
			push_error("não achei a malha %s em %s" % [mesh_name, file_name])
			quit(1)
			return
		var full := source.triangle_count()
		var reduced := VatBaker.reduce(source, TARGET_TRIANGLES)
		var clips: Array[VatBaker.ClipSource] = []
		for clip_name: String in CLIPS:
			clips.append(VatBaker.ClipSource.new(clip_name, library.get_animation(clip_name), WALKING.has(clip_name)))
		var started := Time.get_ticks_msec()
		var model := VatBaker.bake(reduced, clips, FPS)
		var path := OUT_DIR.path_join("pedestrian_%s.res" % body)
		var error := ResourceSaver.save(model, path, ResourceSaver.FLAG_COMPRESS)
		print("%s: %d → %d triângulos, %d vértices, %d quadros, passo %s m, %d ms → %s (%s)" % [body, full,
				model.triangle_count, model.vertex_count, model.positions.get_height(), model.clip_strides_m,
				Time.get_ticks_msec() - started, path, error_string(error)])
	quit()


## Guarda no repositório só as quatro animações usadas (as bibliotecas inteiras têm 16 MB).
func _extract_clips(folder: String) -> bool:
	var library := AnimationLibrary.new()
	for clip_name: String in CLIPS:
		var spec: Array = CLIPS[clip_name]
		var file_name: String = spec[0]
		var animation_name: String = spec[1]
		var root := _load_gltf(folder.path_join(file_name), false)
		if root == null:
			push_error("não abri %s" % folder.path_join(file_name))
			return false
		var players := root.find_children("*", "AnimationPlayer", true, false)
		var player := players[0] as AnimationPlayer if not players.is_empty() else null
		if player == null or not player.has_animation(animation_name):
			push_error("%s não tem %s" % [file_name, animation_name])
			root.free()
			return false
		var animation := player.get_animation(animation_name).duplicate(true) as Animation
		animation.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(clip_name, animation)
		root.free()
	var error := ResourceSaver.save(library, CLIPS_PATH, ResourceSaver.FLAG_COMPRESS)
	print("animações guardadas em %s (%s)" % [CLIPS_PATH, error_string(error)])
	return error == OK


## Abre o glTF sem as imagens (a cor vem do shader da multidão; as texturas nem estão no
## repositório). Num .gltf, tira do JSON imagens, texturas e materiais antes de carregar.
func _load_gltf(path: String, strip_images: bool) -> Node:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_DISCARD_TEXTURES
	var error := OK
	if strip_images and path.get_extension() == "gltf":
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			return null
		var json: Dictionary = parsed
		for key: String in ["images", "textures", "samplers", "materials"]:
			json.erase(key)
		var meshes: Array = json.get("meshes", [])
		for mesh: Dictionary in meshes:
			var primitives: Array = mesh.get("primitives", [])
			for primitive: Dictionary in primitives:
				primitive.erase("material")
		# o caminho base termina em barra: sem ela o glTF procura o .bin uma pasta acima
		error = document.append_from_buffer(JSON.stringify(json).to_utf8_buffer(), path.get_base_dir() + "/", state)
	else:
		error = document.append_from_file(path, state)
	if error != OK:
		return null
	return document.generate_scene(state)
