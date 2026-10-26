class_name TerrainV2Params
extends Resource
## Parâmetros do gerador de ilhas v2 (Fase 45, `terrain_version = 2`): contorno orgânico por união suave de elipses
## giradas, warp de domínio em dois níveis, costa fractal de rugosidade variável, ilhotas e bancos de areia, e patamares
## por ruído celular com altura crescente para o interior. Mudou um número daqui, as ilhas v2 mudam: as assinaturas do
## teste dourado da v2 conferem (os saves v2 refazem o terreno pela semente).

const DEFAULT_PATH := "res://data/terrain_v2.tres"

## Elipses que formam a ilha (5 a 7), o quanto os centros se afastam do meio (fração da meia largura), os raios (fração)
## e o alongamento máximo.
@export var lobes_min: int = 5
@export var lobes_max: int = 7
@export var lobe_spread: float = 0.42
@export var lobe_radius: Vector2 = Vector2(0.32, 0.46)
@export var lobe_stretch: float = 1.4
## Suavidade da união das elipses (maior = mais "derretida").
@export var lobe_blend: float = 0.22
## Até onde uma elipse chega (fração da meia largura): com o warp e a costa, a ilha nunca encosta na borda da grade.
@export var shore: float = 0.9
## Warp de domínio: amplitude (fração da meia largura) e frequência (1/m) de cada nível.
@export var warp_amount: Vector2 = Vector2(0.1, 0.04)
@export var warp_frequency: Vector2 = Vector2(1.0 / 260.0, 1.0 / 70.0)
## Costa fractal: a rugosidade varia pela ilha entre os dois valores (enseadas lisas, cabos recortados).
@export var coast_roughness: Vector2 = Vector2(0.02, 0.08)
@export var coast_frequency: float = 1.0 / 55.0
## Ilhotas em volta (quantas no máximo, raio e altura) e bancos de areia rasos junto à costa.
@export var islets_max: int = 3
@export var islet_radius: Vector2 = Vector2(0.05, 0.1)
@export var islet_height_m: float = 1.1
@export var sandbank_chance: float = 0.35
@export var sandbank_depth_m: float = -0.25
## Patamares: os níveis (m), a fração plana de cada degrau, o quanto o ruído celular desloca o nível de cada região
## (patamares não concêntricos), a frequência dele, a subida para o interior e a maior diferença entre cantos vizinhos.
@export var terrace_levels_m: PackedFloat32Array = PackedFloat32Array([1.2, 3.6, 6.6, 10.4, 15.0])
@export var terrace_flat_fraction: float = 0.72
@export var plateau_jitter_m: float = 0.9
@export var plateau_frequency: float = 1.0 / 150.0
@export var inland_rise: float = 0.9
@export var plain_width: float = 0.42
@export var max_corner_step_m: float = 2.5
## Ondulação suave dentro do patamar (cabe na tolerância de construção de 0,5 m num lote de 3 × 3).
@export var undulation_m: float = 0.16
@export var undulation_frequency: float = 1.0 / 48.0
## Faixa da descida até o fundo do mar na praia e na falésia (fração da métrica).
@export var beach_band: float = 0.06
@export var cliff_band: float = 0.012


static var _default: TerrainV2Params


static func get_default() -> TerrainV2Params:
	if _default == null:
		_default = load(DEFAULT_PATH) as TerrainV2Params if ResourceLoader.exists(DEFAULT_PATH) else TerrainV2Params.new()
	return _default


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if lobes_min < 1 or lobes_max < lobes_min:
		problems.append("TerrainV2Params: lobes_min/lobes_max inválidos")
	if shore <= 0.3 or shore >= 1.0:
		problems.append("TerrainV2Params: shore deve ficar entre 0,3 e 1")
	if terrace_levels_m.size() < 2:
		problems.append("TerrainV2Params: precisa de pelo menos dois patamares")
	if undulation_m < 0.0 or undulation_m > 0.25:
		problems.append("TerrainV2Params: undulation_m deve ficar entre 0 e 0,25 (tolerância de construção)")
	return problems
