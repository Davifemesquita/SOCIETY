class_name LineChart
extends Control
## Gráfico de linhas das estatísticas (seção 10, gráficos históricos): uma ou mais séries com a
## mesma escala, eixo do zero, o maior e o menor valor escritos ao lado e a legenda embaixo. O eixo
## horizontal é o tempo (uma amostra por history_interval_s). Só desenha.

const PADDING := Vector2(64, 14)
const LEGEND_HEIGHT := 22.0

var _series: Array[PackedFloat32Array] = []
var _colors: Array[Color] = []
var _names: Array[String] = []
var _span_text: String = ""


func _init() -> void:
	custom_minimum_size = Vector2(520, 200)
	mouse_filter = Control.MOUSE_FILTER_PASS


## Troca as séries (cada uma com a cor e o nome da legenda) e o texto do período mostrado.
func set_series(series: Array[PackedFloat32Array], colors: Array[Color], names: Array[String], span_text: String) -> void:
	_series = series
	_colors = colors
	_names = names
	_span_text = span_text
	queue_redraw()


func sample_count() -> int:
	var count := 0
	for values: PackedFloat32Array in _series:
		count = maxi(count, values.size())
	return count


func _draw() -> void:
	var font := get_theme_default_font()
	var plot := Rect2(Vector2(PADDING.x, PADDING.y), size - Vector2(PADDING.x + 12.0, PADDING.y * 2.0 + LEGEND_HEIGHT))
	draw_rect(plot, Color("f7eed6"))
	draw_rect(plot, UiPalette.INK_FAINT, false, 1.0)
	var count := sample_count()
	if count < 2:
		draw_string(font, plot.get_center() - Vector2(80, 0), tr("CHART_NO_DATA"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiPalette.INK_SOFT)
		_legend(font, plot)
		return
	var low := 0.0
	var high := 0.0
	for values: PackedFloat32Array in _series:
		for value: float in values:
			low = minf(low, value)
			high = maxf(high, value)
	if is_equal_approx(low, high):
		high = low + 1.0
	var bounds := Rect2(0.0, low, float(count - 1), high - low)
	if low < 0.0:
		var zero := _to_point(plot, bounds, 0, 0.0)
		draw_dashed_line(Vector2(plot.position.x, zero.y), Vector2(plot.end.x, zero.y), UiPalette.INK_FAINT, 1.0, 4.0)
	draw_string(font, Vector2(4, plot.position.y + 12), _number(high), HORIZONTAL_ALIGNMENT_LEFT, PADDING.x - 8, 13, UiPalette.INK_SOFT)
	draw_string(font, Vector2(4, plot.end.y), _number(low), HORIZONTAL_ALIGNMENT_LEFT, PADDING.x - 8, 13, UiPalette.INK_SOFT)
	for s: int in _series.size():
		var values := _series[s]
		var points := PackedVector2Array()
		var first := count - values.size()
		for i: int in values.size():
			points.append(_to_point(plot, bounds, first + i, values[i]))
		if points.size() >= 2:
			draw_polyline(points, _colors[s], 2.5, true)
	_legend(font, plot)


## Ponto da amostra no gráfico: bounds guarda o número de intervalos (x), o menor valor (y) e a
## faixa de valores (altura).
static func _to_point(plot: Rect2, bounds: Rect2, index: int, value: float) -> Vector2:
	return Vector2(plot.position.x + plot.size.x * index / bounds.size.x,
			plot.end.y - plot.size.y * (value - bounds.position.y) / bounds.size.y)


func _legend(font: Font, plot: Rect2) -> void:
	var x := plot.position.x
	var y := plot.end.y + LEGEND_HEIGHT - 4.0
	for s: int in _names.size():
		draw_rect(Rect2(x, y - 10.0, 14.0, 4.0), _colors[s])
		draw_string(font, Vector2(x + 18.0, y), _names[s], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiPalette.INK)
		x += 26.0 + font.get_string_size(_names[s], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	if not _span_text.is_empty():
		draw_string(font, Vector2(plot.end.x - 180.0, y), _span_text, HORIZONTAL_ALIGNMENT_RIGHT, 180.0, 14, UiPalette.INK_SOFT)


static func _number(value: float) -> String:
	return Fmt.integer(value) if absf(value) >= 10.0 else Fmt.decimal(value, 2)
