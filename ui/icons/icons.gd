class_name Icons
extends RefCounted
## Sistema central de ícones (seção 10): um atlas (icons.png, gerado por tools/build_icons.gd) e
## nomes padronizados: good_<id>, building_<id>, tier_<id>, need_<id>, ship_<id>, action_<nome>,
## hud_<nome>, option_<nome>, overlay_<nome>, state_<nome>, notice_<nome> e status_<good|partial|bad>.
## Ícone que falta devolve a interrogação (status_missing) e avisa uma vez.

const ATLAS_PATH := "res://ui/icons/icons.png"
const INDEX_PATH := "res://ui/icons/icons.json"
const MISSING := "status_missing"

static var _atlas: Texture2D
static var _cell: int = 128
static var _index: Dictionary = {}
static var _cache: Dictionary[String, AtlasTexture] = {}
static var _warned: Dictionary[String, bool] = {}


static func _load() -> void:
	if _atlas != null:
		return
	_atlas = load(ATLAS_PATH)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
	if parsed is Dictionary:
		var data: Dictionary = parsed
		var cell: Variant = data.get("cell")
		var icons: Variant = data.get("icons")
		if cell is float:
			var cell_value: float = cell
			_cell = roundi(cell_value)
		if icons is Dictionary:
			_index = icons


static func has(icon_name: String) -> bool:
	_load()
	return _index.has(icon_name)


static func names() -> Array[String]:
	_load()
	var result: Array[String] = []
	result.assign(_index.keys())
	return result


## O ícone pelo nome padronizado.
static func get_icon(icon_name: String) -> Texture2D:
	_load()
	if _cache.has(icon_name):
		return _cache[icon_name]
	var key := icon_name
	if not _index.has(key):
		if not _warned.has(icon_name):
			_warned[icon_name] = true
			push_warning("Icons: ícone sem desenho: " + icon_name)
		key = MISSING
	var at: Array = _index[key]
	var x: float = at[0]
	var y: float = at[1]
	var texture := AtlasTexture.new()
	texture.atlas = _atlas
	texture.region = Rect2(x, y, _cell, _cell)
	_cache[icon_name] = texture
	return texture


static func good(id: StringName) -> Texture2D:
	return get_icon("good_" + id)


static func building(id: StringName) -> Texture2D:
	return get_icon("building_" + id)


static func tier(id: StringName) -> Texture2D:
	return get_icon("tier_" + id)


static func need(id: StringName) -> Texture2D:
	return get_icon("need_" + id)


static func action(id: String) -> Texture2D:
	return get_icon("action_" + id)


static func status(value: UiPalette.Status) -> Texture2D:
	var names: Array[String] = ["status_good", "status_partial", "status_bad", "status_good"]
	return get_icon(names[value])


## Retrato (placeholder até a arte final): tier_<id>, advisor ou trader.
static func portrait(id: String) -> Texture2D:
	var path := "res://ui/portraits/portrait_%s.png" % id
	return load(path) if ResourceLoader.exists(path) else null
