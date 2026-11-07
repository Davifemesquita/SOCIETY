extends SceneTree
## Gera o atlas de ícones (seção 14): cada SVG do game-icons.net (assets/source/game-icons/) é
## recolorido e emoldurado no estilo do jogo, em 128 px, e todos vão para ui/icons/icons.png, com o
## índice em ui/icons/icons.json. A lista (nome padronizado, origem, estilo) está em
## tools/icons/icon_list.csv; os SVGs se baixam com tools/icons/fetch_icons.sh.
## Gera também os indicadores de estado. Os retratos saíram daqui na Fase 51 (tools/build_portraits.gd, pinturas).
##   tools/godot.sh godot --headless --path . --script res://tools/build_icons.gd

const LIST := "res://tools/icons/icon_list.csv"
const SOURCES := "res://assets/source/game-icons/"
const ATLAS := "res://ui/icons/icons.png"
const INDEX := "res://ui/icons/icons.json"
const CELL := 128
const COLUMNS := 16

## Moldura e cores de cada estilo: fundo, aro, contorno, tinta do desenho e a forma.
const STYLES := {
	"good": {"fill": UiPalette.PAPER, "rim": UiPalette.GOLD, "edge": UiPalette.WOOD, "ink": UiPalette.INK, "shape": "circle"},
	"need": {"fill": UiPalette.PAPER_DARK, "rim": UiPalette.INK_SOFT, "edge": UiPalette.WOOD, "ink": UiPalette.INK, "shape": "circle"},
	"building": {"fill": UiPalette.WOOD_LIGHT, "rim": UiPalette.GOLD, "edge": UiPalette.WOOD, "ink": UiPalette.PAPER, "shape": "square"},
	"tier": {"fill": UiPalette.BURGUNDY, "rim": UiPalette.GOLD, "edge": UiPalette.WOOD, "ink": UiPalette.PAPER, "shape": "circle"},
	"state": {"fill": UiPalette.ALERT, "rim": UiPalette.PAPER, "edge": UiPalette.WOOD, "ink": UiPalette.PAPER, "shape": "circle"},
	"notice": {"fill": UiPalette.WOOD, "rim": UiPalette.GOLD, "edge": UiPalette.INK, "ink": UiPalette.GOLD_LIGHT, "shape": "circle"},
	"action": {"ink": UiPalette.INK, "shape": "none"},
	"hud": {"ink": UiPalette.INK, "shape": "none"},
}


func _init() -> void:
	var entries := _read_list()
	var rows := ceili(float(entries.size() + 4) / COLUMNS)
	var atlas := Image.create_empty(COLUMNS * CELL, rows * CELL, false, Image.FORMAT_RGBA8)
	var index := {}
	var slot := 0
	for entry: PackedStringArray in entries:
		var style: Dictionary = STYLES[entry[2]]
		var icon := _icon(entry[1], style)
		if icon == null:
			push_error("build_icons: sem SVG para %s (%s)" % [entry[0], entry[1]])
			continue
		_place(atlas, icon, slot, index, entry[0])
		slot += 1
	for status: String in ["good", "partial", "bad", "missing"]:
		_place(atlas, _status_icon(status), slot, index, "status_" + status)
		slot += 1
	atlas.generate_mipmaps()
	atlas.clear_mipmaps()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ATLAS.get_base_dir()))
	atlas.save_png(ATLAS)
	var file := FileAccess.open(INDEX, FileAccess.WRITE)
	file.store_string(JSON.stringify({"cell": CELL, "icons": index}, "\t", true))
	file.close()
	print("build_icons: %d ícones em %s" % [index.size(), ATLAS])
	quit()


