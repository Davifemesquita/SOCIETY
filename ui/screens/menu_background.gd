class_name MenuBackground
extends Control
## Fundo do menu principal: papel de carta náutica, moldura de madeira e dourado e a rosa dos ventos. Desde a Fase 44
## sem a grade de latitudes a cada 96 px (lia como papel milimetrado): a carta gravada de um arquipélago de semente fixa
## (a mesma gravura da janela de rotas), desbotada no papel, derivando devagar — parada com "reduzir movimento". A carta
## sai de uma thread (ArchipelagoPreview) enquanto o menu já está na tela; até lá, só o papel. Sem tela (testes), só o
## papel.

const CHART_SEED := 1840
const CHART_SIZE := 0
const CHART_ALPHA := 0.32
## A deriva: amplitude (fração do lado) e período (s).
const DRIFT := 0.015
const DRIFT_S := 90.0

var _preview: ArchipelagoPreview
var _chart: ImageTexture
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)
	if not SceneFader.is_instant():
		_preview = ArchipelagoPreview.new(CHART_SEED, CHART_SIZE, GameConfig.get_default(), GameData.get_default(),
				ArchipelagoMap.ENGRAVE_SCALE)
		_preview.start(true)


func _process(delta: float) -> void:
	if _preview != null and _chart == null and _preview.poll():
		var image := _preview.image()
		if image != null:
			_chart = ImageTexture.create_from_image(image)
			queue_redraw()
	if _chart != null and not SceneFader.still():
		_time += delta
		queue_redraw()


func _exit_tree() -> void:
	if _preview != null:
		ArchipelagoPreview.adopt(_preview)


## A carta já está pronta (testes).
func has_chart() -> bool:
	return _chart != null


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.PAPER)
	if _chart != null:
		var chart_size := Vector2(_chart.get_size())
		# o arquipélago inteiro, um pouco além da tela (a deriva não mostra a borda da carta)
		var cover := minf(size.x / chart_size.x, size.y / chart_size.y) * 1.25
		var drawn := chart_size * cover
		var drift := Vector2(sin(_time * TAU / DRIFT_S), cos(_time * TAU / (DRIFT_S * 1.3))) * size * DRIFT
		draw_texture_rect(_chart, Rect2((size - drawn) * 0.5 + drift, drawn), false, Color(1.0, 1.0, 1.0, CHART_ALPHA))
		draw_texture_rect(ArchipelagoMap.grain(), Rect2(Vector2.ZERO, size), false, Color(1.0, 1.0, 1.0, 0.5))
	var center := Vector2(size.x * 0.78, size.y * 0.74)
	var radius := minf(size.x, size.y) * 0.22
	draw_arc(center, radius, 0.0, TAU, 96, Color(UiPalette.WOOD, 0.25), 2.0)
	draw_arc(center, radius * 0.82, 0.0, TAU, 96, Color(UiPalette.WOOD, 0.18), 1.0)
	for i: int in 16:
		var direction := Vector2.UP.rotated(i * TAU / 16.0)
		var length := radius * (1.0 if i % 4 == 0 else (0.7 if i % 2 == 0 else 0.45))
		draw_line(center, center + direction * length, Color(UiPalette.WOOD, 0.2), 1.5)
	for i: int in 4:
		var direction := Vector2.UP.rotated(i * PI * 0.5)
		var side := direction.orthogonal() * radius * 0.08
		var color := Color(UiPalette.BURGUNDY, 0.35) if i == 0 else Color(UiPalette.WOOD, 0.3)
		draw_colored_polygon(PackedVector2Array([center + direction * radius, center + side, center - side]), color)
	var frame := Rect2(Vector2(14, 14), size - Vector2(28, 28))
	draw_rect(frame, UiPalette.WOOD, false, 10.0)
	draw_rect(frame.grow(-9.0), UiPalette.GOLD, false, 3.0)
