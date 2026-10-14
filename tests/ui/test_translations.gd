extends GdUnitTestSuite
## Todo texto do jogo é chave de tradução, com pt-BR e inglês preenchidos.

const CSV_PATH := "res://ui/translations/strings.csv"


func _rows() -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	var header := file.get_csv_line()
	assert_array(Array(header)).is_equal(["keys", "pt_BR", "en"])
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() > 1:
			rows.append(row)
	return rows


func test_every_key_has_both_languages() -> void:
	var rows := _rows()
	assert_int(rows.size()).is_greater(0)
	for row: PackedStringArray in rows:
		assert_int(row.size()).is_equal(3)
		assert_str(row[1].strip_edges()).override_failure_message("sem pt_BR: " + row[0]).is_not_empty()
		assert_str(row[2].strip_edges()).override_failure_message("sem en: " + row[0]).is_not_empty()


func test_keys_are_unique_and_upper_snake_case() -> void:
	var seen: Dictionary[String, bool] = {}
	var pattern := RegEx.create_from_string("^[A-Z][A-Z0-9_]*$")
	for row: PackedStringArray in _rows():
		assert_object(pattern.search(row[0])).override_failure_message("chave fora do padrão: " + row[0]).is_not_null()
		assert_bool(seen.has(row[0])).override_failure_message("chave repetida: " + row[0]).is_false()
		seen[row[0]] = true


func test_server_translates_in_both_locales() -> void:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("pt_BR")
	assert_str(TranslationServer.translate("BOOT_NEW_GAME")).is_equal("Novo jogo")
	TranslationServer.set_locale("en")
	assert_str(TranslationServer.translate("BOOT_NEW_GAME")).is_equal("New game")
	TranslationServer.set_locale(previous)


## Toda chave escrita no código (texto entre aspas no formato CHAVE_DE_TRADUCAO) existe no CSV, e
## as chaves montadas por partes também: teclas das opções, barramentos de áudio, camadas de mapa e
## as dicas dos botões (<texto>_TIP).
func test_every_key_used_in_the_code_exists() -> void:
	var keys: Dictionary[String, bool] = {}
	for row: PackedStringArray in _rows():
		keys[row[0]] = true
	# nome de variável de ambiente (OS.get_environment) tem o mesmo formato, mas não é texto da tela
	var literal := RegEx.create_from_string("(?<!get_environment\\()\"([A-Z][A-Z0-9]*_[A-Z0-9_]+)\"")
	var missing: PackedStringArray = []
	for path: String in _scripts("res://"):
		for found: RegExMatch in literal.search_all(FileAccess.get_file_as_string(path)):
			var key := found.get_string(1)
			if not keys.has(key) and not key.ends_with("_") and not missing.has(key):
				missing.append("%s (%s)" % [key, path.get_file()])
	for action: StringName in InputActions.remappable():
		if not keys.has("ACTION_" + String(action).to_upper()):
			missing.append("ACTION_" + String(action).to_upper())
	for bus: StringName in Settings.AUDIO_BUSES:
		if not keys.has("AUDIO_BUS_" + String(bus).to_upper()):
			missing.append("AUDIO_BUS_" + String(bus).to_upper())
	for key: String in MapOverlays.KEYS.values():
		for suffix: String in ["", "_TIP", "_LEGEND"]:
			if not keys.has(key + suffix):
				missing.append(key + suffix)
	assert_array(Array(missing)).is_empty()


func _scripts(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		if sub in ["addons", ".godot", "tests", "exportado", "reports"]:
			continue
		found.append_array(_scripts(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".gd") or file.ends_with(".tscn") or file.ends_with(".tres"):
			found.append(dir.path_join(file))
	return found
