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
	assert_str(TranslationServer.translate("BOOT_PHASE")).is_equal("Fase 0 — fundação")
	TranslationServer.set_locale("en")
	assert_str(TranslationServer.translate("BOOT_PHASE")).is_equal("Phase 0 — foundation")
	TranslationServer.set_locale(previous)
