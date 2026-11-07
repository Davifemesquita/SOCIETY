class_name OilFields
extends RefCounted
## Campos de petróleo (Fase 70): em cada ilha temperada, COUNT células onde cabe o poço (um bloco de terra de
## WELL_SIDE × WELL_SIDE, plano como a obra pede, sem rio), sorteadas pela semente da ilha e longe uma da outra. Saem
## depois da assinatura do terreno (não a mudam) e não vão no save: a mesma semente dá os mesmos campos.

const COUNT := 2
const WELL_SIDE := 3
const TRIES := 400
## Distância mínima (em células) entre dois campos da mesma ilha.
const SPACING_CELLS := 12


static func spots(grid: IslandGrid, seed_value: int, config: GameConfig) -> PackedInt32Array:
	var result := PackedInt32Array()
	if grid.flat:
		return result
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, &"petroleo"])
	for attempt: int in TRIES:
		if result.size() >= COUNT:
			break
		var corner := Vector2i(rng.randi_range(0, grid.size.x - WELL_SIDE), rng.randi_range(0, grid.size.y - WELL_SIDE))
		var area := Rect2i(corner, Vector2i(WELL_SIDE, WELL_SIDE))
		if not grid.area_is_land(area) or grid.area_relief(area) > config.max_build_height_delta_m:
			continue
		var center := corner + Vector2i.ONE
		var close := false
		for spot: int in result:
			if Vector2(grid.cell_at(spot)).distance_to(Vector2(center)) < SPACING_CELLS:
				close = true
				break
		if not close:
			result.append(grid.index(center))
	return result
