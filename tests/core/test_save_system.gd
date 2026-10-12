extends GdUnitTestSuite
## Salvar e carregar: estado idêntico na volta, versão, migrações e arquivos inválidos.

const SaveSystemScript := preload("res://core/save_system.gd")
const TEST_DIR := "user://test_saves"

var _saves: SaveSystemScript


func before_test() -> void:
	_saves = auto_free(SaveSystemScript.new())
	_saves.save_dir = TEST_DIR


func after_test() -> void:
	if not DirAccess.dir_exists_absolute(TEST_DIR):
		return
	for file_name: String in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR.path_join(file_name))
	DirAccess.remove_absolute(TEST_DIR)


func _sample_state() -> Dictionary:
	return {
		"clock": {"tick_count": 1234, "speed_index": 1, "resume_speed_index": 1},
		"money": 50000,
		"tax_rate": 0.6,
		"good": &"fish",
		"cells": PackedInt32Array([0, 7, 7, -1]),
		"origin": Vector2i(12, -3),
		"islands": [{"name": "inicial", "fertile": true, "deposits": ["clay"]}],
		"nothing": null,
	}


func test_save_then_load_returns_identical_state() -> void:
	var state := _sample_state()
	assert_int(_saves.save_game("slot_1", state)).is_equal(OK)
	var loaded := _saves.load_game("slot_1")
	assert_bool(loaded == state).is_true()
	assert_int(typeof(loaded["money"])).is_equal(TYPE_INT)
	assert_int(typeof(loaded["origin"])).is_equal(TYPE_VECTOR2I)
	assert_int(typeof(loaded["good"])).is_equal(TYPE_STRING_NAME)


func test_file_is_compressed_versioned_json() -> void:
	_saves.save_game("slot_1", _sample_state())
	var file := FileAccess.open_compressed(_saves.slot_path("slot_1"), FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	var envelope: Variant = JSON.to_native(JSON.parse_string(file.get_as_text()))
	assert_bool(envelope is Dictionary).is_true()
	var data: Dictionary = envelope
	assert_int(data["save_version"]).is_equal(SaveSystemScript.SAVE_VERSION)
	var raw := FileAccess.get_file_as_bytes(_saves.slot_path("slot_1"))
	assert_bool(raw.get_string_from_utf8().begins_with("{")).is_false()


func test_thumbnail_is_saved_as_png() -> void:
	var image := Image.create_empty(64, 36, false, Image.FORMAT_RGB8)
	image.fill(Color.DARK_GOLDENROD)
	_saves.save_game("slot_1", {}, image)
	var back := Image.load_from_file(_saves.thumbnail_path("slot_1"))
	assert_vector(back.get_size()).is_equal(Vector2i(64, 36))


func test_invalid_slot_names_are_refused() -> void:
	assert_int(_saves.save_game("../fora", {})).is_equal(ERR_INVALID_PARAMETER)
	assert_int(_saves.save_game("", {})).is_equal(ERR_INVALID_PARAMETER)
	assert_int(_saves.save_game("Com Espaço", {})).is_equal(ERR_INVALID_PARAMETER)
	assert_dict(_saves.load_game("../fora")).is_empty()


func test_missing_and_corrupt_saves_load_empty() -> void:
	assert_dict(_saves.load_game("nao_existe")).is_empty()
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open_compressed(_saves.slot_path("quebrado"), FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	file.store_string("{isto não é json")
	file.close()
	assert_dict(_saves.load_game("quebrado")).is_empty()


func test_objects_in_file_are_never_instantiated() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var hostile := {"save_version": 1, "state": {"x": {"type": "Object", "class": "Node", "props": []}}}
	var file := FileAccess.open_compressed(_saves.slot_path("hostil"), FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	file.store_string(JSON.stringify(hostile))
	file.close()
	assert_dict(_saves.load_game("hostil")).is_empty()


func test_newer_save_version_is_refused() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var envelope := {"save_version": SaveSystemScript.SAVE_VERSION + 1, "state": {}}
	var file := FileAccess.open_compressed(_saves.slot_path("futuro"), FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	file.store_string(JSON.stringify(JSON.from_native(envelope)))
	file.close()
	assert_dict(_saves.load_game("futuro")).is_empty()


func test_migrations_run_in_order_from_saved_version() -> void:
	var steps: Array[Callable] = [_migrate_1_to_2, _migrate_2_to_3]
	assert_str(str(SaveSystemScript.migrate({}, 1, steps)["log"])).is_equal("1>2,2>3")
	assert_str(str(SaveSystemScript.migrate({}, 2, steps)["log"])).is_equal(",2>3")
	assert_dict(SaveSystemScript.migrate({"a": 1}, 3, steps)).is_equal({"a": 1})


static func _migrate_1_to_2(state: Dictionary) -> Dictionary:
	state["log"] = str(state.get("log", "")) + "1>2"
	return state


static func _migrate_2_to_3(state: Dictionary) -> Dictionary:
	state["log"] = str(state.get("log", "")) + ",2>3"
	return state


func test_current_version_has_matching_migration_count() -> void:
	assert_int(_saves.migrations.size()).is_equal(SaveSystemScript.SAVE_VERSION - 1)


func test_list_slots_newest_first() -> void:
	_saves.save_game("antigo", {})
	OS.delay_msec(1100)
	_saves.save_game("novo", {})
	assert_array(Array(_saves.list_slots())).is_equal(["novo", "antigo"])
