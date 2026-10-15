extends Node
## Salvar e carregar em JSON versionado e compactado, com miniatura opcional em PNG.
## Nunca em .tres/.res: Resource vindo de arquivo do usuário pode executar script.
## O JSON usa JSON.from_native sem objetos, que preserva int, vetores e StringName e recusa
## qualquer Object na volta. Float vai como os 8 bytes em hexadecimal: o from_native grava só
## 15 dígitos e o estado não voltaria idêntico.

## Versão do formato. Ao mudar o formato, some 1 e acrescente a migração em migrations.
const SAVE_VERSION := 12
const SAVE_EXTENSION := ".save"
const THUMBNAIL_EXTENSION := ".png"
## Resumo do save para a tela de carregar (nome, data, dia, população, dinheiro), em JSON ao lado,
## para listar os slots sem abrir cada save inteiro.
const INFO_EXTENSION := ".info.json"
const DEFAULT_DIR := "user://saves"
const _SLOT_PATTERN := "^[a-z0-9_-]{1,64}$"
const _FLOAT_TAG := "$f64"

## migrations[i] leva os dados da versão i + 1 para a i + 2.
var migrations: Array[Callable] = SaveMigrations.all()
var save_dir: String = DEFAULT_DIR

var _slot_regex := RegEx.create_from_string(_SLOT_PATTERN)


func is_valid_slot(slot: String) -> bool:
	return _slot_regex.search(slot) != null


func slot_path(slot: String) -> String:
	return save_dir.path_join(slot + SAVE_EXTENSION)


func thumbnail_path(slot: String) -> String:
	return save_dir.path_join(slot + THUMBNAIL_EXTENSION)


func info_path(slot: String) -> String:
	return save_dir.path_join(slot + INFO_EXTENSION)


## Nome de slot a partir do nome que o jogador digitou: minúsculas sem acento, espaço vira "_" e o
## resto fora de [a-z0-9_-] some. Vazio se não sobrar nada.
static func slot_from_name(display_name: String) -> String:
	var plain := display_name.strip_edges().to_lower()
	var from := "áàâãäéèêëíìîïóòôõöúùûüçñ"
	var to := "aaaaaeeeeiiiiooooouuuucn"
	var result := ""
	for character: String in plain:
		var at := from.find(character)
		if at >= 0:
			character = to[at]
		if character == " ":
			character = "_"
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character in ["_", "-"]:
			result += character
	return result.left(64)