func _read_list() -> Array[PackedStringArray]:
	var entries: Array[PackedStringArray] = []
	var file := FileAccess.open(LIST, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 3 and not row[0].is_empty():
			entries.append(row)
	return entries


func _place(atlas: Image, icon: Image, slot: int, index: Dictionary, name: String) -> void:
	var at := Vector2i(slot % COLUMNS, slot / COLUMNS) * CELL
	atlas.blit_rect(icon, Rect2i(Vector2i.ZERO, icon.get_size()), at)
	index[name] = [at.x, at.y]


## Desenho do SVG na cor dada, sem o quadrado preto de fundo do game-icons.
static func glyph(source: String, color: Color, size: int) -> Image:
	if source.begins_with("@"):
		return _drawn_sign(source.substr(1), color, size)
	var path := SOURCES + source + ".svg"
	if not FileAccess.file_exists(path):
		return null
	var svg := FileAccess.get_file_as_string(path)
	svg = svg.replace('<path d="M0 0h512v512H0z"/>', "")
	svg = svg.replace('fill="#fff"', 'fill="#%s"' % color.to_html(false))
	var image := Image.new()
	if image.load_svg_from_string(svg, size / 512.0) != OK:
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image


func _icon(source: String, style: Dictionary) -> Image:
	var shape: String = style["shape"]
	var ink: Color = style["ink"]
	var inner := CELL - 8 if shape == "none" else 74
	var drawn := glyph(source, ink, inner)
	if drawn == null:
		return null
	var image := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
	if shape != "none":
		var fill: Color = style["fill"]
		var rim: Color = style["rim"]
		var edge: Color = style["edge"]
		_frame(image, shape, fill, rim, edge)
	var at := (Vector2i(CELL, CELL) - drawn.get_size()) / 2
	image.blend_rect(drawn, Rect2i(Vector2i.ZERO, drawn.get_size()), at)
	return image


## Medalhão (círculo) ou placa (quadrado arredondado): contorno escuro, aro dourado e fundo,
## com borda suavizada pela distância até a forma.
static func _frame(image: Image, shape: String, fill: Color, rim: Color, edge: Color) -> void:
	var half := CELL * 0.5
	var outer := half - 3.0
	for y: int in CELL:
		for x: int in CELL:
			var p := Vector2(x + 0.5 - half, y + 0.5 - half)
			var d := p.length() - outer if shape == "circle" else _rounded_box(p, outer, 18.0)
			var color := fill
			if d > -4.0:
				color = edge
			elif d > -11.0:
				color = rim
			elif d > -13.0:
				color = edge
			var alpha := clampf(0.5 - d, 0.0, 1.0)
			if alpha > 0.0:
				image.set_pixel(x, y, Color(color, alpha))


## Sinais desenhados aqui (o "mais" e o "menos" do game-icons vêm dentro de um círculo preto).
static func _drawn_sign(sign_name: String, color: Color, size: int) -> Image:
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var half := size * 0.5
	var arm := size * 0.4
	var thickness := size * 0.09
	for y: int in size:
		for x: int in size:
			var p := Vector2(x + 0.5 - half, y + 0.5 - half)
			var horizontal := _rounded_box_rect(p, Vector2(arm, thickness))
			var d := horizontal if sign_name == "minus" else minf(horizontal, _rounded_box_rect(p, Vector2(thickness, arm)))
			var alpha := clampf(0.5 - d, 0.0, 1.0)
			if alpha > 0.0:
				image.set_pixel(x, y, Color(color, alpha))
	return image


static func _rounded_box_rect(p: Vector2, half_size: Vector2) -> float:
	var q := p.abs() - half_size
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0)


static func _rounded_box(p: Vector2, half_side: float, radius: float) -> float:
	var q := p.abs() - Vector2(half_side - radius, half_side - radius)
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - radius


## Indicadores (branco, pintado pela cor do estado na tela): círculo cheio, triângulo, xis e a
## interrogação do ícone que falta. Formas diferentes para o modo de daltonismo não depender da cor.
static func _status_icon(status: String) -> Image:
	var image := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
	var half := CELL * 0.5
	for y: int in CELL:
		for x: int in CELL:
			var p := Vector2(x + 0.5 - half, y + 0.5 - half)
			var d := 0.0
			match status:
				"good":
					d = p.length() - 46.0
				"partial":
					d = _triangle(p, 52.0)
				"bad":
					var a := absf(p.x - p.y) / sqrt(2.0) - 11.0
					var b := absf(p.x + p.y) / sqrt(2.0) - 11.0
					d = maxf(minf(a, b), p.length() - 54.0)
				_:
					d = absf(p.length() - 44.0) - 7.0
			var alpha := clampf(0.5 - d, 0.0, 1.0)
			if alpha > 0.0:
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return image


static func _triangle(p: Vector2, r: float) -> float:
	var k := sqrt(3.0)
	var q := Vector2(absf(p.x) - r, -(p.y - r * 0.25) + r / k)
	if q.x + k * q.y > 0.0:
		q = Vector2(q.x - k * q.y, -k * q.x - q.y) / 2.0
	q.x -= clampf(q.x, -2.0 * r, 0.0)
	return -q.length() * signf(q.y)

