class_name TerrainV3Params
extends TerrainV2Params
## Parâmetros do gerador de ilhas v3 (Fase 52, `terrain_version = 3`), a pedido do dono olhando o Anno 1800 (só a
## ideia; nada de arquivo dele): a ilha alongada sobre uma espinha curva com penínsulas, enseadas fundas cavadas na costa
## com praia larga e água rasa, o resto da costa em falésia com a planície mais alta, e rochedos soltos junto aos cabos.
## O warp, a costa fractal, os patamares e a ondulação vêm dos campos do v2 (herdados). Mudou um número daqui, as ilhas
## v3 mudam: as assinaturas do teste dourado da v3 conferem.

const V3_PATH := "res://data/terrain_v3.tres"

## Espinha: quantas elipses ao longo dela, o comprimento (fração da meia largura, do meio a cada ponta) e a curva.
@export var spine_lobes_min: int = 3
@export var spine_lobes_max: int = 5
@export var spine_length: float = 0.36
@export var spine_bend: float = 0.28
## Penínsulas saindo da espinha (no máximo) e o tamanho delas em relação às elipses da espinha.
@export var side_lobes_max: int = 3
@export var side_lobe_scale: float = 0.7
## Enseadas: quantas, o raio (fração da meia largura), o quanto entram na terra (fração do raio) e a suavidade do corte.
@export var bays_min: int = 2
@export var bays_max: int = 3
@export var bay_radius: Vector2 = Vector2(0.14, 0.24)
@export var bay_inset: float = 0.9
@export var bay_blend: float = 0.08
## A água rasa da enseada (m, acima do fundo do mar).
@export var bay_shallow_m: float = -1.2
## A descida da terra para o mar, em células (não em fração da ilha, como no v2: numa ilha grande a praia do v2 vira uma
## rampa de 15 m que não deixa construir na beira): praia, praia da enseada e falésia.
@export var beach_band_cells: float = 1.5
@export var bay_beach_band_cells: float = 2.5
## (Fase 53: 1,6 em vez de 0,8: com a descida em uma célula a falésia virava a escada da grade de 2 m)
@export var cliff_band_cells: float = 1.6
## Falésia: a faixa do ruído em que a costa passa de praia a falésia (fora das enseadas) e o patamar da planície em cima
## dela (índice em terrace_levels_m).
@export var cliff_noise: Vector2 = Vector2(-0.2, 0.12)
@export var cliff_plain_level: int = 1
## Rochedos: quantos no máximo, o raio (fração da meia largura), a altura (m) e o afastamento da costa.
@export var stacks_max: int = 6
@export var stack_radius: Vector2 = Vector2(0.025, 0.05)
@export var stack_height_m: Vector2 = Vector2(2.5, 7.0)
@export var stack_offshore: Vector2 = Vector2(0.03, 0.1)


static var _v3_default: TerrainV3Params


func _init() -> void:
	lobe_radius = Vector2(0.46, 0.62)
	lobe_stretch = 1.3
	lobe_blend = 0.18
	islets_max = 0
	sandbank_chance = 0.2
	# o interior quase plano, como no Anno: menos patamares, degraus curtos
	terrace_levels_m = PackedFloat32Array([1.2, 3.6, 6.6, 9.6])
	terrace_flat_fraction = 0.82


static func get_v3() -> TerrainV3Params:
	if _v3_default == null:
		_v3_default = load(V3_PATH) as TerrainV3Params if ResourceLoader.exists(V3_PATH) else TerrainV3Params.new()
	return _v3_default


func validate() -> PackedStringArray:
	var problems := super.validate()
	if spine_lobes_min < 2 or spine_lobes_max < spine_lobes_min:
		problems.append("TerrainV3Params: spine_lobes_min/spine_lobes_max inválidos (pelo menos 2)")
	if bays_min < 0 or bays_max < bays_min:
		problems.append("TerrainV3Params: bays_min/bays_max inválidos")
	if cliff_plain_level < 0 or cliff_plain_level >= terrace_levels_m.size():
		problems.append("TerrainV3Params: cliff_plain_level fora de terrace_levels_m")
	if bay_shallow_m >= 0.0:
		problems.append("TerrainV3Params: bay_shallow_m fica abaixo do mar (< 0)")
	return problems