## Grava o estado no slot. A miniatura e o resumo (info) são opcionais.
func save_game(slot: String, state: Dictionary, thumbnail: Image = null, info: Dictionary = {}) -> Error:
	if not is_valid_slot(slot):
		return _fail(slot, "nome de slot inválido", ERR_INVALID_PARAMETER)
	var dir_error := DirAccess.make_dir_recursive_absolute(save_dir)
	if dir_error != OK:
		return _fail(slot, "não foi possível criar a pasta de saves", dir_error)
	var envelope := {
		"save_version": SAVE_VERSION,
		"game_version": str(ProjectSettings.get_setting("application/config/version", "")),
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"state": state,
	}
	var file := FileAccess.open_compressed(slot_path(slot), FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if file == null:
		return _fail(slot, "não foi possível abrir o arquivo", FileAccess.get_open_error())
	file.store_string(JSON.stringify(JSON.from_native(pack_floats(envelope))))
	file.close()
	if thumbnail != null:
		var png_error := thumbnail.save_png(thumbnail_path(slot))
		if png_error != OK:
			return _fail(slot, "não foi possível gravar a miniatura", png_error)
	var summary := info.duplicate()
	summary["saved_at_unix"] = envelope["saved_at_unix"]
	summary["save_version"] = SAVE_VERSION
	var info_file := FileAccess.open(info_path(slot), FileAccess.WRITE)
	if info_file != null:
		info_file.store_string(JSON.stringify(summary))
		info_file.close()
	EventBus.game_saved.emit(slot)
	return OK


## Lê o slot e devolve o estado já migrado para a versão atual, ou {} se falhar.
func load_game(slot: String) -> Dictionary:
	if not is_valid_slot(slot):
		_fail(slot, "nome de slot inválido", ERR_INVALID_PARAMETER)
		return {}
	var file := FileAccess.open_compressed(slot_path(slot), FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if file == null:
		_fail(slot, "save não encontrado", FileAccess.get_open_error())
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		_fail(slot, "save corrompido", ERR_PARSE_ERROR)
		return {}
	var envelope: Variant = unpack_floats(JSON.to_native(json.data))
	if not envelope is Dictionary:
		_fail(slot, "save sem estado", ERR_INVALID_DATA)
		return {}
	var data: Dictionary = envelope
	var raw_state: Variant = data.get("state")
	var raw_version: Variant = data.get("save_version")
	if not raw_state is Dictionary or not raw_version is int:
		_fail(slot, "save sem estado", ERR_INVALID_DATA)
		return {}
	var version: int = raw_version
	var saved_state: Dictionary = raw_state
	if version < 1 or version > SAVE_VERSION:
		_fail(slot, "versão de save não suportada: %d" % version, ERR_INVALID_DATA)
		return {}
	var state := migrate(saved_state, version, migrations)
	EventBus.game_loaded.emit(slot)
	return state


## Aplica, em ordem, as migrações da versão from_version até a atual.
static func migrate(state: Dictionary, from_version: int, steps: Array[Callable]) -> Dictionary:
	var current := state
	for i: int in range(from_version - 1, steps.size()):
		current = steps[i].call(current)
	return current


## Troca cada float por {"$f64": bytes em hexadecimal}, para a volta ser exata.
static func pack_floats(value: Variant) -> Variant:
	if value is float:
		var number: float = value
		return {_FLOAT_TAG: PackedFloat64Array([number]).to_byte_array().hex_encode()}
	if value is Dictionary:
		var source: Dictionary = value
		var packed := {}
		for key: Variant in source:
			packed[key] = pack_floats(source[key])
		return packed
	if value is Array:
		var items: Array = value
		var packed_items := []
		for item: Variant in items:
			packed_items.append(pack_floats(item))
		return packed_items
	return value


static func unpack_floats(value: Variant) -> Variant:
	if value is Dictionary:
		var source: Dictionary = value
		var tagged: Variant = source.get(_FLOAT_TAG)
		if source.size() == 1 and tagged is String:
			var hex: String = tagged
			var bytes := hex.hex_decode()
			return bytes.to_float64_array()[0] if bytes.size() == 8 else null
		var unpacked := {}
		for key: Variant in source:
			unpacked[key] = unpack_floats(source[key])
		return unpacked
	if value is Array:
		var items: Array = value
		var unpacked_items := []
		for item: Variant in items:
			unpacked_items.append(unpack_floats(item))
		return unpacked_items
	return value


## Resumo do slot (só texto e números; chave estranha é ignorada). Sem o arquivo, só a data do save.
func read_info(slot: String) -> Dictionary:
	var result := {"saved_at_unix": FileAccess.get_modified_time(slot_path(slot))}
	if not is_valid_slot(slot) or not FileAccess.file_exists(info_path(slot)):
		return result
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(info_path(slot)))
	if parsed is Dictionary:
		var data: Dictionary = parsed
		for key: Variant in data:
			var value: Variant = data[key]
			if key is String and (value is String or value is float or value is int):
				result[key] = value
	return result


## Miniatura do slot, ou null.
func read_thumbnail(slot: String) -> Image:
	if not is_valid_slot(slot) or not FileAccess.file_exists(thumbnail_path(slot)):
		return null
	return Image.load_from_file(thumbnail_path(slot))


## Apaga o save, a miniatura e o resumo do slot.
func delete_slot(slot: String) -> Error:
	if not is_valid_slot(slot):
		return ERR_INVALID_PARAMETER
	for path: String in [slot_path(slot), thumbnail_path(slot), info_path(slot)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	return OK


func has_slot(slot: String) -> bool:
	return is_valid_slot(slot) and FileAccess.file_exists(slot_path(slot))


## Slots existentes, do mais recente para o mais antigo.
func list_slots() -> PackedStringArray:
	var entries: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(save_dir):
		return PackedStringArray()
	for file_name: String in DirAccess.get_files_at(save_dir):
		if file_name.ends_with(SAVE_EXTENSION):
			var path := save_dir.path_join(file_name)
			entries.append({"slot": file_name.get_basename(), "mtime": FileAccess.get_modified_time(path)})
	entries.sort_custom(_newer_first)
	var slots := PackedStringArray()
	for entry: Dictionary in entries:
		slots.append(str(entry["slot"]))
	return slots


static func _newer_first(a: Dictionary, b: Dictionary) -> bool:
	var a_time: int = a["mtime"]
	var b_time: int = b["mtime"]
	return a_time > b_time


func _fail(slot: String, reason: String, code: Error) -> Error:
	push_warning("SaveSystem [%s]: %s (%s)" % [slot, reason, error_string(code)])
	EventBus.save_failed.emit(slot, reason)
	return code
