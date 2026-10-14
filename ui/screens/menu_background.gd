class_name MenuBackground
extends Control
## Fundo do menu principal: papel de carta náutica com a grade de latitudes, uma moldura de
## madeira e dourado e a rosa dos ventos. Só desenha.

const LINE := Color(0.29, 0.19, 0.13, 0.12)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.PAPER)
	var step := 96.0
	var x := fmod(size.x * 0.5, step)
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), LINE, 1.0)
		x += step
	var y := fmod(size.y * 0.5, step)
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), LINE, 1.0)
		y += step
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
