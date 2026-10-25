class_name GraphicsPresetDef
extends Resource
## Nível de qualidade gráfica (seção 11: baixo, médio, alto e ultra). Só mexe no que se vê: a
## simulação é a mesma em todos. Aplicado pelo GraphicsQuality.

@export var id: StringName
@export var name_key: String

@export_group("Luz e sombra")
## Distância da sombra do sol e o lado do atlas de sombras direcionais (em pixels).
@export var shadow_distance_m: float = 400.0
@export var shadow_atlas_size: int = 4096
## Qualidade do filtro de sombra suave (RenderingServer.ShadowQuality, 0 = dura).
@export var soft_shadow_quality: int = 2
@export var ssao: bool = true
@export var ssil: bool = false
@export var glow: bool = true
## Neblina volumétrica (a de distância fica sempre ligada).
@export var volumetric_fog: bool = false

@export_group("Céu e efeitos")
@export var clouds: bool = false
## Profundidade de campo (o efeito miniatura do zoom de perto).
@export var depth_of_field: bool = false
## Fração das partículas (fumaça, vapor, chuva) em relação ao máximo.
@export var particles_ratio: float = 1.0
@export var decals: bool = true

@export_group("Detalhe")
## Limiar do LOD automático (pixels de erro aceitos; maior = troca antes para o modelo simples).
@export var mesh_lod_threshold: float = 1.0
## Multiplica a distância até onde os detalhes (telhados, portas, chaminés, gaivotas) aparecem.
@export var visibility_scale: float = 1.0
## Fração do teto de pedestres (max_visible_pedestrians) e as luzes de área das janelas.
@export var pedestrian_ratio: float = 1.0
@export var area_lights: int = 12
## Escala de resolução sugerida (abaixo de 1 usa o FSR 2.2, que também é o antisserrilhado).
@export var render_scale: float = 1.0

@export_group("Antisserrilhado")
## Fase 32: AA de tela (Viewport.ScreenSpaceAA: 0 nenhum, 1 FXAA, 2 SMAA), usado quando o FSR 2.2 está desligado. O
## MSAA saiu: trocá-lo em jogo recompila pipelines, e ele não pega a borda recortada do alpha (cercas, folhas).
@export var screen_space_aa: int = Viewport.SCREEN_SPACE_AA_SMAA
## FSR 2.2 também na resolução cheia, como AA temporal (no lugar do AA de tela).
@export var temporal_native: bool = false
## Nitidez do FSR (0 = a mais nítida, 2 = a mais suave; Viewport.fsr_sharpness).
@export var fsr_sharpness: float = 0.2


## Lista o que está fora do intervalo. Vazia quando o nível é válido.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if shadow_distance_m <= 0.0 or shadow_atlas_size < 512:
		problems.append("%s: sombra com distância positiva e atlas de pelo menos 512" % id)
	if particles_ratio < 0.0 or particles_ratio > 1.0 or pedestrian_ratio < 0.0 or pedestrian_ratio > 1.0:
		problems.append("%s: frações de partículas e pedestres entre 0 e 1" % id)
	if visibility_scale <= 0.0 or mesh_lod_threshold <= 0.0 or area_lights < 0:
		problems.append("%s: detalhe com valores positivos" % id)
	if render_scale <= 0.0 or render_scale > 1.0:
		problems.append("%s: escala entre 0 e 1" % id)
	if screen_space_aa < Viewport.SCREEN_SPACE_AA_DISABLED or screen_space_aa >= Viewport.SCREEN_SPACE_AA_MAX \
			or fsr_sharpness < 0.0 or fsr_sharpness > 2.0:
		problems.append("%s: AA de tela de 0 a %d e nitidez do FSR de 0 a 2" % [id, Viewport.SCREEN_SPACE_AA_MAX - 1])
	if not uses_temporal(render_scale) and screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED:
		problems.append("%s: sem antisserrilhado (nem AA de tela nem FSR)" % id)
	return problems


## O FSR 2.2 fica ligado com esta escala? Abaixo de 100% sempre; na cheia, só com temporal_native.
func uses_temporal(scale: float) -> bool:
	return scale < 0.999 or temporal_native


## O AA de tela que vale com esta escala: nenhum quando o FSR já faz o papel.
func screen_aa_for(scale: float) -> Viewport.ScreenSpaceAA:
	return Viewport.SCREEN_SPACE_AA_DISABLED if uses_temporal(scale) else screen_space_aa as Viewport.ScreenSpaceAA
