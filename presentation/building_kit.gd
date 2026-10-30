class_name BuildingKit
extends RefCounted
## Prédios de modelo (depois da Fase 12): as fachadas saem das peças modulares do Kenney Fantasy Town
## Kit (CC0, assets/models/buildings/), uma peça por célula da borda e por andar — parede com janela,
## porta na célula da entrada —, e o telhado é gerado aqui (duas águas, quatro águas ou plano), porque
## as peças de telhado do kit só fecham larguras de uma ou duas células. Tudo vira uma malha só por
## forma (Spec), guardada em cache: as casas iguais dividem a mesma malha.
##
## A malha fica no referencial "canônico" do prédio: rotação 0 (frente em −Z), largura def.size.x em
## x, fundo def.size.y em z, centro da área na origem e o chão em y = 0. A BuildingView gira o nó.
## O material (BuildingMaterials.kit) reconhece pela UV o que é parede e o que é telhado e põe nelas a
## textura PBR e o tom do prédio; o resto (madeiramento, janelas, porta) fica com as cores do kit.

const DIR := "res://assets/models/buildings/"
## Folga entre a parede e a borda da área, a mesma das caixas de antes.
const INSET_M := 0.3
## Altura de andar procurada: o número de andares é a altura do prédio dividida por ela.
const FLOOR_TARGET_M := 2.6
## Alicerce: desce abaixo do chão (a área pode ter desnível) e aparece um pouco acima dele.
const FOUNDATION_DOWN_M := 0.6
const FOUNDATION_UP_M := 0.15
## Beiral do telhado e espessura das águas.
const ROOF_OVERHANG_M := 0.35
const ROOF_THICKNESS_M := 0.18
## Fase 95: a capa redonda da cumeeira e dos espigões (raio, faces da meia volta) e o beiral redondo (raio, faces).
const RIDGE_CAP_M := 0.14
const RIDGE_SIDES := 6
const EAVE_ROLL_M := 0.11
const EAVE_SIDES := 6
## Fase 96: o telhado da ala em fração do do corpo, e a classe a partir da qual a casa pode ter ala (os camponeses ficam
## na casinha de um volume, com o quintal).
const WING_ROOF := 0.7
const WING_ROOF_FLOOR := 0.8
const WING_SHARE := 2
## Fase 97: a cúpula de cobre (os serviços de DOMED, no telhado de quatro águas): raio em fração do lado menor (até
## DOME_MAX_M), o tambor de pedra (DRUM_M acima da cumeeira), a subida da cúpula em fração do raio e o lanternim; e o
## torreão dos investidores no canto da frente de +X, em balanço do primeiro andar: raio, quanto passa do beiral, o
## telhado cônico e o cone de pedra que o segura por baixo.
const DOMED: Array[StringName] = [&"theater", &"university", &"town_hall", &"museum"]
const DOME_SHARE := 0.2
const DOME_MAX_M := 3.2
const DRUM_M := 1.3
const DOME_RISE := 1.1
const DOME_SIDES := 16
const TURRET_R := 0.85
const TURRET_ABOVE := 0.75
const TURRET_ROOF_M := 2.4
const TURRET_CORBEL_M := 1.0
const TURRET_SIDES := 12
## A cor do cobre velho (célula (2, 1) da paleta, que o kit não usa).
const UV_COPPER := Vector2(2.5 / 8.0, 1.5 / 4.0)
## Fase 98: a abóbada (os de VAULTED, no lugar das duas águas): arco abatido sobre o lado curto em VAULT_SEGMENTS faixas
## lisas, VAULT_RISE da altura do telhado de duas águas; e os tonéis do pátio (Silhouette.VATS): VATS_PER_SIDE de cada lado
## do caminho da porta, de VAT_MAX_M de altura no máximo, com o bojo de VAT_BULGE e os arcos de ferro.
const VAULTED: Array[StringName] = [&"market", &"weavery", &"sewing_machine_factory", &"cannery", &"soap_factory",
		&"window_works", &"coffee_roaster"]
const VAULT_SEGMENTS := 10
const VAULT_RISE := 0.8
const VATS_PER_SIDE := 2
const VAT_MAX_M := 2.4
const VAT_BULGE := 1.08
const VAT_SIDES := 16
## Fase 99: a cabeça em arco das janelas (ARCH_SEGMENTS trechos, a arquivolta de ARCH_BAND_M saltando ARCH_PROUD_M da
## parede e o tímpano de vidro) e a arcada do mercado (na fileira do pátio junto do corpo: pilares de ARCADE_PIER_M, o
## arco nascendo a ARCADE_SPRING_M, a espessura e a água que sobe ARCADE_ROOF_RISE_M até a parede).
const ARCH_SEGMENTS := 8
const ARCH_BAND_M := 0.11
const ARCH_PROUD_M := 0.06
const ARCADE_PIER_M := 0.34
const ARCADE_SPRING_M := 1.9
const ARCADE_THICK_M := 0.32
const ARCADE_ROOF_RISE_M := 0.6
## Fase 101: o toldo listrado sobre a porta e as janelas do térreo da frente — as lojas de AWNING_SHOPS e uma casa em
## AWNING_HOUSE_SHARE dos artesãos e engenheiros; preso a AWNING_AT do andar, saindo AWNING_OUT_M e caindo AWNING_DROP_M,
## em AWNING_STRIPES listras alternando a cor e o creme, com a sanefa de AWNING_VALANCE_M na ponta.
const AWNING_SHOPS: Array[StringName] = [&"bakery", &"butcher", &"tavern"]
const AWNING_HOUSE_SHARE := 3
const AWNING_AT := 0.86
const AWNING_OUT_M := 0.75
const AWNING_DROP_M := 0.42
const AWNING_STRIPES := 7
const AWNING_VALANCE_M := 0.16
const UV_AWNING_COLORS: Array[Vector2] = [Vector2(3.5 / 8.0, 1.5 / 4.0), Vector2(4.5 / 8.0, 1.5 / 4.0),
		Vector2(5.5 / 8.0, 1.5 / 4.0)]
const UV_CANVAS := Vector2(6.5 / 8.0, 1.5 / 4.0)
## Fase 102: o andar saliente das casas dos operários e artesãos (telhado com a cumeeira ao longo da frente, dois andares
## ou mais): os andares de cima da frente avançam JETTY_M (menos que o menor beiral), sobre a viga do balanço e as
## mãos-francesas de JETTY_BRACKET_M, com o enxaimel (frechal, baldrame, esteios e escoras de TIMBER_M) na frente.
const JETTY_M := 0.28
const JETTY_BRACKET_M := 0.6
const TIMBER_M := 0.1
## Telhado da casa em fração da altura (como a caixa de antes: fica acima das paredes).
const HOUSE_ROOF_FRACTION := 0.35
## Telhado dos outros em fração do lado curto.
const ROOF_SLOPE := 0.28
const SPIRE_SLOPE := 0.55
const FLAT_ROOF_M := 0.3
## Vidro aceso (WindowLightsView): onde fica a abertura da janela na peça, em fração da célula
## (largura) e do andar (centro e altura).
const WINDOW_WIDTH := 0.36
const WINDOW_CENTER := 0.52
const WINDOW_HEIGHT := 0.4
const WINDOW_GAP_M := 0.06

## UV de cada tipo de superfície na paleta do kit (colormap.png, 8 colunas × 4 linhas de cor). O
## shader usa a mesma divisão: parede = (1, 2) e (5, 3); telhado = (0, 3) e (1, 3).
const UV_WALL := Vector2(1.25 / 8.0, 2.5 / 4.0)
const UV_ROOF := Vector2(0.25 / 8.0, 3.5 / 4.0)
## Fase 95: a capa da cumeeira e o beiral (célula (1, 3), que o shader trata como telhado: textura e tom, sem as telhas).
const UV_ROOF_TRIM := Vector2(1.5 / 8.0, 3.5 / 4.0)
const UV_STONE := Vector2(7.5 / 8.0, 3.5 / 4.0)
## Fase 18: madeiramento (o shader escurece), ferro (cinza-chumbo da paleta) e bronze (o marrom-cobre).
const UV_TIMBER := Vector2(4.5 / 8.0, 3.5 / 4.0)
const UV_IRON := Vector2(6.5 / 8.0, 3.5 / 4.0)
const UV_BRONZE := Vector2(4.5 / 8.0, 2.5 / 4.0)
## Pedra clara da cornija, das vergas e do frontão (o branco da paleta, que o shader acinzenta).
const UV_LIGHT_STONE := Vector2(2.5 / 8.0, 2.5 / 4.0)

enum Walls { PLASTER, WOOD }
enum Roof { GABLE_X, GABLE_Z, HIP, FLAT }
## GATE (Fase 18): o vão em arco com portão largo de duas folhas abertas, nas fábricas pesadas.
enum Door { NONE, DOOR, ARCH, GATE }

## Peças: parede lisa, janelas e portas de cada estilo.
const PIECES := {
	Walls.PLASTER: {
		&"plain": "wall", &"windows": ["wall-window-shutters", "wall-window-glass", "wall-window-small"],
		&"door": "wall-door", &"arch": "wall-doorway-round",
	},
	Walls.WOOD: {
		&"plain": "wall-wood", &"windows": ["wall-wood-window-shutters", "wall-wood-window-glass", "wall-wood-window-small"],
		&"door": "wall-wood-door", &"arch": "wall-wood-doorway-round",
	},
}
const CHIMNEY := "chimney"
## Silhueta por cadeia (Fase 13, BuildingDef.silhouette): as peças do mesmo kit.
const WINDMILL := "windmill"
const WATERWHEEL := "watermill"
const SHEAVE := "wheel"
const BEAM := "pillar-wood"
const STALLS: Array[String] = ["stall-red", "stall-green"]
const BANNER := "banner-red"
## Detalhe das casas (Fase 13, TierDef.house_trim): cerca e portão do quintal, sebe (também a floreira),
## coluna de pedra do pórtico e o piso da sacada (a frente de madeira do kit deu lugar à grade de ferro
## na Fase 18).
const FENCE := "fence"
const GATE := "fence-gate"
const HEDGE := "hedge"
const PILLAR := "pillar-stone"
const PLANKS := "planks-half"
## Altura da cerca, quanto a sacada e a floreira saem da parede e a altura da coluna do pórtico em
## fração do andar.
const FENCE_M := 1.0
const BALCONY_OUT_M := 0.8
const FLOWER_BOX_OUT_M := 0.16
const PORTICO_HEIGHT := 0.95
## Ornamento das casas (Fase 18), dos artesãos para cima: cornija no alto das paredes, verga de pedra
## sobre cada janela e, nos engenheiros e investidores, a faixa entre os andares; o frontão no alto da
## fachada, sobre a porta dos investidores; e grade de ferro (corrimão, travessa de baixo e balaústres a cada
## RAIL_STEP_M) no lugar do parapeito de madeira das sacadas.
const CORNICE_OUT_M := 0.16
const CORNICE_M := 0.26
const BAND_M := 0.1
const LINTEL_M := 0.12
const PEDIMENT_M := 0.7
const RAIL_M := 0.95
const RAIL_STEP_M := 0.19
## Pedra e torno (Fase 24): a sacada dos investidores troca a grade de ferro pela balaustrada de pedra — soco,
## balaústres torneados a cada BALUSTER_STEP_M (o perfil em BALUSTER_PROFILE, raio e altura em fração da
## altura do balaústre, de BALUSTER_SIDES faces) e o corrimão largo por cima; sob as sacadas, consolos de
## pedra em cada divisa de célula; e o peitoril de pedra debaixo de cada janela, junto com a verga.
const BALUSTER_STEP_M := 0.26
const BALUSTER_SIDES := 6
const BALUSTER_PROFILE: Array[Vector2] = [
	Vector2(0.06, 0.0), Vector2(0.06, 0.08), Vector2(0.035, 0.16), Vector2(0.07, 0.42), Vector2(0.045, 0.68),
	Vector2(0.03, 0.8), Vector2(0.055, 0.88), Vector2(0.055, 1.0),
]
const PLINTH_M := 0.14
const HANDRAIL_M := 0.12
const CORBEL_M := 0.5
const CORBEL_WIDTH_M := 0.16
const SILL_M := 0.08
## Cantaria e moldura (Fase 25): nos engenheiros e investidores, a janela ganha a guarnição de pedra — as duas
## ombreiras de JAMB_M entre o peitoril e a verga — e a pedra de fecho no meio da verga, KEYSTONE_M de alto
## (passa da verga para cima) e saindo mais da parede.
const JAMB_M := 0.07
const KEYSTONE_M := 0.2
const KEYSTONE_WIDTH_M := 0.12
## Medidas das peças do kit (caixa da peça importada): diâmetro das rodas, meio da polia, lado da viga.
const WINDMILL_DIAMETER := 3.113
const WATERWHEEL_DIAMETER := 1.8
const SHEAVE_DIAMETER := 0.483
const SHEAVE_CENTER := Vector3(0.318, 0.2416, 0.0)
const BEAM_SIDE := 0.16
## Torre de mina e guindaste: altura acima do telhado e espessura das vigas.
const HEADFRAME_M := 5.5
const CRANE_M := 3.0
const BEAM_M := 0.35
## Guindaste de porto (Fase 23): a lança sai do mastro a CRANE_BOOM_FOOT da altura e sobe até CRANE_RISE_M
## acima do topo dele, presa por tirantes de ferro; sarilho de manivela no pé, cabo, moitão e gancho com um
## caixote pendurado a CRANE_LOAD_M do chão.
const CRANE_BOOM_FOOT := 0.3
const CRANE_RISE_M := 0.6
const CRANE_LOAD_M := 1.9
const CRANE_CRATE_M := 0.75
const CRANE_DRUM_RADIUS_M := 0.22
const CRANE_ROPE_M := 0.04
## Quanto a ponta da lança sai da parede do lado (o caixote pende longe dela).
const CRANE_REACH_M := 0.5
## Guincho do armazém com plataforma (Fase 23): a viga sai da fachada logo abaixo do beiral, sobre a porta de
## carga do sótão, até HOIST_OUT_M além da frente da área (passa do alpendre), e o caixote pende a HOIST_LOAD_M.
const HOIST_OUT_M := 0.35
const HOIST_LOAD_M := 1.5
## Giro das partes que andam (rad/s de jogo a 1x) enquanto o prédio produz.
const WINDMILL_SPEED := 0.7
const WATERWHEEL_SPEED := 0.5
const SHEAVE_SPEED := 1.6
## Cavalo-de-pau do poço de petróleo (Fase 73): o pátio da frente (PUMPJACK_ROWS fileiras) com o cavalete, a caixa de
## engrenagens com os contrapesos e a cabeça do poço; o galpão baixo atrás. O balancim balança (não gira) em torno do
## eixo no alto do cavalete: até PUMPJACK_ROCK rad para cada lado, PUMPJACK_SPEED rad de fase por segundo de jogo.
const PUMPJACK_ROWS := 2
const PUMPJACK_SHED_M := 3.0
const PUMPJACK_PIVOT_M := 2.4
const PUMPJACK_ROCK := 0.28
const PUMPJACK_SPEED := 1.3
## Zoológico e museu (Fase 74): o galpão do zoológico fica nas MENAGERIE_HALL_ROWS fileiras de trás e o pátio da frente
## tem os cercados (3 por fileira de cercados, cerca de MENAGERIE_FENCE_M); o museu tem uma fileira de pátio com os
## pedestais (GALLERY_PEDESTAL_M de altura) dos dois lados do caminho da porta. Uma vaga de peça por cercado ou pedestal.
## Tanques da usina a petróleo (Fase 78): o pátio da frente (TANKFARM_ROWS fileiras) com dois tanques verticais de
## TANK_SIDES faces (no máximo TANK_MAX_M de altura), dentro de um dique baixo de TANKFARM_BUND_M, com escada e tubo até o
## galpão; o galpão nas fileiras de trás.
const TANKFARM_ROWS := 2
const TANKFARM_BUND_M := 0.45
const TANK_SIDES := 12
const TANK_MAX_M := 5.5
const MENAGERIE_HALL_ROWS := 2
const MENAGERIE_FENCE_M := 0.9
const GALLERY_PEDESTAL_M := 0.9
## Campanário da igreja (Fase 18): torre quadrada no canto da frente, saindo um pouco das paredes, que
## passa do beiral, sineira aberta com o sino e a agulha com a cruz.
const BELFRY_SIDE_M := 2.4
const BELFRY_OUT_M := 0.2
const BELFRY_SHAFT_M := 3.0
const BELFRY_OPEN_M := 2.3
const BELFRY_SPIRE_M := 5.5
const BELL_HEIGHT_M := 0.95
const BELL_RADIUS_M := 0.6
## Portão da fábrica (Fase 18): largura em células, altura em fração do andar e quanto as folhas abrem
## (entreaberto: aberto de todo, a folha passava da área e entrava na rua).
const GATE_CELLS := 1.5
const GATE_HEIGHT := 0.82
const GATE_OPEN := deg_to_rad(40.0)
## Varanda da casa de engenho (Fase 23): a fileira da frente das plantações vira alpendre de tábuas, um
## pouco acima do chão, com esteios de madeira, guarda-corpo de balaústres e o telhado de uma água preso na
## parede entre os dois andares; dois degraus diante da porta.
const VERANDA_DECK_M := 0.35
const VERANDA_STEP_M := 0.35
const VERANDA_POST_M := 0.18
const VERANDA_RAIL_M := 0.8
const VERANDA_RAIL_STEP_M := 0.24
## Altura do beiral e da água na parede, em fração do andar (a água fica abaixo das janelas de cima).
const VERANDA_EAVE := 0.95
const VERANDA_WALL := 1.15
const VERANDA_OVERHANG_M := 0.25
## Plataforma de carga do armazém (Fase 23): a fileira da frente vira plataforma na altura da caçamba da
## carroça, de tijolo com tampo de tábuas e defensa de madeira, com uma rampa de pedra em cada ponta. Com o
## nível 1 ganha alpendre em mãos-francesas de ferro e portas de carga em células alternadas; no 2 (o que
## custa tijolo) as paredes passam a tijolo e o telhado a telha.
const DOCK_M := 0.8
const DOCK_RAMP_M := 1.7
const DOCK_CANOPY_LEVEL := 1
const DOCK_BRICK_LEVEL := 2
## Altura do alpendre na parede e no beiral, em fração do andar, e quanto ele sai além da plataforma.
const DOCK_CANOPY_WALL := 1.25
const DOCK_CANOPY_EAVE := 1.02
const DOCK_CANOPY_OUT_M := 0.15
## Prédios assentados (Fase 39). Beiral e cumeeira variam em três degraus, pelo resto do id por 3 (casas construídas em
## fila têm ids seguidos, e as vizinhas nunca ficam da mesma altura). O tipo de prédio que não é casa tira o beiral pelo
## tipo, igual em todos os dele.
const OVERHANGS_M: Array[float] = [0.3, 0.4, 0.5]
const RIDGE_SCALES: Array[float] = [0.85, 1.0, 1.18]
## A casa com quintal (camponeses) recua das divisas dos lados: as vizinhas deixam de se colar.
const YARD_SIDE_GAP_M := 0.6
## Lucarna no telhado de duas águas das casas, de LUCARNE_W de largura e LUCARNE_H de parede, com a frente a LUCARNE_AT
## da meia largura da água e o telhadinho LUCARNE_PEAK_M acima dela: só onde ele fica abaixo da cumeeira
## (lucarne_fits; nos camponeses a água é baixa demais).
const LUCARNE_W := 0.9
const LUCARNE_H := 0.75
const LUCARNE_AT := 0.62
const LUCARNE_PEAK_M := 0.32
## Vidro e caixilho nas janelas: o kit só tem o vão. O vidro fica na espessura da parede (x da peça), o caixilho em
## cruz logo à frente dele, MULLION_M de largura.
const UV_GLASS := Vector2(0.5 / 8.0, 1.5 / 4.0)
const GLASS_X := 0.44
const MULLION_X := 0.452
const MULLION_M := 0.05
## Plinto e degraus no barranco: o piso fica no canto mais alto do lote (seat_lift), a pedra desce até PLINTH_BELOW_M
## abaixo do canto mais baixo e a porta alta ganha degraus de STEP_RISE_M até o chão da frente, STEP_TREAD_M cada.
const PLINTH_BELOW_M := 0.3
const PLINTH_OUT_M := 0.07
const STEP_RISE_M := 0.18
const STEP_TREAD_M := 0.28
const MAX_STEPS := 4
## Armazém do entreposto: empena na frente, mais íngreme.
const STOREHOUSE_SLOPE := 0.42


## A forma de um prédio: tudo que muda a malha (e nada que só muda a cor).
class Spec:
	var cells := Vector2i(3, 3)
	var cell_m: float = 2.0
	var height_m: float = 4.0
	var walls: int = Walls.PLASTER
	var roof: int = Roof.GABLE_X
	var roof_m: float = 1.0
	var door: int = Door.DOOR
	var door_index: int = 1
	## Qual das três janelas do estilo, e se as fachadas alternam janela e parede lisa.
	var window_style: int = 0
	var sparse_windows: bool = false
	var chimney: bool = false
	var silhouette: int = BuildingDef.Silhouette.NONE
	## Fileiras da frente sem paredes (o pátio das bancas do mercado, o quintal da casa): o corpo fica
	## nas de trás.
	var court_rows: int = 0
	var trim: int = TierDef.HouseTrim.NONE
	## Plataforma de carga do armazém (Fase 23) e o nível do armazém, que muda o alpendre e as portas dela.
	var dock: bool = false
	var level: int = 0
	## Fase 39: beiral, recuo dos lados do corpo (o quintal dos camponeses; só no hall()), lucarnas e o armazém do
	## entreposto (portas de carga alternadas no térreo e as do sótão sobre a porta).
	var overhang_m: float = ROOF_OVERHANG_M
	var side_gap_m: float = 0.0
	var hall_side_gap_m: float = 0.0
	var lucarnes: int = 0
	var storehouse: bool = false
	## Fase 50: a peça do kit de época para este prédio (caminho), se houver; vazio, a forma procedural.
	var asset: String = ""
	## Fase 96: a ala mais baixa (0 sem; -1 no lado de −X): a coluna de células da ponta perde o último andar e ganha
	## telhado próprio, cruzado com o do corpo.
	var wing: int = 0
	## Fase 97: cúpula de cobre no alto do telhado (os serviços grandes) e torreão redondo no canto da frente (investidores).
	var dome: bool = false
	var turret: bool = false
	## Fase 98: o telhado de duas águas vira abóbada (arco abatido sobre o lado curto).
	var vault: bool = false
	## Fase 99: as janelas com a cabeça em arco (os serviços de pedra e os investidores).
	var arched: bool = false
	## Fase 101: o toldo listrado do térreo da frente (0 sem; 1 a 3, a cor da listra).
	var awning: int = 0
	## Fase 102: os andares de cima da frente avançam JETTY_M sobre a rua, com o enxaimel à mostra.
	var jetty: bool = false

	func key() -> String:
		return "%d,%d|%.2f|%.2f|%d|%d|%.2f|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%.2f|%.2f|%.2f|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [cells.x, cells.y, cell_m,
				height_m, walls, roof, roof_m, door, door_index, window_style, int(sparse_windows), int(chimney), silhouette,
				court_rows, trim, int(dock), level, overhang_m, side_gap_m, hall_side_gap_m, lucarnes, int(storehouse), wing, int(dome), int(turret), int(vault), int(arched), awning, int(jetty)]

	## O corpo do prédio (sem o pátio), no referencial dele; hall_offset() o leva ao do prédio.
	func hall() -> Spec:
		if court_rows == 0:
			return self
		var copy := Spec.new()
		copy.cells = Vector2i(cells.x, cells.y - court_rows)
		copy.cell_m = cell_m
		copy.height_m = height_m
		copy.walls = walls
		copy.roof = roof
		copy.roof_m = roof_m
		copy.door = door
		copy.door_index = door_index
		copy.window_style = window_style
		copy.sparse_windows = sparse_windows
		copy.chimney = chimney
		copy.silhouette = silhouette
		copy.trim = trim
		copy.dock = dock
		copy.level = level
		copy.overhang_m = overhang_m
		copy.side_gap_m = hall_side_gap_m
		copy.lucarnes = lucarnes
		copy.storehouse = storehouse
		copy.wing = wing
		copy.dome = dome
		copy.turret = turret
		copy.vault = vault
		copy.arched = arched
		copy.awning = awning
		copy.jetty = jetty
		return copy

	func hall_offset() -> Vector3:
		return Vector3(0.0, 0.0, court_rows * cell_m * 0.5)

	func size_m() -> Vector2:
		return Vector2(cells.x * cell_m - INSET_M - side_gap_m * 2.0, cells.y * cell_m - INSET_M)

	func floors() -> int:
		return maxi(1, roundi(height_m / FLOOR_TARGET_M))

	func floor_m() -> float:
		return height_m / floors()

	## Fase 96: a largura de uma coluna de células, a parte do corpo (sem a coluna da ala) e a da ala, cada uma no
	## referencial dela (main_offset e wing_offset as levam ao do prédio).
	func column_m() -> float:
		return size_m().x / cells.x

	func main_part() -> Spec:
		var copy := hall()
		if copy == self:
			copy = _copy()
		copy.cells = Vector2i(cells.x - 1, cells.y)
		copy.wing = 0
		return copy

	func main_offset() -> Vector3:
		# a ponta de fora do corpo fica na parede (com a largura de uma coluna o telhado ficava curto do beiral)
		return Vector3(-wing * (size_m().x - main_part().size_m().x) * 0.5, 0.0, 0.0)

	func wing_part() -> Spec:
		var copy := _copy()
		copy.cells = Vector2i(1, cells.y)
		copy.wing = 0
		copy.height_m = height_m - floor_m()
		copy.lucarnes = 0
		copy.chimney = false
		copy.overhang_m = minf(overhang_m, 0.3)
		# o telhado da ala cruza o do corpo: com a cumeeira do corpo ao longo de x, a da ala corre em z
		copy.roof = Roof.GABLE_Z if roof == Roof.GABLE_X else Roof.HIP
		# cabe no andar que a ala tirou: a cumeeira dela fica abaixo do beiral do corpo (mais alto virava uma agulha)
		copy.roof_m = minf(roof_m * WING_ROOF, floor_m() * WING_ROOF_FLOOR)
		return copy

	func wing_offset() -> Vector3:
		return Vector3(wing * (size_m().x * 0.5 - column_m() * 0.5), 0.0, 0.0)

	func _copy() -> Spec:
		var copy := Spec.new()
		copy.cells = cells
		copy.cell_m = cell_m
		copy.height_m = height_m
		copy.walls = walls
		copy.roof = roof
		copy.roof_m = roof_m
		copy.door = door
		copy.door_index = door_index
		copy.window_style = window_style
		copy.sparse_windows = sparse_windows
		copy.chimney = chimney
		copy.silhouette = silhouette
		copy.court_rows = court_rows
		copy.trim = trim
		copy.dock = dock
		copy.level = level
		copy.overhang_m = overhang_m
		copy.side_gap_m = side_gap_m
		copy.hall_side_gap_m = hall_side_gap_m
		copy.lucarnes = lucarnes
		copy.storehouse = storehouse
		copy.wing = wing
		copy.dome = dome
		copy.turret = turret
		copy.vault = vault
		copy.arched = arched
		copy.awning = awning
		copy.jetty = jetty
		return copy


static var _parts: Dictionary[String, Array] = {}
static var _meshes: Dictionary[String, ArrayMesh] = {}
static var _available: int = -1


static func available() -> bool:
	if _available < 0:
		_available = 1 if ResourceLoader.exists(DIR + "wall.glb") else 0
	return _available == 1


## A forma do prédio do registro (null: fica a caixa — campo, pasto, píer ou kit ausente).
static func spec_for(simulation: Simulation, record: BuildingRecord, cell_size: float) -> Spec:
	var def := simulation.def_of(record)
	if not available() or def.kind in [BuildingDef.Kind.MODULE, BuildingDef.Kind.PIER, BuildingDef.Kind.DECORATION]:
		return null
	var spec := Spec.new()
	spec.cells = def.size
	spec.cell_m = cell_size
	spec.asset = asset_path(def.id, record.tier)
	spec.door_index = def.size.x / 2 if posmod(record.rotation, 4) < 2 else def.size.x - 1 - def.size.x / 2
	if record.is_house():
		var tier := simulation.data.tier(record.tier)
		var variant := BuildingView.house_variant(record.id)
		spec.height_m = tier.house_height_m
		spec.walls = Walls.WOOD if tier.wall_material == BuildingMaterials.Wall.WOOD else Walls.PLASTER
		# cada malha nova custa ~18 ms: o beiral e o que vai no telhado seguem o degrau da cumeeira (3 × 3 telhados × 2
		# janelas por classe, em vez de centenas)
		var step := posmod(record.id, RIDGE_SCALES.size())
		spec.roof = [Roof.GABLE_X, Roof.GABLE_Z, Roof.FLAT][variant]
		spec.roof_m = tier.house_height_m * HOUSE_ROOF_FRACTION * RIDGE_SCALES[step]
		spec.overhang_m = OVERHANGS_M[step]
		# o telhado de duas águas tira chaminé (degrau do meio), lucarnas (o mais alto) ou nada; o plano tem a chaminé
		spec.chimney = variant == 2 or step == 1
		if variant != 2 and step == 2 and lucarne_fits(spec.roof_m):
			spec.lucarnes = 1 if spec.cells.x <= 3 else 2
		spec.window_style = BuildingView.house_hash(record.id) / 3 % 2
		spec.trim = tier.house_trim
		if spec.trim == TierDef.HouseTrim.YARD and spec.cells.y > 2:
			# a fileira da frente vira quintal cercado; a casa fica nas de trás, recuada das divisas dos lados
			spec.court_rows = 1
			spec.hall_side_gap_m = YARD_SIDE_GAP_M
		elif spec.cells.x >= 3 and spec.roof != Roof.FLAT and spec.floors() >= 2 \
				and BuildingView.house_hash(record.id) / 7 % WING_SHARE == 0:
			# Fase 96: metade das casas de dois andares para cima ganha a ala mais baixa num lado (a chaminé fica no outro)
			spec.wing = -1
		# Fase 97: o torreão de canto das casas dos investidores (três andares ou mais)
		spec.turret = spec.trim == TierDef.HouseTrim.PORTICO and spec.floors() >= 3
		# Fase 102: o andar saliente com enxaimel dos operários e artesãos
		spec.jetty = spec.trim in [TierDef.HouseTrim.NONE, TierDef.HouseTrim.FLOWER_BOXES] and spec.roof == Roof.GABLE_X \
				and spec.floors() >= 2
		# Fase 99: as janelas em arco das casas dos investidores
		spec.arched = spec.trim == TierDef.HouseTrim.PORTICO
		# Fase 101: uma casa em AWNING_HOUSE_SHARE dos artesãos e engenheiros tem loja no térreo, com o toldo
		if spec.trim in [TierDef.HouseTrim.FLOWER_BOXES, TierDef.HouseTrim.BALCONIES] \
				and BuildingView.house_hash(record.id) / 11 % AWNING_HOUSE_SHARE == 0:
			# uma cor por classe (cada forma nova custa ~18 ms; três cores triplicavam as casas com loja)
			spec.awning = 1 if spec.trim == TierDef.HouseTrim.FLOWER_BOXES else 2
		return spec
	spec.height_m = def.height_m
	spec.walls = Walls.WOOD if def.wall_material == BuildingMaterials.Wall.WOOD else Walls.PLASTER
	var short := minf(def.size.x, def.size.y) * cell_size
	spec.roof_m = short * ROOF_SLOPE
	spec.roof = Roof.GABLE_X if def.size.x >= def.size.y else Roof.GABLE_Z
	spec.overhang_m = OVERHANGS_M[absi(hash(String(def.id))) % OVERHANGS_M.size()]
	spec.window_style = 1
	if def.kind in [BuildingDef.Kind.WAREHOUSE] or def.is_shipyard():
		spec.door = Door.ARCH
		spec.sparse_windows = true
		if def.is_trading_post:
			# o entreposto lê como armazém (Fase 39): empena alta na frente, portas de carga no térreo, janela pequena
			spec.storehouse = true
			spec.roof = Roof.GABLE_Z
			spec.roof_m = minf(def.size.x, def.size.y) * cell_size * STOREHOUSE_SLOPE
			spec.window_style = 2
		# o armazém do interior (não o entreposto, que tem o cais) ganha a plataforma de carga na frente
		spec.dock = def.kind == BuildingDef.Kind.WAREHOUSE and not def.is_trading_post and def.size.y > 2
		if spec.dock:
			spec.level = record.level
			spec.court_rows = 1
	elif def.kind == BuildingDef.Kind.SERVICE and def.wall_material == BuildingMaterials.Wall.STONE:
		# igreja, teatro, universidade: quatro águas, a igreja bem alta
		spec.roof = Roof.HIP
		spec.roof_m = short * (SPIRE_SLOPE if def.id == &"church" else ROOF_SLOPE * 1.4)
		spec.door = Door.ARCH
		spec.window_style = 2
		spec.arched = true
	elif def.kind == BuildingDef.Kind.PRODUCTION and def.smoke != BuildingDef.Smoke.NONE:
		spec.sparse_windows = true
		if def.smoke == BuildingDef.Smoke.HEAVY or def.silhouette == BuildingDef.Silhouette.CLERESTORY:
			spec.door = Door.GATE
	if def.height_m < 3.0 or def.deposit != &"" or def.id in [&"clay_pit", &"sand_pit"]:
		spec.roof = Roof.FLAT
		spec.roof_m = FLAT_ROOF_M
	if def.wall_material == BuildingMaterials.Wall.WOOD and not brick(spec) and not spec.storehouse:
		spec.window_style = 0
	if brick(spec):
		spec.walls = Walls.PLASTER
	spec.silhouette = def.silhouette
	# Fase 97: a cúpula de cobre dos serviços grandes (no telhado de quatro águas)
	spec.dome = def.id in DOMED and spec.roof == Roof.HIP
	if def.silhouette == BuildingDef.Silhouette.STALLS:
		# metade da frente vira pátio; o telhado segue o lado curto do corpo
		spec.court_rows = def.size.y / 2
		var hall := spec.hall()
		spec.roof = Roof.GABLE_X if hall.cells.x >= hall.cells.y else Roof.GABLE_Z
		spec.roof_m = minf(hall.cells.x, hall.cells.y) * cell_size * ROOF_SLOPE
	elif def.silhouette == BuildingDef.Silhouette.VERANDA and def.size.y > 2:
		# a fileira da frente vira varanda; o telhado segue o lado curto do corpo
		spec.court_rows = 1
		var house := spec.hall()
		spec.roof = Roof.GABLE_X if house.cells.x >= house.cells.y else Roof.GABLE_Z
		spec.roof_m = minf(house.cells.x, house.cells.y) * cell_size * ROOF_SLOPE
	elif def.silhouette == BuildingDef.Silhouette.PUMPJACK and def.size.y > PUMPJACK_ROWS:
		# o pátio da frente fica com o cavalo-de-pau; o galpão baixo, nas fileiras de trás
		spec.court_rows = PUMPJACK_ROWS
		spec.height_m = minf(spec.height_m, PUMPJACK_SHED_M)
		var shed := spec.hall()
		spec.roof = Roof.GABLE_X if shed.cells.x >= shed.cells.y else Roof.GABLE_Z
		spec.roof_m = minf(shed.cells.x, shed.cells.y) * cell_size * ROOF_SLOPE
	elif def.silhouette == BuildingDef.Silhouette.TANKFARM and def.size.y > TANKFARM_ROWS:
		# o pátio da frente fica com os tanques; o galpão, nas fileiras de trás
		spec.court_rows = TANKFARM_ROWS
		var hall := spec.hall()
		spec.roof = Roof.GABLE_X if hall.cells.x >= hall.cells.y else Roof.GABLE_Z
		spec.roof_m = minf(hall.cells.x, hall.cells.y) * cell_size * ROOF_SLOPE
	elif (def.silhouette == BuildingDef.Silhouette.MENAGERIE and def.size.y > MENAGERIE_HALL_ROWS) \
			or (def.silhouette == BuildingDef.Silhouette.GALLERY and def.size.y > 1):
		# o pátio da frente fica com os cercados ou os pedestais; o corpo, nas fileiras de trás
		spec.court_rows = def.size.y - MENAGERIE_HALL_ROWS if def.silhouette == BuildingDef.Silhouette.MENAGERIE else 1
		var body := spec.hall()
		spec.roof = Roof.GABLE_X if body.cells.x >= body.cells.y else Roof.GABLE_Z
		spec.roof_m = minf(body.cells.x, body.cells.y) * cell_size * ROOF_SLOPE
	elif def.silhouette == BuildingDef.Silhouette.WINDMILL:
		# a empena fica na frente e as pás giram nela
		spec.roof = Roof.GABLE_Z
	elif spec.dock:
		var body := spec.hall()
		spec.roof = Roof.GABLE_X if body.cells.x >= body.cells.y else Roof.GABLE_Z
		spec.roof_m = minf(body.cells.x, body.cells.y) * cell_size * ROOF_SLOPE
	elif def.silhouette == BuildingDef.Silhouette.VATS and def.size.y > 2:
		# Fase 98: a fileira da frente fica com os tonéis; o corpo, nas de trás
		spec.court_rows = 1
		var body := spec.hall()
		spec.roof = Roof.GABLE_X if body.cells.x >= body.cells.y else Roof.GABLE_Z
		spec.roof_m = minf(body.cells.x, body.cells.y) * cell_size * ROOF_SLOPE
	elif def.silhouette == BuildingDef.Silhouette.CLERESTORY and spec.roof == Roof.FLAT:
		spec.roof = Roof.GABLE_X if def.size.x >= def.size.y else Roof.GABLE_Z
	# Fase 101: o toldo das lojas, na cor sorteada pelo tipo
	if def.id in AWNING_SHOPS:
		spec.awning = 1 + absi(hash(String(def.id))) % UV_AWNING_COLORS.size()
	# Fase 98: a abóbada no lugar das duas águas (o mercado e as fábricas de nave comprida)
	spec.vault = def.id in VAULTED and spec.roof in [Roof.GABLE_X, Roof.GABLE_Z]
	return spec


## Fase 39: número estável da variação visual do prédio. O mesmo id, tipo e rotação dão sempre a mesma; ela nunca
## muda o lote, a porta nem o número de andares.
static func variation_hash(record: BuildingRecord) -> int:
	return absi(hash("%d|%s|%d" % [record.id, record.def_id, posmod(record.rotation, 4)]))


## Quanto o piso sobe da altura média do lote até o canto mais alto (Fase 39): a casa no barranco não afunda a parede de
## cima; embaixo aparece o plinto.
static func seat_lift(grid: IslandGrid, area: Rect2i) -> float:
	var corners := corner_range(grid, area)
	return maxf(corners.y - grid.area_height(area), 0.0)


## Menor e maior altura dos cantos do lote.
static func corner_range(grid: IslandGrid, area: Rect2i) -> Vector2:
	var low := INF
	var high := -INF
	for y: int in range(area.position.y, area.end.y + 1):
		for x: int in range(area.position.x, area.end.x + 1):
			var height := grid.corner_height(x, y)
			low = minf(low, height)
			high = maxf(high, height)
	return Vector2(low, high)


## O ponto do piso do prédio de modelo: o meio do lote, na altura do canto mais alto.
static func seat(grid: IslandGrid, area: Rect2i) -> Vector3:
	return grid.rect_world(area) + Vector3(0.0, seat_lift(grid, area), 0.0)


## O armazém de nível DOCK_BRICK_LEVEL é de tijolo (Fase 23): a BuildingView troca as camadas da parede e do
## telhado.
static func brick(spec: Spec) -> bool:
	return spec.dock and spec.level >= DOCK_BRICK_LEVEL


## Fase 50: a pasta do kit de época. Uma peça <prédio>_<classe> (casas) ou <prédio>, .glb ou .tscn, aprovada pelas
## AssetRules (uma malha, pivô no centro do lote e no chão, frente em −Z, UV na trim sheet do material do kit), entra no
## lugar da forma procedural, no mesmo lote e rotação; sem peça, nada muda.
static var kit_root := "res://assets/kit"
static var _asset_paths: Dictionary[String, String] = {}
static var _asset_meshes: Dictionary[String, ArrayMesh] = {}


## O caminho da peça do prédio (a da classe antes da geral), ou vazio.
static func asset_path(def_id: StringName, tier: StringName) -> String:
	var key := "%s|%s|%s" % [kit_root, def_id, tier]
	if not _asset_paths.has(key):
		var found := ""
		var stems: Array[String] = []
		if tier != &"":
			stems.append("%s_%s" % [def_id, tier])
		stems.append(String(def_id))
		for stem: String in stems:
			for extension: String in ["glb", "tscn"]:
				var path := kit_root.path_join("%s.%s" % [stem, extension])
				if found == "" and ResourceLoader.exists(path):
					found = path
		_asset_paths[key] = found
	return _asset_paths[key]


## A malha da peça (a primeira MeshInstance3D da cena), lida uma vez; null se a cena não tem malha.
static func asset_mesh(path: String) -> ArrayMesh:
	if not _asset_meshes.has(path):
		var mesh: ArrayMesh = null
		var scene := load(path) as PackedScene
		if scene != null:
			var root := scene.instantiate()
			var found := AssetRules.meshes(root)
			if not found.is_empty():
				mesh = found[0].mesh as ArrayMesh
			root.free()
		_asset_meshes[path] = mesh
	return _asset_meshes[path]


## Esquece o que achou na pasta do kit (testes, ou peça nova durante o jogo).
static func forget_assets() -> void:
	_asset_paths.clear()
	_asset_meshes.clear()


## A malha da forma, feita uma vez por chave (ou a peça do kit de época, se houver).
static func mesh(spec: Spec) -> ArrayMesh:
	if spec.asset != "":
		var piece := asset_mesh(spec.asset)
		if piece != null:
			return piece
	var key := spec.key()
	if not _meshes.has(key):
		_meshes[key] = _build(spec)
	return _meshes[key]


static func cached_meshes() -> int:
	return _meshes.size()


## O que vai em cada célula da borda de cada andar: &"door", &"arch", &"plain" ou &"window".
## faces: 0 = frente (−Z), 1 = +X, 2 = fundo (+Z), 3 = −X; índice crescendo em x ou z.
## Fase 96: a célula de parede que a ala tira (o último andar da coluna da ponta e o lado da ala nesse andar).
static func in_wing(spec: Spec, face: int, index: int, level: int) -> bool:
	if spec.wing == 0 or spec.floors() < 2 or level != spec.floors() - 1:
		return false
	var wing_face := 3 if spec.wing < 0 else 1
	if face == wing_face:
		return true
	return face % 2 == 0 and index == (0 if spec.wing < 0 else spec.cells.x - 1)


static func slot(spec: Spec, face: int, index: int, level: int) -> StringName:
	if in_wing(spec, face, index, level):
		return &"none"
	if face == 0 and level == 0 and index == spec.door_index and spec.door != Door.NONE:
		return &"arch" if spec.door in [Door.ARCH, Door.GATE] else &"door"
	if spec.silhouette == BuildingDef.Silhouette.BANNERS and face == 0 and level == 1 and index == spec.door_index:
		return &"plain"
	if spec.dock and face == 0 and level >= 1 and index == spec.door_index:
		return &"plain"
	if spec.dock and spec.level >= DOCK_CANOPY_LEVEL and face == 0 and level == 0 \
			and index % 2 == spec.door_index % 2:
		# portas de carga em células alternadas, todas dando na plataforma
		return &"arch"
	if spec.storehouse and face == 0:
		# armazém do entreposto: portas de carga alternadas no térreo; sobre a porta, as do sótão (no lugar da janela)
		if level == 0 and index % 2 == spec.door_index % 2:
			return &"arch"
		if level >= 1 and index == spec.door_index:
			return &"plain"
	if spec.sparse_windows and (index + level + face) % 2 == 1:
		return &"plain"
	return &"window"


## Vidros acesos à noite no referencial canônico: um por janela do modelo, logo à frente dela, com
## o +Z do vidro para fora.
static func windows(spec: Spec) -> Array[Transform3D]:
	if spec.court_rows > 0:
		var shifted: Array[Transform3D] = []
		for window: Transform3D in windows(spec.hall()):
			shifted.append(window.translated(spec.hall_offset()))
		return shifted
	var result: Array[Transform3D] = []
	var size := spec.size_m()
	var floor_m := spec.floor_m()
	for face: int in 4:
		var count := spec.cells.x if face % 2 == 0 else spec.cells.y
		var step := (size.x if face % 2 == 0 else size.y) / count
		for level: int in spec.floors():
			for index: int in count:
				if slot(spec, face, index, level) != &"window":
					continue
				var place := _cell_transform(spec, face, index, level)
				var normal := _face_normal(face)
				# o meio da peça fica meia célula para dentro (o x da base é a profundidade): o vidro vai à parede
				var origin := place.origin + normal * (place.basis.x.length() * 0.5 + WINDOW_GAP_M) \
						+ Vector3(0.0, floor_m * WINDOW_CENTER, 0.0)
				var basis := Basis.looking_at(-normal, Vector3.UP).scaled_local(Vector3(step * WINDOW_WIDTH, floor_m * WINDOW_HEIGHT, 1.0))
				result.append(Transform3D(basis, origin))
	return result


const FACE_NORMALS: Array[Vector3] = [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]
## Giro que leva o +X da peça à normal de cada fachada.
const FACE_YAWS: Array[float] = [PI * 0.5, 0.0, -PI * 0.5, PI]


## Meio da porta no chão, na fachada da frente (referencial canônico).
static func door_position(spec: Spec) -> Vector3:
	if spec.court_rows > 0:
		return door_position(spec.hall()) + spec.hall_offset()
	var place := _cell_transform(spec, 0, spec.door_index, 0)
	return place.origin + FACE_NORMALS[0] * (spec.size_m().y / spec.cells.y * 0.5)


## Triângulos da malha da forma (orçamento de polígonos).
static func triangles(spec: Spec) -> int:
	var arrays := mesh(spec).surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	return indices.size() / 3


static func _face_normal(face: int) -> Vector3:
	return FACE_NORMALS[face]


## Onde fica a peça: a origem é o ponto da fachada no meio da célula, no chão do andar; a base gira o
## +X da peça (a face de fora) para a normal da fachada e estica a célula até o tamanho dela.
static func _cell_transform(spec: Spec, face: int, index: int, level: int) -> Transform3D:
	var size := spec.size_m()
	var along := face % 2 == 0
	var count := spec.cells.x if along else spec.cells.y
	var step := (size.x if along else size.y) / count
	var depth := size.y / spec.cells.y if along else size.x / spec.cells.x
	var t := -(size.x if along else size.y) * 0.5 + step * (index + 0.5)
	var normal := _face_normal(face)
	var center := Vector3(t, level * spec.floor_m(), 0.0) if along else Vector3(0.0, level * spec.floor_m(), t)
	center += normal * ((size.y if along else size.x) * 0.5)
	# a peça ocupa x de -0,5 a 0,5 com a parede em 0,4..0,5: o meio da célula fica meia célula para dentro
	center -= normal * depth * 0.5
	# Fase 102: os andares de cima da frente avançam sobre a rua (tudo o que se põe pela célula acompanha)
	if spec.jetty and face == 0 and level >= 1:
		center += normal * JETTY_M
	var yaw := FACE_YAWS[face]
	var basis := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(depth, spec.floor_m(), step))
	return Transform3D(basis, center)


static func _parts_of(piece: String) -> Array:
	if _parts.has(piece):
		return _parts[piece]
	var parts: Array = []
	var path := DIR + piece + ".glb"
	if ResourceLoader.exists(path):
		var root := (load(path) as PackedScene).instantiate() as Node3D
		for node: Node in root.find_children("*", "MeshInstance3D", true, false):
			var part := node as MeshInstance3D
			parts.append([part.mesh, ShipView._transform_to(root, part)])
		root.free()
	_parts[piece] = parts
	return parts


static func _append_piece(tool: SurfaceTool, piece: String, transform: Transform3D) -> void:
	for part: Array in _parts_of(piece):
		var mesh: Mesh = part[0]
		var local: Transform3D = part[1]
		for surface: int in mesh.get_surface_count():
			tool.append_from(mesh, surface, transform * local)


static func _build(spec: Spec) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hall := spec.hall()
	var offset := Transform3D(Basis.IDENTITY, spec.hall_offset())
	var pieces: Dictionary = PIECES[spec.walls]
	var choices: Array = pieces[&"windows"]
	for face: int in 4:
		var count := hall.cells.x if face % 2 == 0 else hall.cells.y
		for level: int in hall.floors():
			for index: int in count:
				var kind := slot(hall, face, index, level)
				if kind == &"none":
					continue
				var piece: String = pieces[&"plain"]
				if kind == &"window":
					piece = choices[spec.window_style % choices.size()]
				elif kind != &"plain":
					piece = pieces[kind]
				_append_piece(tool, piece, offset * _cell_transform(hall, face, index, level))
	if hall.wing != 0 and hall.floors() >= 2:
		# Fase 96: no último andar, a parede do corpo do lado da ala (uma coluna para dentro), lisa
		var wing_face := 3 if hall.wing < 0 else 1
		var inward := -_face_normal(wing_face) * hall.column_m()
		var plain_piece: String = pieces[&"plain"]
		for index: int in hall.cells.y:
			_append_piece(tool, plain_piece,
					offset * _cell_transform(hall, wing_face, index, hall.floors() - 1).translated(inward))
	var size := spec.size_m()
	# alicerce e telhado à parte: as peças do kit chegam indexadas, e vértice solto depois delas
	# ficaria fora do índice
	var extra := SurfaceTool.new()
	extra.begin(Mesh.PRIMITIVE_TRIANGLES)
	# o quintal fica no chão: o alicerce é só o do corpo
	var base := hall.size_m() if spec.trim == TierDef.HouseTrim.YARD else size
	var base_center := spec.hall_offset() if spec.trim == TierDef.HouseTrim.YARD else Vector3.ZERO
	_box(extra, base_center + Vector3(0.0, (FOUNDATION_UP_M - FOUNDATION_DOWN_M) * 0.5, 0.0),
			Vector3(base.x + 0.1, FOUNDATION_UP_M + FOUNDATION_DOWN_M, base.y + 0.1), UV_STONE)
	if hall.wing != 0 and hall.floors() >= 2:
		# Fase 96: o telhado do corpo, uma coluna mais estreito, e o da ala, mais baixo e cruzado com ele
		for part: Array in [[hall.main_part(), hall.main_offset()], [hall.wing_part(), hall.wing_offset()]]:
			var piece_spec: Spec = part[0]
			var shift: Vector3 = part[1]
			var roof := SurfaceTool.new()
			roof.begin(Mesh.PRIMITIVE_TRIANGLES)
			_roof(roof, piece_spec)
			_lucarnes(roof, piece_spec)
			extra.append_from(roof.commit(), 0, offset.translated(shift))
	elif spec.court_rows > 0:
		# o telhado do corpo é feito no referencial dele e trazido para o do prédio
		var roof := SurfaceTool.new()
		roof.begin(Mesh.PRIMITIVE_TRIANGLES)
		_roof(roof, hall)
		_lucarnes(roof, hall)
		extra.append_from(roof.commit(), 0, offset)
	else:
		_roof(extra, spec)
		_lucarnes(extra, spec)
	# Fase 97: a cúpula de cobre e o torreão de canto
	if spec.dome:
		_dome(extra, spec)
	if hall.turret:
		_turret(extra, hall, offset)
	_glazing(extra, hall, offset)
	_silhouette(tool, extra, spec)
	_trim(tool, extra, spec)
	if spec.awning > 0:
		_awnings(extra, spec)
	if spec.jetty:
		_jetty(extra, spec)
	if spec.door == Door.GATE:
		_gate(tool, extra, hall, offset)
	extra.index()
	extra.generate_tangents()
	tool.append_from(extra.commit(), 0, Transform3D.IDENTITY)
	if spec.chimney:
		_append_piece(tool, CHIMNEY, _chimney_place(spec))
	var arrays := tool.commit_to_arrays()
	var importer := ImporterMesh.new()
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
	importer.generate_lods(25.0, 60.0, [])
	return importer.get_mesh()


## Fase 101: as células do térreo da frente que levam toldo (porta e janelas).
static func awning_cells(spec: Spec) -> Array[int]:
	var cells: Array[int] = []
	if spec.awning <= 0:
		return cells
	var hall := spec.hall()
	for index: int in hall.cells.x:
		if slot(hall, 0, index, 0) in [&"window", &"door", &"arch"]:
			cells.append(index)
	return cells


## O toldo de cada célula: a água de lona listrada da parede para fora e para baixo (de cima e de baixo), as duas abas
## dos lados e a sanefa na ponta, nas listras alternadas da cor do toldo e do creme.
static func _awnings(tool: SurfaceTool, spec: Spec) -> void:
	var hall := spec.hall()
	var size := hall.size_m()
	var step := size.x / hall.cells.x
	var normal := _face_normal(0)
	var color := UV_AWNING_COLORS[(spec.awning - 1) % UV_AWNING_COLORS.size()]
	var width := step * 0.86
	var high := hall.floor_m() * AWNING_AT
	for index: int in awning_cells(spec):
		var wall := spec.hall_offset() + _wall_point(hall, 0, index, 0)
		var base := Vector3(wall.x, high, wall.z) + normal * 0.02
		var tip := base + normal * AWNING_OUT_M + Vector3.DOWN * AWNING_DROP_M
		var up_side := (tip - base).cross(Vector3.RIGHT).normalized()
		if up_side.y < 0.0:
			up_side = -up_side
		for stripe: int in AWNING_STRIPES:
			var uv := color if stripe % 2 == 0 else UV_CANVAS
			var x0 := -width * 0.5 + width * stripe / AWNING_STRIPES
			var x1 := -width * 0.5 + width * (stripe + 1) / AWNING_STRIPES
			var a := base + Vector3.RIGHT * x0
			var b := base + Vector3.RIGHT * x1
			var c := tip + Vector3.RIGHT * x1
			var d := tip + Vector3.RIGHT * x0
			_quad(tool, a, b, c, d, up_side, uv)
			_quad(tool, a, b, c, d, -up_side, uv)
			# a sanefa: a aba que cai na ponta, de cada listra
			var drop := Vector3.DOWN * AWNING_VALANCE_M
			_quad(tool, d, c, c + drop, d + drop, normal, uv)
			_quad(tool, d, c, c + drop, d + drop, -normal, uv)
		# as abas dos lados, um triângulo de lona de cada lado
		for side: float in [-0.5, 0.5]:
			var at := Vector3.RIGHT * width * side
			var corner := base + at + Vector3.DOWN * AWNING_DROP_M
			_triangle(tool, base + at, tip + at, corner, Vector3.RIGHT * side, UV_CANVAS)
			_triangle(tool, base + at, tip + at, corner, Vector3.LEFT * side, UV_CANVAS)


## Fase 102: o andar saliente — a viga do balanço e as mãos-francesas embaixo, o enxaimel na frente de cada andar de cima
## (baldrame, frechal, esteios nas divisas e as escoras ao lado da janela, ou em diagonal na parede lisa) e, nas pontas da
## frente que avançou, o pedaço de parede que fecha o vão até a parede do lado.
static func _jetty(tool: SurfaceTool, spec: Spec) -> void:
	var hall := spec.hall()
	var size := hall.size_m()
	var step := size.x / hall.cells.x
	var floor_m := hall.floor_m()
	var shift := spec.hall_offset()
	var front := -size.y * 0.5
	var out := front - JETTY_M
	var timber_z := out - 0.03
	_box(tool, shift + Vector3(0.0, floor_m - 0.07, (front + out) * 0.5), Vector3(size.x, 0.14, JETTY_M), UV_TIMBER)
	for k: int in hall.cells.x + 1:
		var x := clampf(-size.x * 0.5 + step * k, -size.x * 0.5 + 0.06, size.x * 0.5 - 0.06)
		_bar(tool, shift + Vector3(x, floor_m - JETTY_BRACKET_M, front - 0.02), shift + Vector3(x, floor_m - 0.12, out + 0.04),
				0.09, UV_TIMBER)
	for level: int in range(1, hall.floors()):
		var y0 := level * floor_m
		var y1 := y0 + floor_m
		for index: int in hall.cells.x:
			var kind := slot(hall, 0, index, level)
			if kind == &"none":
				continue
			var x0 := -size.x * 0.5 + step * index
			var x1 := x0 + step
			var middle := (x0 + x1) * 0.5
			_box(tool, shift + Vector3(middle, y0 + 0.07, timber_z), Vector3(step, TIMBER_M, 0.06), UV_TIMBER)
			_box(tool, shift + Vector3(middle, y1 - 0.07, timber_z), Vector3(step, TIMBER_M, 0.06), UV_TIMBER)
			for x: float in [x0 + 0.05, x1 - 0.05]:
				_box(tool, shift + Vector3(x, (y0 + y1) * 0.5, timber_z), Vector3(TIMBER_M, floor_m, 0.06), UV_TIMBER)
			if kind == &"window":
				# uma escora de cada lado da janela, do pé do esteio até o alto do vão
				var beside := step * WINDOW_WIDTH * 0.5 + 0.14
				var top := y0 + floor_m * (WINDOW_CENTER + WINDOW_HEIGHT * 0.5)
				_bar(tool, shift + Vector3(x0 + 0.08, y0 + 0.12, timber_z), shift + Vector3(middle - beside, top, timber_z), 0.08,
						UV_TIMBER)
				_bar(tool, shift + Vector3(x1 - 0.08, y0 + 0.12, timber_z), shift + Vector3(middle + beside, top, timber_z), 0.08,
						UV_TIMBER)
			else:
				_bar(tool, shift + Vector3(x0 + 0.08, y0 + 0.12, timber_z), shift + Vector3(x1 - 0.08, y1 - 0.12, timber_z), 0.08,
						UV_TIMBER)
			# o vão entre a frente que avançou e a parede do lado, nas pontas de cada trecho da frente
			var last := hall.cells.x - 1
			if index == 0 or slot(hall, 0, index - 1, level) == &"none":
				_box(tool, shift + Vector3(x0 + 0.06, (y0 + y1) * 0.5, (front + out) * 0.5), Vector3(0.12, floor_m, JETTY_M),
						UV_WALL)
			if index == last or slot(hall, 0, index + 1, level) == &"none":
				_box(tool, shift + Vector3(x1 - 0.06, (y0 + y1) * 0.5, (front + out) * 0.5), Vector3(0.12, floor_m, JETTY_M),
						UV_WALL)


## A chaminé da casa no telhado, no referencial do prédio: a peça do kit esticada até passar da cumeeira.
static func _chimney_place(spec: Spec) -> Transform3D:
	var stack := spec.roof_m + 0.6
	var body := spec.hall().size_m()
	return Transform3D(Basis.IDENTITY, spec.hall_offset()) * Transform3D(Basis.from_scale(Vector3(3.0, stack, 3.0)),
			Vector3(body.x * 0.25 - 0.6, spec.height_m, -body.y * 0.2 + 0.5))


## Fase 100: a boca da chaminé (o meio do alto da peça), no referencial do prédio; null sem chaminé ou sem o kit.
static func chimney_top(spec: Spec) -> Variant:
	if spec == null or not spec.chimney:
		return null
	var place := _chimney_place(spec)
	var box := AABB()
	var first := true
	for part: Array in _parts_of(CHIMNEY):
		var mesh: Mesh = part[0]
		var transform: Transform3D = part[1]
		var piece := place * transform * mesh.get_aabb()
		box = piece if first else box.merge(piece)
		first = false
	if first:
		return null
	return Vector3(box.get_center().x, box.end.y, box.get_center().z)


## As peças paradas da silhueta (Fase 13). As que giram ficam em rotor().
static func _silhouette(tool: SurfaceTool, extra: SurfaceTool, spec: Spec) -> void:
	var size := spec.size_m()
	var top := spec.height_m + spec.roof_m
	match spec.silhouette:
		BuildingDef.Silhouette.HEADFRAME:
			# quatro pernas inclinadas do telhado até a plataforma da polia, travadas no meio
			var high := top + HEADFRAME_M
			var feet: Array[Vector3] = []
			var heads: Array[Vector3] = []
			for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				feet.append(Vector3(corner.x * minf(1.3, size.x * 0.3), top, corner.y * minf(1.0, size.y * 0.3)))
				heads.append(Vector3(corner.x * 0.55, high, corner.y * 0.3))
			for i: int in 4:
				_beam(tool, feet[i], heads[i], BEAM_M)
				var j := (i + 1) % 4
				_beam(tool, feet[i].lerp(heads[i], 0.5), feet[j].lerp(heads[j], 0.5), BEAM_M * 0.6)
				_beam(tool, heads[i], heads[j], BEAM_M * 0.6)
		BuildingDef.Silhouette.STALLS:
			# bancas no pátio, menos na coluna que leva à porta (e, desde a Fase 99, na fileira da arcada)
			var step := size.x / spec.cells.x
			var stall_rows := spec.court_rows - (1 if arcade_bays(spec) > 0 else 0)
			_arcade(extra, spec)
			for row: int in stall_rows:
				for column: int in spec.cells.x:
					if column == spec.door_index:
						continue
					var center := Vector3(-size.x * 0.5 + step * (column + 0.5), 0.0,
							-size.y * 0.5 + spec.cell_m * (row + 0.5))
					var scale := spec.cell_m * 0.8
					_append_piece(tool, STALLS[(row + column) % STALLS.size()],
							Transform3D(Basis(Vector3.UP, PI).scaled(Vector3.ONE * scale), center))
		BuildingDef.Silhouette.CRANE:
			if spec.dock:
				_hoist(tool, extra, spec)
			else:
				_crane(tool, extra, spec)
				if spec.storehouse:
					# o armazém do entreposto: portas do sótão e o guincho sob a empena da frente
					_hoist(tool, extra, spec)
		BuildingDef.Silhouette.CLERESTORY:
			# lanternim: uma faixa de parede mais alta ao longo da cumeeira, com o seu telhado
			var along_x := spec.roof != Roof.GABLE_Z
			var length := (size.x if along_x else size.y) * 0.7
			var ridge := spec.height_m + spec.roof_m
			_box(extra, Vector3(0.0, ridge + 0.35, 0.0), _uv_point(along_x, length, 1.3, 1.4), UV_WALL)
			_box(extra, Vector3(0.0, ridge + 1.08, 0.0), _uv_point(along_x, length + 0.4, 0.16, 2.2), UV_ROOF)
		BuildingDef.Silhouette.BANNERS:
			var hall := spec.hall()
			if hall.floors() > 1:
				# a bandeira fica sobre a parede lisa em cima da porta, um pouco à frente dela
				var place := Transform3D(Basis.IDENTITY, spec.hall_offset()) * _cell_transform(hall, 0, hall.door_index, 1)
				_append_piece(tool, BANNER, place * Transform3D(Basis.IDENTITY, Vector3(0.11, 0.0, 0.0)))
		BuildingDef.Silhouette.BELFRY:
			_belfry(extra, spec)
		BuildingDef.Silhouette.VERANDA:
			if spec.court_rows > 0:
				_veranda(extra, spec)
		BuildingDef.Silhouette.PUMPJACK:
			if spec.court_rows > 0:
				_pumpjack(tool, extra, spec)
		BuildingDef.Silhouette.TANKFARM:
			if spec.court_rows > 0:
				_tankfarm(extra, spec)
		BuildingDef.Silhouette.VATS:
			_vats(extra, spec)
		BuildingDef.Silhouette.MENAGERIE:
			_pens(extra, spec)
		BuildingDef.Silhouette.GALLERY:
			for spot: Vector3 in exhibit_spots(spec):
				_box(extra, spot - Vector3(0.0, GALLERY_PEDESTAL_M * 0.5, 0.0), Vector3(0.7, GALLERY_PEDESTAL_M, 0.7), UV_LIGHT_STONE)
				_box(extra, spot - Vector3(0.0, 0.05, 0.0), Vector3(0.82, 0.1, 0.82), UV_LIGHT_STONE)
	if spec.dock:
		_dock(extra, spec)


## Fase 73: as medidas do cavalo-de-pau no pátio — o fundo do pátio (z da frente da área), a profundidade dele, o eixo
## do balancim e quanto o balancim sai para a frente (até a cabeça) e para trás (até a biela).
static func pumpjack_layout(spec: Spec) -> Dictionary:
	var size := spec.size_m()
	var front := -size.y * 0.5
	var depth := spec.court_rows * spec.cell_m
	var middle := front + depth * 0.5
	return {
		&"front": front,
		&"depth": depth,
		&"pivot": Vector3(0.0, PUMPJACK_PIVOT_M, middle + depth * 0.05),
		&"ahead": depth * 0.45,
		&"behind": depth * 0.34,
		&"gearbox": Vector3(0.0, 0.62, middle + depth * 0.36),
	}


## As peças paradas do cavalo-de-pau: o estrado, o cavalete em A com a escora, o mancal do eixo, a caixa de engrenagens
## com as manivelas e os contrapesos, e a cabeça do poço com a haste, embaixo da cabeça do balancim.
static func _pumpjack(tool: SurfaceTool, extra: SurfaceTool, spec: Spec) -> void:
	var layout := pumpjack_layout(spec)
	var depth: float = layout[&"depth"]
	var pivot: Vector3 = layout[&"pivot"]
	var gearbox: Vector3 = layout[&"gearbox"]
	var ahead: float = layout[&"ahead"]
	var middle: float = layout[&"front"] + depth * 0.5
	_box(extra, Vector3(0.0, 0.12, middle), Vector3(1.0, 0.24, depth * 0.86), UV_TIMBER)
	for side: float in [-1.0, 1.0]:
		_beam(tool, Vector3(side * 0.7, 0.24, pivot.z), Vector3(side * 0.12, pivot.y - 0.12, pivot.z), 0.18)
	_beam(tool, Vector3(0.0, 0.24, pivot.z + depth * 0.22), Vector3(0.0, pivot.y - 0.15, pivot.z + 0.05), 0.16)
	_box(extra, pivot + Vector3(0.0, -0.05, 0.0), Vector3(0.5, 0.2, 0.3), UV_IRON)
	_box(extra, gearbox, Vector3(0.66, 0.76, 0.6), UV_IRON)
	for side: float in [-1.0, 1.0]:
		_box(extra, gearbox + Vector3(side * 0.42, 0.0, 0.0), Vector3(0.12, 1.0, 0.34), UV_IRON)
	var well_z := pivot.z - ahead - 0.12
	_box(extra, Vector3(0.0, 0.4, well_z), Vector3(0.4, 0.8, 0.4), UV_IRON)
	_box(extra, Vector3(0.0, 1.2, well_z), Vector3(0.06, 0.8, 0.06), UV_IRON)


## Fase 74: onde fica cada vaga de peça do zoológico (o meio do cercado, no chão) ou do museu (o tampo do pedestal), no
## referencial do prédio, na ordem em que as peças entram; vazio fora dessas silhuetas ou sem pátio.
static func exhibit_spots(spec: Spec) -> Array[Vector3]:
	var spots: Array[Vector3] = []
	if spec.court_rows == 0:
		return spots
	var size := spec.size_m()
	var front := -size.y * 0.5
	var depth := spec.court_rows * spec.cell_m
	match spec.silhouette:
		BuildingDef.Silhouette.MENAGERIE:
			var rows := maxi(1, spec.court_rows / 2)
			for row: int in rows:
				for column: int in 3:
					# Fase 77: em cima do piso (até a Fase 76 o bicho ficava com as patas no piso)
					spots.append(Vector3(size.x * (column - 1) / 3.0, FOUNDATION_UP_M, front + depth * (row + 0.5) / rows))
		BuildingDef.Silhouette.GALLERY:
			var z := front + depth * 0.5
			for k: int in 6:
				# três de cada lado do caminho da porta, do meio para fora
				var side := -1.0 if k % 2 == 0 else 1.0
				spots.append(Vector3(side * (1.6 + (k / 2) * 1.35) * size.x / 9.7, GALLERY_PEDESTAL_M, z))
	return spots


## Os cercados do zoológico: em volta de cada vaga, a cerca de madeira (mourões nos cantos e no meio dos lados, duas
## travessas) com a abertura do portão no lado da frente.
static func _pens(tool: SurfaceTool, spec: Spec) -> void:
	var spots := exhibit_spots(spec)
	if spots.is_empty():
		return
	var half := pen_half(spec)
	for spot: Vector3 in spots:
		var corners: Array[Vector3] = [spot + Vector3(-half.x, 0.0, -half.y), spot + Vector3(half.x, 0.0, -half.y),
				spot + Vector3(half.x, 0.0, half.y), spot + Vector3(-half.x, 0.0, half.y)]
		for i: int in 4:
			var a := corners[i]
			var b := corners[(i + 1) % 4]
			for t: float in [0.0, 0.5]:
				var post := a.lerp(b, t)
				_box(tool, post + Vector3(0.0, MENAGERIE_FENCE_M * 0.55, 0.0), Vector3(0.12, MENAGERIE_FENCE_M * 1.1, 0.12), UV_TIMBER)
			for rail: float in [0.4, 0.85]:
				var y := Vector3(0.0, MENAGERIE_FENCE_M * rail, 0.0)
				if i == 0:
					# o lado da frente com o portão (um vão no meio)
					_rail(tool, a + y, a.lerp(b, 0.4) + y)
					_rail(tool, a.lerp(b, 0.6) + y, b + y)
				else:
					_rail(tool, a + y, b + y)


## Fase 78: os tanques da usina a petróleo no pátio — cada um [meio da base, raio, altura do costado], lado a lado.
static func tank_layout(spec: Spec) -> Array[Array]:
	var tanks: Array[Array] = []
	if spec.court_rows == 0:
		return tanks
	var size := spec.size_m()
	var depth := spec.court_rows * spec.cell_m
	var middle := -size.y * 0.5 + depth * 0.5
	var radius := minf(depth * 0.4, size.x * 0.18)
	var height := minf(spec.height_m * 0.6, TANK_MAX_M)
	for side: float in [-1.0, 1.0]:
		tanks.append([Vector3(side * size.x * 0.25, 0.0, middle), radius, height])
	return tanks


## O pátio dos tanques: o dique baixo de pedra em volta (com a passagem até a porta no meio da frente), cada tanque com o
## teto em cone, os anéis de ferro, a escada na frente e o tubo até a parede do galpão.
static func _tankfarm(extra: SurfaceTool, spec: Spec) -> void:
	var size := spec.size_m()
	var front := -size.y * 0.5 + 0.15
	var wall_z := spec.hall_offset().z - spec.hall().size_m().y * 0.5
	var left := -size.x * 0.5 + 0.15
	var y := TANKFARM_BUND_M * 0.5
	var gap := 0.9
	_box(extra, Vector3((left - gap) * 0.5, y, front), Vector3(-gap - left, TANKFARM_BUND_M, 0.2), UV_STONE)
	_box(extra, Vector3((gap - left) * 0.5, y, front), Vector3(-gap - left, TANKFARM_BUND_M, 0.2), UV_STONE)
	for side: float in [-1.0, 1.0]:
		_box(extra, Vector3(side * -left, y, (front + wall_z) * 0.5), Vector3(0.2, TANKFARM_BUND_M, wall_z - front), UV_STONE)
	for tank: Array in tank_layout(spec):
		var base: Vector3 = tank[0]
		var radius: float = tank[1]
		var height: float = tank[2]
		_tank(extra, base, radius, height, UV_LIGHT_STONE)
		for ring: float in [0.33, 0.66]:
			_tank(extra, base + Vector3(0.0, height * ring - 0.05, 0.0), radius + 0.03, 0.1, UV_IRON, false)
		# a escada: dois montantes e os degraus, encostados na frente do costado
		var face := base.z - radius - 0.08
		for rail: float in [-0.22, 0.22]:
			_bar(extra, Vector3(base.x + rail, 0.0, face), Vector3(base.x + rail, height + 0.6, face), 0.05, UV_IRON)
		var rung := 0.5
		while rung < height + 0.4:
			_box(extra, Vector3(base.x, rung, face), Vector3(0.44, 0.04, 0.04), UV_IRON)
			rung += 0.5
		# o tubo do fundo do tanque até o galpão, num suporte
		var from := Vector3(base.x * 0.6, 0.7, base.z + radius * 0.7)
		_bar(extra, from, Vector3(base.x * 0.6, 0.7, wall_z), 0.16, UV_IRON)
		_box(extra, Vector3(base.x * 0.6, 0.3, (from.z + wall_z) * 0.5), Vector3(0.12, 0.6, 0.12), UV_IRON)


## Tanque vertical de TANK_SIDES faces com a base em "base"; com teto, o cone baixo em cima.
static func _tank(tool: SurfaceTool, base: Vector3, radius: float, height: float, uv: Vector2, roof: bool = true) -> void:
	var top := base + Vector3(0.0, height, 0.0)
	var peak := top + Vector3(0.0, radius * 0.25, 0.0)
	for i: int in TANK_SIDES:
		var a0 := TAU * i / TANK_SIDES
		var a1 := TAU * (i + 1) / TANK_SIDES
		var d0 := Vector3(cos(a0), 0.0, sin(a0)) * radius
		var d1 := Vector3(cos(a1), 0.0, sin(a1)) * radius
		_quad(tool, base + d0, base + d1, top + d1, top + d0, (d0 + d1) * 0.5, uv)
		if roof:
			_triangle(tool, top + d0, top + d1, peak, (d0 + d1) * 0.5 + Vector3(0.0, radius, 0.0), uv)
		else:
			_triangle(tool, top + d0, top + d1, top, Vector3.UP, uv)


## Meia largura (x) e meia profundidade (z) de cada cercado do zoológico, da vaga até a linha da cerca.
static func pen_half(spec: Spec) -> Vector2:
	var rows := maxi(1, spec.court_rows / 2)
	return Vector2(spec.size_m().x / 3.0, spec.court_rows * spec.cell_m / rows) * 0.5 - Vector2(0.25, 0.25)


static func _rail(tool: SurfaceTool, a: Vector3, b: Vector3) -> void:
	var middle := (a + b) * 0.5
	var along := b - a
	var size := Vector3(absf(along.x) + 0.06, 0.08, absf(along.z) + 0.06)
	_box(tool, middle, size, UV_TIMBER)


## Onde fica a plataforma de carga (Fase 23): x entre as rampas, z da frente da área até a parede do corpo,
## y do chão até o tampo.
static func dock_box(spec: Spec) -> AABB:
	var size := spec.size_m()
	var wall_z := spec.hall_offset().z - spec.hall().size_m().y * 0.5
	var front := -size.y * 0.5 + 0.15
	var left := -size.x * 0.5 + DOCK_RAMP_M
	return AABB(Vector3(left, 0.0, front), Vector3(size.x - DOCK_RAMP_M * 2.0, DOCK_M, wall_z - front))


static func _dock(tool: SurfaceTool, spec: Spec) -> void:
	var box := dock_box(spec)
	var center := box.get_center()
	var top := box.end.y
	# corpo de tijolo, tampo de tábuas que sai um pouco e a defensa de madeira na frente
	_box(tool, Vector3(center.x, (top - 0.1) * 0.5 - 0.05, center.z), Vector3(box.size.x, top - 0.1 + 0.1, box.size.z), UV_WALL)
	_box(tool, Vector3(center.x, top - 0.05, center.z - 0.05), Vector3(box.size.x + 0.1, 0.1, box.size.z + 0.1), UV_TIMBER)
	_box(tool, Vector3(center.x, top - 0.28, box.position.z - 0.08), Vector3(box.size.x, 0.22, 0.12), UV_TIMBER)
	# as rampas descem das pontas até o chão
	for side: float in [-1.0, 1.0]:
		var high := box.end.x if side > 0.0 else box.position.x
		var low := high + side * DOCK_RAMP_M
		_ramp(tool, low, high, box.position.z + 0.1, box.end.z, top - 0.02)
	if spec.level < DOCK_CANOPY_LEVEL:
		return
	# alpendre sobre a plataforma, preso na parede por mãos-francesas de ferro
	var floor_m := spec.hall().floor_m()
	var high_point := Vector3(0.0, floor_m * DOCK_CANOPY_WALL, box.end.z)
	var low_point := Vector3(0.0, floor_m * DOCK_CANOPY_EAVE, box.position.z - DOCK_CANOPY_OUT_M)
	_lean_to(tool, high_point, low_point, spec.size_m().x - 0.2)
	var bracket_step := spec.size_m().x / spec.cells.x
	for k: int in spec.cells.x + 1:
		var x := clampf(-spec.size_m().x * 0.5 + bracket_step * k, -spec.size_m().x * 0.5 + 0.2, spec.size_m().x * 0.5 - 0.2)
		var wall_foot := Vector3(x, floor_m * DOCK_CANOPY_EAVE - 0.9, box.end.z)
		var under := Vector3(x, floor_m * DOCK_CANOPY_EAVE + 0.05, box.position.z + 0.2)
		_bar(tool, wall_foot, under, 0.07, UV_IRON)
		_bar(tool, Vector3(x, high_point.y - 0.05, box.end.z), under, 0.06, UV_IRON)


## Rampa ao longo de x: do chão em low_x até "top" em high_x, de z0 a z1 (cunha: a face inclinada e os dois lados).
static func _ramp(tool: SurfaceTool, low_x: float, high_x: float, z0: float, z1: float, top: float) -> void:
	var away := Vector3(signf(low_x - high_x), 1.0, 0.0)
	_quad(tool, Vector3(low_x, 0.0, z0), Vector3(low_x, 0.0, z1), Vector3(high_x, top, z1), Vector3(high_x, top, z0), away, UV_STONE)
	for z: float in [z0, z1]:
		_triangle(tool, Vector3(low_x, 0.0, z), Vector3(high_x, 0.0, z), Vector3(high_x, top, z),
				Vector3(0.0, 0.0, signf(z - (z0 + z1) * 0.5)), UV_STONE)
	# o meio-fio de madeira da beira da rampa
	for z: float in [z0 + 0.05, z1 - 0.05]:
		_bar(tool, Vector3(low_x, 0.05, z), Vector3(high_x, top + 0.05, z), 0.1, UV_TIMBER)


## Barra de seção quadrada de a até b, numa caixa girada.
static func _bar(tool: SurfaceTool, a: Vector3, b: Vector3, thickness: float, uv: Vector2) -> void:
	var along := b - a
	if along.length_squared() < 1e-6:
		return
	var z := along.normalized()
	var x := (Vector3.UP if absf(z.y) < 0.95 else Vector3.RIGHT).cross(z).normalized()
	var y := z.cross(x)
	_box_at(tool, Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(thickness, thickness, along.length()), uv)


## Telhado de uma água de "high" (na parede) até "low" (o beiral), com a largura em x.
static func _lean_to(tool: SurfaceTool, high: Vector3, low: Vector3, width: float) -> void:
	var along := (low - high).normalized()
	# x de lado a lado, z subindo a água e y para fora dela
	var basis := Basis(Vector3.RIGHT, -along.cross(Vector3.RIGHT).normalized(), -along)
	_box_at(tool, Transform3D(basis, (high + low) * 0.5 + basis.y * ROOF_THICKNESS_M * 0.5),
			Vector3(width, ROOF_THICKNESS_M, high.distance_to(low)), UV_ROOF)


## Onde fica a varanda (Fase 23): x de um lado ao outro da área, z da frente da área até a parede do corpo,
## y do chão até o alto da água na parede.
static func veranda_box(spec: Spec) -> AABB:
	var size := spec.size_m()
	var hall := spec.hall()
	var wall_z := spec.hall_offset().z - hall.size_m().y * 0.5
	var front := -size.y * 0.5
	return AABB(Vector3(-size.x * 0.5, 0.0, front), Vector3(size.x, hall.floor_m() * VERANDA_WALL, wall_z - front))


static func _veranda(tool: SurfaceTool, spec: Spec) -> void:
	var box := veranda_box(spec)
	var hall := spec.hall()
	var floor_m := hall.floor_m()
	var left := box.position.x
	var right := box.end.x
	var wall := box.end.z
	# o assoalho começa VERANDA_STEP_M para dentro: na frente da porta ficam os degraus
	var front := box.position.z + VERANDA_STEP_M
	var deck := VERANDA_DECK_M
	_box(tool, Vector3(0.0, (deck - 0.1) * 0.5, (front + wall) * 0.5), Vector3(right - left, deck + 0.1, wall - front), UV_TIMBER)
	var step := (right - left) / spec.cells.x
	var door_x := left + step * (spec.door_index + 0.5)
	var stair := step * 0.7
	_box(tool, Vector3(door_x, deck / 3.0, front - VERANDA_STEP_M * 0.25), Vector3(stair, deck * 2.0 / 3.0, VERANDA_STEP_M * 0.5), UV_STONE)
	_box(tool, Vector3(door_x, deck / 6.0, front - VERANDA_STEP_M * 0.75), Vector3(stair, deck / 3.0, VERANDA_STEP_M * 0.5), UV_STONE)
	# esteios na frente, um em cada divisa de célula, e a viga do beiral em cima deles
	var eave := floor_m * VERANDA_EAVE
	var post_z := front + VERANDA_POST_M * 0.5 + 0.04
	var post_xs: Array[float] = []
	for k: int in spec.cells.x + 1:
		post_xs.append(clampf(left + step * k, left + VERANDA_POST_M * 0.5, right - VERANDA_POST_M * 0.5))
	for x: float in post_xs:
		_box(tool, Vector3(x, (deck + eave) * 0.5, post_z), Vector3(VERANDA_POST_M, eave - deck, VERANDA_POST_M), UV_TIMBER)
		# mão-francesa: o braço do esteio até a viga
		_box(tool, Vector3(x, eave - 0.12, post_z), Vector3(VERANDA_POST_M * 2.2, 0.08, VERANDA_POST_M * 0.8), UV_TIMBER)
	_box(tool, Vector3(0.0, eave + 0.09, post_z), Vector3(right - left, 0.18, VERANDA_POST_M * 1.1), UV_TIMBER)
	# guarda-corpo entre os esteios, menos no vão da porta, e nas duas pontas até a parede
	for k: int in spec.cells.x:
		if k == spec.door_index:
			continue
		_railing(tool, Vector3(post_xs[k], deck, post_z), Vector3(post_xs[k + 1], deck, post_z), UV_TIMBER,
				VERANDA_RAIL_M, 0.06, VERANDA_RAIL_STEP_M)
	for x: float in [post_xs[0], post_xs[post_xs.size() - 1]]:
		_railing(tool, Vector3(x, deck, post_z), Vector3(x, deck, wall), UV_TIMBER, VERANDA_RAIL_M, 0.06, VERANDA_RAIL_STEP_M)
	# telhado de uma água, da parede (entre os andares) até um pouco além dos esteios
	_lean_to(tool, Vector3(0.0, floor_m * VERANDA_WALL, wall), Vector3(0.0, eave + 0.18, post_z - VERANDA_OVERHANG_M),
			right - left + VERANDA_OVERHANG_M * 2.0)


## Guindaste de porto (Fase 23): o mastro no canto de trás, por fora da parede do lado, e a lança subindo
## para a frente ao longo dela.
static func crane_mast(spec: Spec) -> Vector3:
	var size := spec.size_m()
	return Vector3(size.x * 0.5 + 0.35, 0.0, size.y * 0.5 - 0.35)


static func crane_height(spec: Spec) -> float:
	return spec.height_m + spec.roof_m + CRANE_M


static func crane_tip(spec: Spec) -> Vector3:
	var mast := crane_mast(spec)
	return Vector3(mast.x + CRANE_REACH_M, crane_height(spec) + CRANE_RISE_M, -spec.size_m().y * 0.2)


## Onde fica o gancho (o caixote pende logo abaixo).
static func crane_hook(spec: Spec) -> Vector3:
	var tip := crane_tip(spec)
	return Vector3(tip.x, CRANE_LOAD_M + CRANE_CRATE_M + 0.45, tip.z)


static func _crane(tool: SurfaceTool, extra: SurfaceTool, spec: Spec) -> void:
	var mast := crane_mast(spec)
	var high := crane_height(spec)
	var top := mast + Vector3(0.0, high, 0.0)
	var tip := crane_tip(spec)
	var foot := mast + Vector3(0.0, high * CRANE_BOOM_FOOT, 0.0)
	# soco de pedra, mastro, escora para a frente e a lança com os tirantes de ferro do topo à ponta
	_box(extra, mast + Vector3(0.0, 0.2, 0.0), Vector3(1.0, 0.4 + FOUNDATION_DOWN_M, 1.0), UV_STONE)
	_beam(tool, mast, top, BEAM_M * 1.3)
	_beam(tool, mast + Vector3(0.0, 0.0, -1.5), mast + Vector3(0.0, high * 0.4, 0.0), BEAM_M * 0.7)
	_beam(tool, foot, tip, BEAM_M)
	for side: float in [-1.0, 1.0]:
		var spread := Vector3(side * 0.12, 0.0, 0.0)
		_bar(extra, top + spread, tip + spread + Vector3(0.0, 0.1, 0.0), 0.06, UV_IRON)
	_box(extra, top + Vector3(0.0, 0.12, 0.0), Vector3(0.6, 0.24, 0.6), UV_TIMBER)
	# sarilho no pé do mastro: dois montantes, o tambor e as manivelas de ferro
	var drum := mast + Vector3(0.0, 0.75, -0.7)
	for side: float in [-1.0, 1.0]:
		_box(extra, drum + Vector3(side * 0.38, -0.38, 0.0), Vector3(0.1, 0.9, 0.5), UV_TIMBER)
		var crank := drum + Vector3(side * 0.48, 0.0, 0.0)
		_bar(extra, crank, crank + Vector3(0.0, 0.3, -0.12), 0.05, UV_IRON)
		_bar(extra, crank + Vector3(0.0, 0.3, -0.12), crank + Vector3(side * 0.22, 0.3, -0.12), 0.05, UV_IRON)
	_drum(extra, drum, CRANE_DRUM_RADIUS_M, 0.66, UV_TIMBER)
	# cabo do tambor à ponta, moitão e o cabo descendo até o gancho, com o caixote nas lingas
	_bar(extra, drum + Vector3(0.0, CRANE_DRUM_RADIUS_M, 0.0), tip, CRANE_ROPE_M, UV_IRON)
	_box(extra, tip + Vector3(0.0, -0.2, 0.0), Vector3(0.22, 0.34, 0.3), UV_TIMBER)
	_hanging_crate(extra, tip + Vector3(0.0, -0.35, 0.0), crane_hook(spec), CRANE_LOAD_M)


## Guincho do armazém com plataforma: a ponta da viga, sobre a coluna da porta.
static func hoist_tip(spec: Spec) -> Vector3:
	var hall := spec.hall()
	var size := spec.size_m()
	var x := -size.x * 0.5 + size.x / spec.cells.x * (spec.door_index + 0.5)
	return Vector3(x, hall.height_m - 0.3, -size.y * 0.5 - HOIST_OUT_M)


static func _hoist(tool: SurfaceTool, extra: SurfaceTool, spec: Spec) -> void:
	var hall := spec.hall()
	var tip := hoist_tip(spec)
	var wall_z := spec.hall_offset().z - hall.size_m().y * 0.5
	# portas de carga de tábuas nos andares de cima, sobre a porta de baixo
	for level: int in range(1, hall.floors()):
		var bottom := level * hall.floor_m() + 0.1
		var height := hall.floor_m() * 0.78
		_box(extra, Vector3(tip.x, bottom + height * 0.5, wall_z - 0.05), Vector3(1.1, height, 0.1), UV_TIMBER)
		_box(extra, Vector3(tip.x, bottom + height * 0.5, wall_z - 0.11), Vector3(0.08, height, 0.04), UV_IRON)
	# a viga entra na parede e a mão-francesa de ferro a segura por baixo
	var root := Vector3(tip.x, tip.y, wall_z + 0.3)
	_beam(tool, root, tip, BEAM_M * 0.8)
	_bar(extra, Vector3(tip.x, tip.y - 1.1, wall_z), tip.lerp(root, 0.45) + Vector3(0.0, -0.1, 0.0), 0.07, UV_IRON)
	# moitão, cabo e o caixote nas lingas
	_box(extra, tip + Vector3(0.0, -0.3, 0.0), Vector3(0.22, 0.34, 0.3), UV_TIMBER)
	var hook := Vector3(tip.x, HOIST_LOAD_M + CRANE_CRATE_M + 0.45, tip.z)
	_hanging_crate(extra, tip + Vector3(0.0, -0.45, 0.0), hook, HOIST_LOAD_M)


## Cabo de "from" até o gancho e o caixote pendurado nele pelas lingas, com o fundo em "bottom".
static func _hanging_crate(tool: SurfaceTool, from: Vector3, hook: Vector3, bottom: float) -> void:
	_bar(tool, from, hook, CRANE_ROPE_M, UV_IRON)
	_box(tool, hook + Vector3(0.0, -0.08, 0.0), Vector3(0.14, 0.16, 0.14), UV_IRON)
	var crate := Vector3(hook.x, bottom + CRANE_CRATE_M * 0.5, hook.z)
	_box(tool, crate, Vector3.ONE * CRANE_CRATE_M, UV_TIMBER)
	var half := CRANE_CRATE_M * 0.5 - 0.05
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		_bar(tool, hook + Vector3(0.0, -0.16, 0.0), crate + Vector3(corner.x * half, CRANE_CRATE_M * 0.5, corner.y * half),
				0.03, UV_TIMBER)


## Tambor de oito faces ao longo de x, com as tampas.
static func _drum(tool: SurfaceTool, center: Vector3, radius: float, length: float, uv: Vector2) -> void:
	var near := center - Vector3(length * 0.5, 0.0, 0.0)
	var far := center + Vector3(length * 0.5, 0.0, 0.0)
	for i: int in 8:
		var a0 := TAU * i / 8.0
		var a1 := TAU * (i + 1) / 8.0
		var d0 := Vector3(0.0, cos(a0), sin(a0)) * radius
		var d1 := Vector3(0.0, cos(a1), sin(a1)) * radius
		_quad(tool, near + d0, far + d0, far + d1, near + d1, (d0 + d1) * 0.5, uv)
		_triangle(tool, near, near + d0, near + d1, Vector3.LEFT, uv)
		_triangle(tool, far, far + d0, far + d1, Vector3.RIGHT, uv)


## Campanário (Fase 18) no canto da frente à esquerda: o fuste de parede até BELFRY_SHAFT_M acima do
## beiral, a sineira (quatro pilares, laje de pedra embaixo e em cima) com o sino pendurado na trave, e
## a agulha de quatro águas com a cruz de ferro.
static func belfry_center(spec: Spec) -> Vector3:
	var size := spec.size_m()
	var half := BELFRY_SIDE_M * 0.5
	return Vector3(-size.x * 0.5 + half - BELFRY_OUT_M, 0.0, -size.y * 0.5 + half - BELFRY_OUT_M)


static func belfry_top(spec: Spec) -> float:
	return spec.height_m + BELFRY_SHAFT_M + BELFRY_OPEN_M + 0.3 + BELFRY_SPIRE_M


static func _belfry(tool: SurfaceTool, spec: Spec) -> void:
	var center := belfry_center(spec)
	var side := BELFRY_SIDE_M
	var shaft := spec.height_m + BELFRY_SHAFT_M
	_box(tool, center + Vector3(0.0, shaft * 0.5 - FOUNDATION_DOWN_M * 0.5, 0.0),
			Vector3(side, shaft + FOUNDATION_DOWN_M, side), UV_WALL)
	# cornija no alto do fuste e no beiral da igreja
	for height: float in [spec.height_m - 0.1, shaft - 0.15]:
		_box(tool, center + Vector3(0.0, height, 0.0), Vector3(side + 0.24, 0.3, side + 0.24), UV_STONE)
	var pier := 0.42
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var at := center + Vector3(corner.x, 0.0, corner.y) * (side - pier) * 0.5
		_box(tool, at + Vector3(0.0, shaft + BELFRY_OPEN_M * 0.5, 0.0), Vector3(pier, BELFRY_OPEN_M, pier), UV_WALL)
	var cap := shaft + BELFRY_OPEN_M
	_box(tool, center + Vector3(0.0, cap + 0.15, 0.0), Vector3(side + 0.3, 0.3, side + 0.3), UV_STONE)
	# trave de madeira de um lado ao outro e o sino pendurado nela
	var yoke := cap - 0.25
	_box(tool, center + Vector3(0.0, yoke, 0.0), Vector3(side - pier, 0.16, 0.2), UV_TIMBER)
	_bell(tool, center + Vector3(0.0, yoke - 0.1 - BELL_HEIGHT_M, 0.0))
	# agulha
	var base := cap + 0.3
	var half := side * 0.5 + 0.1
	var tip := center + Vector3(0.0, base + BELFRY_SPIRE_M, 0.0)
	var ring: Array[Vector3] = []
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		ring.append(center + Vector3(corner.x * half, base, corner.y * half))
	for i: int in 4:
		var a := ring[i]
		var b := ring[(i + 1) % 4]
		var middle := (a + b) * 0.5 - center
		_triangle(tool, a, b, tip, Vector3(middle.x, 0.5, middle.z), UV_ROOF)
	_box(tool, tip + Vector3(0.0, 0.55, 0.0), Vector3(0.08, 1.1, 0.08), UV_IRON)
	_box(tool, tip + Vector3(0.0, 0.75, 0.0), Vector3(0.55, 0.08, 0.08), UV_IRON)


## Sino de bronze: tronco de cone de BELL_SEGMENTS faces que se abre na boca, com a coroa em cima; a
## boca fica em "mouth".
const BELL_SEGMENTS := 12
const BELL_PROFILE: Array[Vector2] = [Vector2(0.38, 1.0), Vector2(0.55, 0.62), Vector2(0.72, 0.22), Vector2(1.0, 0.0)]


static func _bell(tool: SurfaceTool, mouth: Vector3) -> void:
	for k: int in BELL_PROFILE.size() - 1:
		var upper := BELL_PROFILE[k]
		var lower := BELL_PROFILE[k + 1]
		for i: int in BELL_SEGMENTS:
			var a0 := TAU * i / BELL_SEGMENTS
			var a1 := TAU * (i + 1) / BELL_SEGMENTS
			var d0 := Vector3(cos(a0), 0.0, sin(a0))
			var d1 := Vector3(cos(a1), 0.0, sin(a1))
			var y_up := Vector3.UP * upper.y * BELL_HEIGHT_M
			var y_low := Vector3.UP * lower.y * BELL_HEIGHT_M
			_quad(tool, mouth + d0 * lower.x * BELL_RADIUS_M + y_low, mouth + d1 * lower.x * BELL_RADIUS_M + y_low,
					mouth + d1 * upper.x * BELL_RADIUS_M + y_up, mouth + d0 * upper.x * BELL_RADIUS_M + y_up,
					(d0 + d1) * 0.5 + Vector3.UP * 0.3, UV_BRONZE)
	var crown := BELL_PROFILE[0].x * BELL_RADIUS_M
	_box(tool, mouth + Vector3(0.0, BELL_HEIGHT_M + 0.02, 0.0), Vector3(crown * 1.6, 0.06, crown * 1.6), UV_BRONZE)


## Portão largo (Fase 18) diante do vão em arco da fábrica: dois esteios e a verga de madeira, e as duas
## folhas de tábua abertas para fora, presas nos esteios.
static func _gate(tool: SurfaceTool, extra: SurfaceTool, hall: Spec, offset: Transform3D) -> void:
	var door := offset * _wall_point(hall, 0, hall.door_index, 0)
	var width := hall.size_m().x / hall.cells.x * GATE_CELLS
	var height := hall.floor_m() * GATE_HEIGHT
	var out := _face_normal(0) * 0.12
	for side: float in [-1.0, 1.0]:
		var post := door + out + Vector3(side * width * 0.5, 0.0, 0.0)
		_beam(tool, post, post + Vector3(0.0, height + 0.25, 0.0), 0.24)
		# a folha sai do esteio para o meio do vão e gira para fora
		var swing := Basis(Vector3.UP, -side * GATE_OPEN)
		var leaf := width * 0.5 - 0.1
		var along := swing * Vector3(-side, 0.0, 0.0)
		_box_at(extra, Transform3D(Basis.looking_at(along.cross(Vector3.UP), Vector3.UP),
				post + along * (leaf * 0.5 + 0.1) + Vector3(0.0, height * 0.5, 0.0)),
				Vector3(leaf, height, 0.08), UV_TIMBER)
	_beam(tool, door + out + Vector3(-width * 0.5 - 0.2, height + 0.2, 0.0),
			door + out + Vector3(width * 0.5 + 0.2, height + 0.2, 0.0), 0.26)


## Caixa girada: a caixa do _box no referencial "place" (x, y e z da base são largura, altura e fundo).
static func _box_at(tool: SurfaceTool, place: Transform3D, size: Vector3, uv: Vector2) -> void:
	var local := SurfaceTool.new()
	local.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(local, Vector3.ZERO, size, uv)
	tool.append_from(local.commit(), 0, place)


## O detalhe da casa pela classe (Fase 13). As peças do kit têm a face de fora em x = 0,5, como as
## paredes.
static func _trim(tool: SurfaceTool, extra: SurfaceTool, spec: Spec) -> void:
	var hall := spec.hall()
	var offset := Transform3D(Basis.IDENTITY, spec.hall_offset())
	match spec.trim:
		TierDef.HouseTrim.YARD:
			if spec.court_rows == 0:
				return
			# cerca na borda da área, em volta das fileiras da frente, com o portão diante da porta
			for index: int in spec.cells.x:
				var piece := GATE if index == spec.door_index else FENCE
				_append_piece(tool, piece, _fence_place(spec, 0, index))
			for row: int in spec.court_rows:
				_append_piece(tool, FENCE, _fence_place(spec, 1, row))
				_append_piece(tool, FENCE, _fence_place(spec, 3, row))
		TierDef.HouseTrim.FLOWER_BOXES:
			# floreira debaixo de cada janela da frente, dos andares de cima
			for level: int in range(1, hall.floors()):
				for index: int in hall.cells.x:
					if slot(hall, 0, index, level) == &"window":
						var under := hall.floor_m() * (WINDOW_CENTER - WINDOW_HEIGHT * 0.5) - 0.18
						_append_piece(tool, HEDGE, offset * _face_place(hall, 0, index, level,
								Vector3(0.64, 0.9, 0.5), FLOWER_BOX_OUT_M, under))
		TierDef.HouseTrim.BALCONIES, TierDef.HouseTrim.PORTICO:
			# sacada corrida no primeiro andar (e nos do meio, nos engenheiros): piso de tábuas e grade de ferro
			var top := hall.floors() - 1 if spec.trim == TierDef.HouseTrim.BALCONIES else mini(2, hall.floors())
			# Fase 97: com o torreão no canto de +X, a sacada para uma célula antes (o canto é dele)
			var cells_out := hall.cells.x - (1 if hall.turret else 0)
			for level: int in range(1, top):
				for index: int in cells_out:
					# o piso de tábuas vai da parede (x = 0 da peça) até a frente da sacada
					_append_piece(tool, PLANKS, offset * _face_place(hall, 0, index, level,
							Vector3(BALCONY_OUT_M * 2.0, 2.0, 1.0), BALCONY_OUT_M, -0.12))
				# grade de ferro na frente e nas duas pontas da sacada corrida
				var floor_y := level * hall.floor_m()
				var half := hall.size_m() * 0.5
				var step_x := hall.size_m().x / hall.cells.x
				var right := half.x - (step_x if hall.turret else 0.0)
				var wall := spec.hall_offset() + Vector3(0.0, floor_y, -half.y)
				var out := Vector3(0.0, 0.0, -BALCONY_OUT_M)
				# investidores: balaustrada de pedra (Fase 24); engenheiros: a grade de ferro
				var fence := _balustrade if spec.trim == TierDef.HouseTrim.PORTICO else _railing
				fence.call(extra, wall + out + Vector3(-half.x, 0.0, 0.0), wall + out + Vector3(right, 0.0, 0.0))
				for end: float in [-half.x, right]:
					fence.call(extra, wall + Vector3(end, 0.0, 0.0), wall + out + Vector3(end, 0.0, 0.0))
				# consolos de pedra sob a sacada, em cada divisa de célula (os das pontas um pouco para dentro)
				for k: int in cells_out + 1:
					var x := clampf(-half.x + step_x * k, -half.x + CORBEL_WIDTH_M, right - CORBEL_WIDTH_M)
					_corbel(extra, wall + Vector3(x, -0.12, 0.0), BALCONY_OUT_M * 0.85)
			if spec.trim == TierDef.HouseTrim.PORTICO:
				# duas colunas de pedra dos lados da porta e sebe diante das outras células do térreo
				var door := _wall_point(hall, 0, hall.door_index, 0)
				var step := hall.size_m().x / hall.cells.x
				for side: float in [-0.42, 0.42]:
					var foot := door + _face_normal(0) * 0.35 + Vector3(side * step, 0.0, 0.0)
					_append_piece(tool, PILLAR, offset * Transform3D(Basis.from_scale(Vector3(1.7,
							hall.floor_m() * PORTICO_HEIGHT, 2.2)), foot))
				# o frontão fica no alto da fachada, sobre a porta: em cima do pórtico ele atravessava a sacada
				_pediment(extra, offset * door, step * 1.4, hall.height_m)
				for index: int in hall.cells.x:
					if index != hall.door_index:
						_append_piece(tool, HEDGE, offset * _face_place(hall, 0, index, 0,
								Vector3(1.6, 3.0, 0.9), 0.45, 0.0))
	if spec.trim in [TierDef.HouseTrim.FLOWER_BOXES, TierDef.HouseTrim.BALCONIES, TierDef.HouseTrim.PORTICO]:
		_ornament(extra, spec)
	elif spec.arched:
		_arches(extra, spec)


## Cornija, vergas das janelas e (engenheiros e investidores) a faixa entre os andares, em pedra clara.
static func _ornament(tool: SurfaceTool, spec: Spec) -> void:
	var hall := spec.hall()
	var center := spec.hall_offset()
	var size := hall.size_m()
	if hall.wing != 0 and hall.floors() >= 2:
		# Fase 96: a cornija do alto só no corpo; a da ala no topo dela (a altura do último andar a menos)
		var main_width := size.x - hall.column_m()
		_box(tool, center + hall.main_offset() + Vector3(0.0, hall.height_m - CORNICE_M * 0.5, 0.0),
				Vector3(main_width + CORNICE_OUT_M * 2.0, CORNICE_M, size.y + CORNICE_OUT_M * 2.0), UV_LIGHT_STONE)
		var wing_top := hall.height_m - hall.floor_m()
		_box(tool, center + hall.wing_offset() + Vector3(0.0, wing_top - CORNICE_M * 0.5, 0.0),
				Vector3(hall.column_m() + CORNICE_OUT_M * 2.0, CORNICE_M, size.y + CORNICE_OUT_M * 2.0), UV_LIGHT_STONE)
	else:
		_box(tool, center + Vector3(0.0, hall.height_m - CORNICE_M * 0.5, 0.0),
				Vector3(size.x + CORNICE_OUT_M * 2.0, CORNICE_M, size.y + CORNICE_OUT_M * 2.0), UV_LIGHT_STONE)
	if hall.jetty:
		# Fase 102: a cornija da frente acompanha o andar que avançou (só no corpo, se houver ala)
		var winged := hall.wing != 0 and hall.floors() >= 2
		var top_width := size.x - (hall.column_m() if winged else 0.0)
		var top_x := hall.main_offset().x if winged else 0.0
		_box(tool, center + Vector3(top_x, hall.height_m - CORNICE_M * 0.5, -size.y * 0.5 - JETTY_M * 0.5),
				Vector3(top_width + CORNICE_OUT_M * 2.0, CORNICE_M, JETTY_M + CORNICE_OUT_M * 2.0), UV_LIGHT_STONE)
	if spec.trim != TierDef.HouseTrim.FLOWER_BOXES:
		for level: int in range(1, hall.floors()):
			_box(tool, center + Vector3(0.0, level * hall.floor_m(), 0.0),
					Vector3(size.x + 0.12, BAND_M, size.y + 0.12), UV_LIGHT_STONE)
	for face: int in 4:
		var count := hall.cells.x if face % 2 == 0 else hall.cells.y
		var step := (size.x if face % 2 == 0 else size.y) / count
		for level: int in hall.floors():
			for index: int in count:
				if slot(hall, face, index, level) != &"window":
					continue
				var top := hall.floor_m() * (WINDOW_CENTER + WINDOW_HEIGHT * 0.5) + LINTEL_M
				var at := center + _wall_point(hall, face, index, level) + Vector3(0.0, top, 0.0) \
						+ _face_normal(face) * 0.04
				var width := step * WINDOW_WIDTH * 1.5
				if hall.arched:
					# Fase 99: a cabeça em arco no lugar da verga reta (a pedra de fecho vai no alto do arco)
					_arch_head(tool, center + _wall_point(hall, face, index, level), face, step, hall.floor_m())
				else:
					_box(tool, at, Vector3(width, LINTEL_M, 0.1) if face % 2 == 0 else Vector3(0.1, LINTEL_M, width),
							UV_LIGHT_STONE)
				# o peitoril (Fase 24), mais estreito que a verga e saindo um pouco mais da parede
				var sill := center + _wall_point(hall, face, index, level) + _face_normal(face) * 0.07 \
						+ Vector3(0.0, hall.floor_m() * (WINDOW_CENTER - WINDOW_HEIGHT * 0.5) - SILL_M * 0.5, 0.0)
				var sill_width := step * WINDOW_WIDTH * 1.2
				_box(tool, sill, Vector3(sill_width, SILL_M, 0.16) if face % 2 == 0 else Vector3(0.16, SILL_M, sill_width),
						UV_LIGHT_STONE)
				if spec.trim != TierDef.HouseTrim.FLOWER_BOXES:
					_window_frame(tool, center + _wall_point(hall, face, index, level), face, step, hall.floor_m(), top,
							not hall.arched)


## Guarnição de pedra da janela (Fase 25): as ombreiras dos dois lados do vão, do peitoril à verga, e a pedra
## de fecho no meio da verga. "wall" é o ponto da fachada no meio da célula, no chão do andar; "lintel_y", o
## meio da verga acima dele.
static func _window_frame(tool: SurfaceTool, wall: Vector3, face: int, step: float, floor_m: float,
		lintel_y: float, keystone := true) -> void:
	var along_x := face % 2 == 0
	var lateral := Vector3.RIGHT if along_x else Vector3.BACK
	var normal := _face_normal(face)
	# a verga fica meia altura dela acima do vão: a ombreira sobe até encostar nela
	var height := floor_m * WINDOW_HEIGHT + LINTEL_M * 0.5
	for side: float in [-1.0, 1.0]:
		var at := wall + lateral * side * (step * WINDOW_WIDTH * 0.5 + JAMB_M * 0.5) \
				+ Vector3(0.0, floor_m * WINDOW_CENTER + LINTEL_M * 0.25, 0.0) + normal * 0.04
		_box(tool, at, Vector3(JAMB_M, height, 0.08) if along_x else Vector3(0.08, height, JAMB_M), UV_LIGHT_STONE)
	if not keystone:
		return
	var key := wall + Vector3(0.0, lintel_y - LINTEL_M * 0.5 + KEYSTONE_M * 0.5, 0.0) + normal * 0.07
	_box(tool, key, Vector3(KEYSTONE_WIDTH_M, KEYSTONE_M, 0.14) if along_x
			else Vector3(0.14, KEYSTONE_M, KEYSTONE_WIDTH_M), UV_LIGHT_STONE)


## Fase 99: a cabeça em arco da janela, por cima do vão — o tímpano de vidro em meio círculo, a arquivolta de pedra que
## salta da parede (face, borda de fora e intradorso) e a pedra de fecho no alto. "wall" como no _window_frame.
static func _arch_head(tool: SurfaceTool, wall: Vector3, face: int, step: float, floor_m: float) -> void:
	var lateral := Vector3.RIGHT if face % 2 == 0 else Vector3.BACK
	var normal := _face_normal(face)
	var spring := wall + Vector3(0.0, arch_spring(floor_m), 0.0)
	var inner := arch_radius(step)
	var outer := inner + ARCH_BAND_M
	var proud := normal * ARCH_PROUD_M
	for k: int in ARCH_SEGMENTS:
		var a0 := PI * k / ARCH_SEGMENTS
		var a1 := PI * (k + 1) / ARCH_SEGMENTS
		var r0 := lateral * cos(a0) + Vector3.UP * sin(a0)
		var r1 := lateral * cos(a1) + Vector3.UP * sin(a1)
		_triangle(tool, spring + normal * 0.03, spring + r0 * inner + normal * 0.03, spring + r1 * inner + normal * 0.03,
				normal, UV_GLASS)
		_quad(tool, spring + r0 * inner + proud, spring + r1 * inner + proud, spring + r1 * outer + proud,
				spring + r0 * outer + proud, normal, UV_LIGHT_STONE)
		_quad(tool, spring + r0 * outer, spring + r1 * outer, spring + r1 * outer + proud, spring + r0 * outer + proud,
				r0 + r1, UV_LIGHT_STONE)
		_quad(tool, spring + r0 * inner, spring + r1 * inner, spring + r1 * inner + proud, spring + r0 * inner + proud,
				-(r0 + r1), UV_LIGHT_STONE)
	var key := spring + Vector3.UP * (inner + ARCH_BAND_M * 0.5) + normal * (ARCH_PROUD_M + 0.02)
	_box(tool, key, Vector3(KEYSTONE_WIDTH_M, ARCH_BAND_M * 1.8, 0.1) if face % 2 == 0
			else Vector3(0.1, ARCH_BAND_M * 1.8, KEYSTONE_WIDTH_M), UV_LIGHT_STONE)


## Onde o arco da janela nasce (o alto do vão, acima do chão do andar) e o raio dele (a meia largura do vão).
static func arch_spring(floor_m: float) -> float:
	return floor_m * (WINDOW_CENTER + WINDOW_HEIGHT * 0.5)


static func arch_radius(step: float) -> float:
	return step * WINDOW_WIDTH * 0.5


## Fase 99: as cabeças em arco de todas as janelas do corpo (os serviços de pedra, que não têm o _ornament das casas).
static func _arches(tool: SurfaceTool, spec: Spec) -> void:
	var hall := spec.hall()
	var center := spec.hall_offset()
	var size := hall.size_m()
	for face: int in 4:
		var count := hall.cells.x if face % 2 == 0 else hall.cells.y
		var step := (size.x if face % 2 == 0 else size.y) / count
		for level: int in hall.floors():
			for index: int in count:
				if slot(hall, face, index, level) == &"window":
					_arch_head(tool, center + _wall_point(hall, face, index, level), face, step, hall.floor_m())


## Fase 99: a arcada do mercado na fileira do pátio junto do corpo — um pilar em cada divisa de célula, o arco de volta
## inteira entre eles (o tímpano por cima do arco, a face de trás e o intradorso) e a água de telhas subindo até a parede.
static func arcade_bays(spec: Spec) -> int:
	if spec.silhouette != BuildingDef.Silhouette.STALLS or spec.court_rows < 2:
		return 0
	return spec.cells.x


static func _arcade(tool: SurfaceTool, spec: Spec) -> void:
	var bays := arcade_bays(spec)
	if bays == 0:
		return
	var size := spec.size_m()
	var step := size.x / bays
	var wall_z := spec.hall_offset().z - spec.hall().size_m().y * 0.5
	var front := wall_z - spec.cell_m + 0.15
	var radius := (step - ARCADE_PIER_M) * 0.5
	var top := ARCADE_SPRING_M + radius + 0.35
	var y0 := FOUNDATION_UP_M
	for k: int in bays + 1:
		var x := -size.x * 0.5 + step * k
		x = clampf(x, -size.x * 0.5 + ARCADE_PIER_M * 0.5, size.x * 0.5 - ARCADE_PIER_M * 0.5)
		_box(tool, Vector3(x, (y0 + top) * 0.5, front + ARCADE_THICK_M * 0.5),
				Vector3(ARCADE_PIER_M, top - y0, ARCADE_THICK_M), UV_LIGHT_STONE)
		# o capitel: a pedra mais larga onde o arco nasce
		_box(tool, Vector3(x, ARCADE_SPRING_M, front + ARCADE_THICK_M * 0.5),
				Vector3(ARCADE_PIER_M + 0.12, 0.12, ARCADE_THICK_M + 0.08), UV_LIGHT_STONE)
	for bay: int in bays:
		var middle := -size.x * 0.5 + step * (bay + 0.5)
		for i: int in ARCH_SEGMENTS:
			var a0 := PI * i / ARCH_SEGMENTS
			var a1 := PI * (i + 1) / ARCH_SEGMENTS
			var p0 := Vector3(middle + cos(a0) * radius, ARCADE_SPRING_M + sin(a0) * radius, front)
			var p1 := Vector3(middle + cos(a1) * radius, ARCADE_SPRING_M + sin(a1) * radius, front)
			var back := Vector3(0.0, 0.0, ARCADE_THICK_M)
			# o tímpano: do arco até o alto da arcada, na frente e atrás
			var q0 := Vector3(p0.x, top, front)
			var q1 := Vector3(p1.x, top, front)
			_quad(tool, p0, p1, q1, q0, Vector3.FORWARD, UV_LIGHT_STONE)
			_quad(tool, p0 + back, p1 + back, q1 + back, q0 + back, Vector3.BACK, UV_LIGHT_STONE)
			var down := Vector3(middle, ARCADE_SPRING_M, front) - (p0 + p1) * 0.5
			_quad(tool, p0, p1, p1 + back, p0 + back, down, UV_LIGHT_STONE)
	# a cornija no alto e a água de telhas até a parede do corpo
	_box(tool, Vector3(0.0, top + 0.06, front + ARCADE_THICK_M * 0.5), Vector3(size.x + 0.1, 0.12, ARCADE_THICK_M + 0.14),
			UV_LIGHT_STONE)
	_lean_to(tool, Vector3(0.0, top + ARCADE_ROOF_RISE_M, wall_z), Vector3(0.0, top + 0.12, front - 0.2), size.x + 0.2)


## Frontão: a base de pedra em "height" (o alto da parede) e o triângulo sobre ela, centrados em "front"
## (o ponto da fachada no chão) e de frente para −Z.
static func _pediment(tool: SurfaceTool, front: Vector3, width: float, height: float) -> void:
	var depth := 0.7
	_box(tool, front + Vector3(0.0, height + 0.13, 0.0), Vector3(width, 0.26, depth), UV_LIGHT_STONE)
	var base := height + 0.26
	var half := width * 0.5
	var near := front.z - depth * 0.5
	var far := front.z + depth * 0.5
	var apex_near := Vector3(front.x, base + PEDIMENT_M, near)
	var apex_far := Vector3(front.x, base + PEDIMENT_M, far)
	var left_near := Vector3(front.x - half, base, near)
	var right_near := Vector3(front.x + half, base, near)
	var left_far := Vector3(front.x - half, base, far)
	var right_far := Vector3(front.x + half, base, far)
	_triangle(tool, left_near, right_near, apex_near, Vector3.FORWARD, UV_LIGHT_STONE)
	_triangle(tool, left_far, right_far, apex_far, Vector3.BACK, UV_LIGHT_STONE)
	_quad(tool, left_near, apex_near, apex_far, left_far, Vector3(-1.0, 1.0, 0.0), UV_LIGHT_STONE)
	_quad(tool, right_near, apex_near, apex_far, right_far, Vector3(1.0, 1.0, 0.0), UV_LIGHT_STONE)


## Grade de ferro de a até b (no chão da sacada, em x ou em z): corrimão, travessa de baixo e balaústres. A
## varanda da casa de engenho (Fase 23) usa a mesma, de madeira, mais baixa e de balaústre grosso.
static func _railing(tool: SurfaceTool, a: Vector3, b: Vector3, uv := UV_IRON, height := RAIL_M, bar := 0.03,
		step := RAIL_STEP_M) -> void:
	var along := b - a
	var length := along.length()
	if length < 0.05:
		return
	var along_x := absf(along.x) > absf(along.z)
	var middle := (a + b) * 0.5
	for rail: Vector2 in [Vector2(height, bar * 2.0), Vector2(0.12, bar * 1.3)]:
		_box(tool, middle + Vector3(0.0, rail.x, 0.0),
				Vector3(length, rail.y, rail.y) if along_x else Vector3(rail.y, rail.y, length), uv)
	var count := maxi(1, roundi(length / step))
	for i: int in count + 1:
		var at := a + along * (float(i) / count)
		_box(tool, at + Vector3(0.0, height * 0.5, 0.0), Vector3(bar, height, bar), uv)


## Balaustrada de pedra de a até b (Fase 24, no chão da sacada, em x ou em z): o soco embaixo, os balaústres
## torneados e o corrimão largo, na altura da grade de ferro.
static func _balustrade(tool: SurfaceTool, a: Vector3, b: Vector3) -> void:
	var along := b - a
	var length := along.length()
	if length < 0.05:
		return
	var along_x := absf(along.x) > absf(along.z)
	var middle := (a + b) * 0.5
	for part: Vector3 in [Vector3(PLINTH_M * 0.5, PLINTH_M, 0.2), Vector3(RAIL_M - HANDRAIL_M * 0.5, HANDRAIL_M, 0.22)]:
		_box(tool, middle + Vector3(0.0, part.x, 0.0),
				Vector3(length + part.z - 0.2, part.y, part.z) if along_x else Vector3(part.z, part.y, length + part.z - 0.2),
				UV_LIGHT_STONE)
	var height := RAIL_M - PLINTH_M - HANDRAIL_M
	var count := maxi(1, roundi(length / BALUSTER_STEP_M))
	for i: int in count:
		_baluster(tool, a + along * ((i + 0.5) / count) + Vector3(0.0, PLINTH_M, 0.0), height)


## Balaústre torneado de pé em "foot": o perfil BALUSTER_PROFILE girado em BALUSTER_SIDES faces (sem tampa: o
## soco e o corrimão cobrem as pontas).
static func _baluster(tool: SurfaceTool, foot: Vector3, height: float) -> void:
	for k: int in BALUSTER_PROFILE.size() - 1:
		var low := BALUSTER_PROFILE[k]
		var high := BALUSTER_PROFILE[k + 1]
		for side: int in BALUSTER_SIDES:
			var angle_a := TAU * side / BALUSTER_SIDES
			var angle_b := TAU * (side + 1) / BALUSTER_SIDES
			var dir_a := Vector3(cos(angle_a), 0.0, sin(angle_a))
			var dir_b := Vector3(cos(angle_b), 0.0, sin(angle_b))
			_quad(tool, foot + dir_a * low.x + Vector3.UP * low.y * height, foot + dir_b * low.x + Vector3.UP * low.y * height,
					foot + dir_b * high.x + Vector3.UP * high.y * height, foot + dir_a * high.x + Vector3.UP * high.y * height,
					(dir_a + dir_b).normalized(), UV_LIGHT_STONE)


## Consolo de pedra sob a sacada (Fase 24), de frente para −Z: o topo em "top" (na parede), saindo "out" dela,
## e a face de baixo num quarto de elipse da ponta até a parede, CORBEL_M abaixo.
static func _corbel(tool: SurfaceTool, top: Vector3, out: float) -> void:
	var profile: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(out, 0.0)]
	for k: int in 6:
		var angle := PI * 0.5 * k / 5.0
		profile.append(Vector2(out * cos(angle), -0.08 - (CORBEL_M - 0.08) * sin(angle)))
	var half := CORBEL_WIDTH_M * 0.5
	for x: float in [-half, half]:
		for k: int in range(1, profile.size() - 1):
			_triangle(tool, _corbel_point(top, x, profile[0]), _corbel_point(top, x, profile[k]),
					_corbel_point(top, x, profile[k + 1]), Vector3(signf(x), 0.0, 0.0), UV_LIGHT_STONE)
	for k: int in range(1, profile.size() - 1):
		var a := profile[k]
		var b := profile[k + 1]
		# para fora do centro da elipse
		var away := (a + b) * 0.5 - Vector2(0.0, -0.08)
		_quad(tool, _corbel_point(top, -half, a), _corbel_point(top, half, a), _corbel_point(top, half, b),
				_corbel_point(top, -half, b), Vector3(0.0, away.y, -away.x), UV_LIGHT_STONE)
	_quad(tool, _corbel_point(top, -half, profile[0]), _corbel_point(top, half, profile[0]),
			_corbel_point(top, half, profile[1]), _corbel_point(top, -half, profile[1]), Vector3.UP, UV_LIGHT_STONE)


## Ponto do perfil do consolo (x para fora da parede, y para cima) na largura x.
static func _corbel_point(top: Vector3, x: float, point: Vector2) -> Vector3:
	return top + Vector3(x, point.y, -point.x)


## Peça presa à fachada: o meio da célula na face de fora da parede, saindo out_m dela e up_m acima do
## chão do andar, com a escala da peça (o x da escala é a profundidade: a face de fora da peça, x = 0,5,
## fica a out_m da parede).
static func _face_place(spec: Spec, face: int, index: int, level: int, scale: Vector3, out_m: float,
		up_m: float) -> Transform3D:
	var normal := _face_normal(face)
	var origin := _wall_point(spec, face, index, level) + normal * (out_m - 0.5 * scale.x) + Vector3(0.0, up_m, 0.0)
	return Transform3D(Basis(Vector3.UP, FACE_YAWS[face]) * Basis.from_scale(scale), origin)


## O meio da célula na face de fora da parede, no chão do andar.
static func _wall_point(spec: Spec, face: int, index: int, level: int) -> Vector3:
	var place := _cell_transform(spec, face, index, level)
	return place.origin + _face_normal(face) * place.basis.x.length() * 0.5


## Lanço da cerca na borda da área (não da parede): a célula da fachada, com a altura da cerca.
static func _fence_place(spec: Spec, face: int, index: int) -> Transform3D:
	var place := _cell_transform(spec, face, index, 0)
	place.basis.y = Vector3.UP * FENCE_M / 0.38
	# a borda da área fica INSET_M / 2 além da parede
	return place.translated(_face_normal(face) * INSET_M * 0.5)


## Viga da peça de madeira do kit de a até b (o comprimento da peça é 1 em y).
static func _beam(tool: SurfaceTool, a: Vector3, b: Vector3, thickness: float) -> void:
	var along := b - a
	if along.length_squared() < 1e-6:
		return
	var side := along.cross(Vector3.UP if absf(along.normalized().y) < 0.95 else Vector3.RIGHT).normalized()
	var other := side.cross(along).normalized()
	var k := thickness / BEAM_SIDE
	_append_piece(tool, BEAM, Transform3D(Basis(side * k, along, other * k), a))


## A parte que gira enquanto o prédio produz: pás do moinho, roda d'água ou polia da torre de mina.
class Rotor:
	var mesh: ArrayMesh
	## Onde fica o eixo, no referencial canônico; o giro é em torno do x local.
	var pivot: Transform3D
	var speed: float
	## Fase 73: maior que zero, a parte balança até esse ângulo (rad) para cada lado em vez de girar; speed é a fase.
	var rock: float = 0.0


static var _rotors: Dictionary[String, Rotor] = {}


static func rotor(spec: Spec) -> Rotor:
	if spec.silhouette == BuildingDef.Silhouette.PUMPJACK and spec.court_rows == 0:
		return null
	if spec.silhouette not in [BuildingDef.Silhouette.WINDMILL, BuildingDef.Silhouette.WATERWHEEL,
			BuildingDef.Silhouette.HEADFRAME, BuildingDef.Silhouette.PUMPJACK]:
		return null
	var key := spec.key()
	if _rotors.has(key):
		return _rotors[key]
	if spec.silhouette == BuildingDef.Silhouette.PUMPJACK:
		_rotors[key] = _walking_beam(spec)
		return _rotors[key]
	var size := spec.size_m()
	var result := Rotor.new()
	var piece := ""
	var scale := 1.0
	var center := Vector3.ZERO
	match spec.silhouette:
		BuildingDef.Silhouette.WINDMILL:
			# pás na frente, com o eixo para fora da fachada (o x da peça vira −Z)
			piece = WINDMILL
			scale = minf(size.x * 0.9, spec.height_m * 0.9) / WINDMILL_DIAMETER
			result.pivot = Transform3D(Basis(Vector3.UP, PI * 0.5),
					Vector3(0.0, spec.height_m + spec.roof_m * 0.35, -size.y * 0.5 - 0.6))
			result.speed = WINDMILL_SPEED
		BuildingDef.Silhouette.WATERWHEEL:
			piece = WATERWHEEL
			var diameter := minf(3.4, size.y * 0.6)
			scale = diameter / WATERWHEEL_DIAMETER
			result.pivot = Transform3D(Basis.IDENTITY, Vector3(size.x * 0.5 + 0.85, diameter * 0.38, 0.0))
			result.speed = WATERWHEEL_SPEED
		BuildingDef.Silhouette.HEADFRAME:
			piece = SHEAVE
			scale = 1.6 / SHEAVE_DIAMETER
			center = SHEAVE_CENTER
			result.pivot = Transform3D(Basis.IDENTITY, Vector3(0.0, spec.height_m + spec.roof_m + HEADFRAME_M + 0.4, 0.0))
			result.speed = SHEAVE_SPEED
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_piece(tool, piece, Transform3D(Basis.from_scale(Vector3.ONE * scale), -center * scale))
	result.mesh = tool.commit()
	_rotors[key] = result
	return result


## Fase 73: o balancim do cavalo-de-pau, no referencial do eixo: a viga de madeira, a cabeça de ferro na frente (sobre
## o poço), a travessa atrás e as duas bielas descendo até as manivelas.
static func _walking_beam(spec: Spec) -> Rotor:
	var layout := pumpjack_layout(spec)
	var pivot: Vector3 = layout[&"pivot"]
	var ahead: float = layout[&"ahead"]
	var behind: float = layout[&"behind"]
	var gearbox: Vector3 = layout[&"gearbox"]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(tool, Vector3(0.0, 0.14, (behind - ahead) * 0.5), Vector3(0.26, 0.28, ahead + behind), UV_TIMBER)
	_box(tool, Vector3(0.0, -0.2, -ahead - 0.1), Vector3(0.3, 0.9, 0.36), UV_IRON)
	_box(tool, Vector3(0.0, 0.0, behind), Vector3(0.95, 0.16, 0.22), UV_IRON)
	var drop := pivot.y - gearbox.y
	for side: float in [-1.0, 1.0]:
		_box(tool, Vector3(side * 0.42, -drop * 0.5, behind), Vector3(0.07, drop, 0.07), UV_IRON)
	tool.index()
	tool.generate_tangents()
	var result := Rotor.new()
	result.mesh = tool.commit()
	result.pivot = Transform3D(Basis.IDENTITY, pivot)
	result.speed = PUMPJACK_SPEED
	result.rock = PUMPJACK_ROCK
	return result


## Telhado: as águas com a UV do telhado; as empenas (triângulos das pontas) com a UV da parede.
static func _roof(tool: SurfaceTool, spec: Spec) -> void:
	var size := spec.size_m()
	var top := spec.height_m
	var o := spec.overhang_m
	match spec.roof:
		Roof.FLAT:
			_box(tool, Vector3(0.0, top + spec.roof_m * 0.5, 0.0), Vector3(size.x + 0.2, spec.roof_m, size.y + 0.2), UV_ROOF)
		Roof.HIP:
			var hx := size.x * 0.5 + o
			var hz := size.y * 0.5 + o
			var rx := maxf(hx - hz, 0.0)
			var rz := maxf(hz - hx, 0.0)
			var peak := top + spec.roof_m
			var c00 := Vector3(-hx, top, -hz)
			var c10 := Vector3(hx, top, -hz)
			var c11 := Vector3(hx, top, hz)
			var c01 := Vector3(-hx, top, hz)
			var r00 := Vector3(-rx, peak, -rz)
			var r10 := Vector3(rx, peak, -rz)
			var r11 := Vector3(rx, peak, rz)
			var r01 := Vector3(-rx, peak, rz)
			_quad(tool, c00, c10, r10, r00, Vector3(0, 1, -1), UV_ROOF)
			_quad(tool, c10, c11, r11, r10, Vector3(1, 1, 0), UV_ROOF)
			_quad(tool, c11, c01, r01, r11, Vector3(0, 1, 1), UV_ROOF)
			_quad(tool, c01, c00, r00, r01, Vector3(-1, 1, 0), UV_ROOF)
			_quad(tool, c00, c10, c11, c01, Vector3.DOWN, UV_ROOF)
			# Fase 95: as quinas arredondadas (espigões e cumeeira) e o beiral redondo
			var lift := Vector3(0.0, RIDGE_CAP_M * 0.4, 0.0)
			for pair: Array in [[c00, r00], [c10, r10], [c11, r11], [c01, r01]]:
				var low: Vector3 = pair[0]
				var high: Vector3 = pair[1]
				_rod(tool, low + lift, high + lift, RIDGE_CAP_M * 0.8, RIDGE_SIDES, UV_ROOF_TRIM, true)
			if r00.distance_to(r11) > 0.01:
				_rod(tool, r00 + lift, r11 + lift, RIDGE_CAP_M, RIDGE_SIDES, UV_ROOF_TRIM, true)
			for edge: Array in [[c00, c10], [c10, c11], [c11, c01], [c01, c00]]:
				var start: Vector3 = edge[0]
				var finish: Vector3 = edge[1]
				_rod(tool, start, finish, EAVE_ROLL_M, EAVE_SIDES, UV_ROOF_TRIM)
		_ when spec.vault:
			_vault(tool, spec)
		_:
			var along_x := spec.roof == Roof.GABLE_X
			# a cumeeira corre em u (x ou z) e as águas descem em v
			var hu := (size.x if along_x else size.y) * 0.5
			var hv := (size.y if along_x else size.x) * 0.5
			var eave := top - o * spec.roof_m / hv
			var ridge := top + spec.roof_m
			var down := Vector3(0.0, -ROOF_THICKNESS_M, 0.0)
			for side: float in [-1.0, 1.0]:
				var low_a := _uv_point(along_x, -hu - o, eave, side * (hv + o))
				var low_b := _uv_point(along_x, hu + o, eave, side * (hv + o))
				var high_b := _uv_point(along_x, hu + o, ridge, 0.0)
				var high_a := _uv_point(along_x, -hu - o, ridge, 0.0)
				var away := _uv_point(along_x, 0.0, 0.0, side)
				_quad(tool, low_a, low_b, high_b, high_a, away + Vector3.UP, UV_ROOF)
				_quad(tool, low_a + down, low_b + down, high_b + down, high_a + down, -away - Vector3.UP, UV_ROOF)
				_quad(tool, low_a + down, low_b + down, low_b, low_a, away, UV_ROOF)
				# Fase 95: o beiral redondo (a borda grossa da água, no lugar da quina viva)
				_rod(tool, low_a + down * 0.5, low_b + down * 0.5, EAVE_ROLL_M, EAVE_SIDES, UV_ROOF_TRIM)
			# Fase 95: a capa redonda da cumeeira, de ponta a ponta
			var cap_lift := Vector3(0.0, RIDGE_CAP_M * 0.35, 0.0)
			_rod(tool, _uv_point(along_x, -hu - o, ridge, 0.0) + cap_lift, _uv_point(along_x, hu + o, ridge, 0.0) + cap_lift,
					RIDGE_CAP_M, RIDGE_SIDES, UV_ROOF_TRIM, true)
			for end: float in [-1.0, 1.0]:
				var left := _uv_point(along_x, end * hu, top, -hv)
				var right := _uv_point(along_x, end * hu, top, hv)
				var apex := _uv_point(along_x, end * hu, ridge, 0.0)
				_triangle(tool, left, right, apex, _uv_point(along_x, end, 0.0, 0.0), UV_WALL)
				# a ponta da água por fora da empena
				var side_a := _uv_point(along_x, end * (hu + o), eave, -(hv + o))
				var side_b := _uv_point(along_x, end * (hu + o), eave, hv + o)
				var tip := _uv_point(along_x, end * (hu + o), ridge, 0.0)
				_quad(tool, side_a, side_a + down, tip + down, tip, _uv_point(along_x, end, 0.0, 0.0), UV_ROOF)
				_quad(tool, side_b, side_b + down, tip + down, tip, _uv_point(along_x, end, 0.0, 0.0), UV_ROOF)


## Fase 98: a altura da abóbada em v (de -largura a +largura, com o beiral): o arco de círculo que passa pelo beiral dos
## dois lados e pelo alto. Devolve [altura, normal no plano (v, y)].
static func vault_profile(spec: Spec, v: float) -> Array:
	var size := spec.size_m()
	var hv := (size.y if spec.roof == Roof.GABLE_X else size.x) * 0.5
	var width := hv + spec.overhang_m
	var rise := spec.roof_m * VAULT_RISE
	var eave := spec.height_m - spec.overhang_m * 0.3
	var h := spec.height_m + rise - eave
	var radius := (width * width + h * h) / (2.0 * h)
	var center_y := spec.height_m + rise - radius
	var y := center_y + sqrt(maxf(radius * radius - v * v, 0.0))
	return [y, Vector2(v, y - center_y) / radius]


## A abóbada: as faixas do arco com as normais dele (sai lisa), a espessura por baixo e na borda, o beiral redondo e as
## empenas em arco nas duas pontas.
static func _vault(tool: SurfaceTool, spec: Spec) -> void:
	var size := spec.size_m()
	var along_x := spec.roof == Roof.GABLE_X
	var hu := (size.x if along_x else size.y) * 0.5
	var hv := (size.y if along_x else size.x) * 0.5
	var o := spec.overhang_m
	var top := spec.height_m
	var width := hv + o
	var down := Vector3(0.0, -ROOF_THICKNESS_M, 0.0)
	for i: int in VAULT_SEGMENTS:
		var v0 := -width + 2.0 * width * i / VAULT_SEGMENTS
		var v1 := -width + 2.0 * width * (i + 1) / VAULT_SEGMENTS
		var p0 := vault_profile(spec, v0)
		var p1 := vault_profile(spec, v1)
		var y0: float = p0[0]
		var y1: float = p1[0]
		var m0: Vector2 = p0[1]
		var m1: Vector2 = p1[1]
		var n0 := _uv_point(along_x, 0.0, m0.y, m0.x)
		var n1 := _uv_point(along_x, 0.0, m1.y, m1.x)
		var a := _uv_point(along_x, -hu - o, y0, v0)
		var b := _uv_point(along_x, hu + o, y0, v0)
		var c := _uv_point(along_x, hu + o, y1, v1)
		var d := _uv_point(along_x, -hu - o, y1, v1)
		_smooth_quad(tool, [a, b, c, d], [n0, n0, n1, n1], UV_ROOF)
		_quad(tool, a + down, b + down, c + down, d + down, -(n0 + n1), UV_ROOF)
		# a borda da faixa nas duas pontas
		for end: float in [-1.0, 1.0]:
			var e0 := _uv_point(along_x, end * (hu + o), y0, v0)
			var e1 := _uv_point(along_x, end * (hu + o), y1, v1)
			_quad(tool, e0, e1, e1 + down, e0 + down, _uv_point(along_x, end, 0.0, 0.0), UV_ROOF)
		# a empena: do alto da parede até o arco, só por cima da parede
		var w0 := clampf(v0, -hv, hv)
		var w1 := clampf(v1, -hv, hv)
		if w1 - w0 > 0.001:
			var r0: float = vault_profile(spec, w0)[0]
			var r1: float = vault_profile(spec, w1)[0]
			var g0 := maxf(r0, top)
			var g1 := maxf(r1, top)
			for end: float in [-1.0, 1.0]:
				var outward := _uv_point(along_x, end, 0.0, 0.0)
				_quad(tool, _uv_point(along_x, end * hu, top, w0), _uv_point(along_x, end * hu, top, w1),
						_uv_point(along_x, end * hu, g1, w1), _uv_point(along_x, end * hu, g0, w0), outward, UV_WALL)
	# a borda grossa no beiral e o beiral redondo
	for side: float in [-1.0, 1.0]:
		var eave: float = vault_profile(spec, side * width)[0]
		var low_a := _uv_point(along_x, -hu - o, eave, side * width)
		var low_b := _uv_point(along_x, hu + o, eave, side * width)
		_quad(tool, low_a + down, low_b + down, low_b, low_a, _uv_point(along_x, 0.0, 0.0, side), UV_ROOF)
		_rod(tool, low_a + down * 0.5, low_b + down * 0.5, EAVE_ROLL_M, EAVE_SIDES, UV_ROOF_TRIM)


## Quadrilátero com uma normal por vértice (a, b, c, d em volta), virado para a média delas.
static func _smooth_quad(tool: SurfaceTool, points: Array[Vector3], normals: Array[Vector3], uv: Vector2) -> void:
	var outward := normals[0] + normals[1] + normals[2] + normals[3]
	var order: Array[int] = [0, 1, 2, 0, 2, 3]
	if (points[1] - points[0]).cross(points[2] - points[0]).dot(outward) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for index: int in order:
		tool.set_normal(normals[index].normalized())
		tool.set_uv(uv)
		tool.add_vertex(points[index])


## Fase 98: os tonéis do pátio — cada um [meio da base, raio do bojo, altura], de cada lado do caminho da porta.
static func vat_layout(spec: Spec) -> Array[Array]:
	var vats: Array[Array] = []
	if spec.court_rows == 0 or spec.silhouette != BuildingDef.Silhouette.VATS:
		return vats
	var size := spec.size_m()
	var depth := spec.court_rows * spec.cell_m
	var z := -size.y * 0.5 + depth * 0.5
	var step := size.x / spec.cells.x
	var door_x := -size.x * 0.5 + step * (spec.door_index + 0.5)
	var radius := minf(depth * 0.34, 0.75)
	var height := minf(spec.height_m * 0.36, VAT_MAX_M)
	for span: Vector2 in [Vector2(-size.x * 0.5 + 0.2, door_x - 0.9), Vector2(door_x + 0.9, size.x * 0.5 - 0.2)]:
		var room := span.y - span.x
		var count := mini(VATS_PER_SIDE, floori(room / (radius * 2.0 + 0.25)))
		for k: int in count:
			var x := span.x + room * (k + 0.5) / count
			vats.append([Vector3(x, FOUNDATION_UP_M, z), radius, height])
	return vats


## Os tonéis: aduelas com o bojo (sólido de revolução), três arcos de ferro, a tampa e o cano de cobre até a parede.
static func _vats(tool: SurfaceTool, spec: Spec) -> void:
	var wall_z := spec.hall_offset().z - spec.hall().size_m().y * 0.5
	for vat: Array in vat_layout(spec):
		var base: Vector3 = vat[0]
		var radius: float = vat[1]
		var height: float = vat[2]
		var profile: Array[Vector2] = []
		for step: int in 7:
			var t := step / 6.0
			profile.append(Vector2(_vat_radius(radius, t), height * t))
		_turned(tool, base, profile, VAT_SIDES, UV_TIMBER)
		_turned(tool, base, [Vector2(radius / VAT_BULGE, height), Vector2(0.0, height + 0.05)], VAT_SIDES, UV_TIMBER)
		for t: float in [0.12, 0.5, 0.88]:
			var ring := _vat_radius(radius, t) + 0.025
			_turned(tool, base, [Vector2(ring, height * t - 0.05), Vector2(ring, height * t + 0.05)], VAT_SIDES, UV_IRON)
		_bar(tool, base + Vector3(0.0, height * 0.8, radius * 0.8), Vector3(base.x, base.y + height * 0.8, wall_z), 0.1,
				UV_COPPER)


## O raio do tonel a "t" da altura (0 embaixo, 1 em cima): a parábola do bojo.
static func _vat_radius(radius: float, t: float) -> float:
	var narrow := radius / VAT_BULGE
	return narrow + (radius - narrow) * (1.0 - pow(2.0 * t - 1.0, 2.0))


## Lucarnas (Fase 39) na água da frente do telhado de duas águas (na de cumeeira em z a frente é a empena: vão na água
## de +x). Caixa de parede enterrada no telhado, com a frente de pé a LUCARNE_AT da meia largura da água, telhadinho de
## duas águas, empena, vidro e caixilho.
static func lucarne_fits(roof_m: float) -> bool:
	return roof_m * LUCARNE_AT >= LUCARNE_H + LUCARNE_PEAK_M + 0.1


static func _lucarnes(tool: SurfaceTool, spec: Spec) -> void:
	if spec.lucarnes <= 0 or spec.roof not in [Roof.GABLE_X, Roof.GABLE_Z] or not lucarne_fits(spec.roof_m):
		return
	var size := spec.size_m()
	var along_x := spec.roof == Roof.GABLE_X
	var hu := (size.x if along_x else size.y) * 0.5
	var hv := (size.y if along_x else size.x) * 0.5
	var ridge := spec.height_m + spec.roof_m
	var side := -1.0 if along_x else 1.0
	var slope := spec.roof_m / hv
	var front := hv * LUCARNE_AT
	var base := ridge - slope * front
	var crown := base + LUCARNE_H
	var back := (ridge - crown) / slope
	var half := LUCARNE_W * 0.5
	var out := _uv_point(along_x, 0.0, 0.0, side)
	for k: int in spec.lucarnes:
		var u := ((k + 0.5) / spec.lucarnes * 2.0 - 1.0) * hu * 0.5
		var bottom := base - 0.4
		_box(tool, _uv_point(along_x, u, (crown + bottom) * 0.5, side * (front + back) * 0.5),
				_uv_point(along_x, LUCARNE_W, crown - bottom, front - back).abs(), UV_WALL)
		var peak := crown + LUCARNE_PEAK_M
		var eave := half + 0.08
		for s: float in [-1.0, 1.0]:
			_quad(tool, _uv_point(along_x, u + s * eave, crown - 0.03, side * (front + 0.1)),
					_uv_point(along_x, u + s * eave, crown - 0.03, side * back),
					_uv_point(along_x, u, peak, side * back), _uv_point(along_x, u, peak, side * (front + 0.1)),
					_uv_point(along_x, s, 1.0, 0.0), UV_ROOF)
		_triangle(tool, _uv_point(along_x, u - half, crown, side * front), _uv_point(along_x, u + half, crown, side * front),
				_uv_point(along_x, u, peak - 0.04, side * front), out, UV_WALL)
		var glass_v := side * (front + 0.01)
		var low := base + 0.1
		var high := low + LUCARNE_H * 0.62
		var glass_u := LUCARNE_W * 0.28
		_quad(tool, _uv_point(along_x, u - glass_u, low, glass_v), _uv_point(along_x, u + glass_u, low, glass_v),
				_uv_point(along_x, u + glass_u, high, glass_v), _uv_point(along_x, u - glass_u, high, glass_v), out, UV_GLASS)
		var bar_v := side * (front + 0.02)
		_quad(tool, _uv_point(along_x, u - MULLION_M * 0.5, low, bar_v), _uv_point(along_x, u + MULLION_M * 0.5, low, bar_v),
				_uv_point(along_x, u + MULLION_M * 0.5, high, bar_v), _uv_point(along_x, u - MULLION_M * 0.5, high, bar_v), out,
				UV_TIMBER)


## Vidro e caixilho em cada janela (Fase 39): o kit só tem o vão, que de dia lia como buraco preto. O vidro fica na
## espessura da parede e a cruz de madeira logo à frente dele.
static func _glazing(tool: SurfaceTool, spec: Spec, offset: Transform3D) -> void:
	var half_w := WINDOW_WIDTH * 0.52
	var half_h := WINDOW_HEIGHT * 0.52
	var middle := WINDOW_CENTER
	for face: int in 4:
		var count := spec.cells.x if face % 2 == 0 else spec.cells.y
		for level: int in spec.floors():
			for index: int in count:
				if slot(spec, face, index, level) != &"window":
					continue
				var place := offset * _cell_transform(spec, face, index, level)
				var out := place.basis.x.normalized()
				_quad(tool, place * Vector3(GLASS_X, middle - half_h, -half_w), place * Vector3(GLASS_X, middle - half_h, half_w),
						place * Vector3(GLASS_X, middle + half_h, half_w), place * Vector3(GLASS_X, middle + half_h, -half_w), out,
						UV_GLASS)
				var bar_z := MULLION_M * 0.5 / place.basis.z.length()
				var bar_y := MULLION_M * 0.5 / place.basis.y.length()
				_quad(tool, place * Vector3(MULLION_X, middle - half_h, -bar_z), place * Vector3(MULLION_X, middle - half_h, bar_z),
						place * Vector3(MULLION_X, middle + half_h, bar_z), place * Vector3(MULLION_X, middle + half_h, -bar_z), out,
						UV_TIMBER)
				_quad(tool, place * Vector3(MULLION_X, middle - bar_y, -half_w), place * Vector3(MULLION_X, middle - bar_y, half_w),
						place * Vector3(MULLION_X, middle + bar_y, half_w), place * Vector3(MULLION_X, middle + bar_y, -half_w), out,
						UV_TIMBER)


## Plinto e degraus do prédio no barranco (Fase 39), no referencial canônico: a pedra desce do piso até "depth" abaixo
## dele, um pouco maior que o alicerce do kit (cobre-o); o pátio da frente fica no nível do piso, como um terraço. Se a
## porta fica "drop" acima do chão da frente, os degraus descem da soleira até ele. Malha em cache pela forma e pelas
## medidas arredondadas a 5 cm.
static var _plinths: Dictionary[String, ArrayMesh] = {}


static func plinth(spec: Spec, depth: float, drop: float) -> ArrayMesh:
	var depth_q := snappedf(maxf(depth, FOUNDATION_DOWN_M), 0.05)
	var steps := steps_for(drop)
	var drop_q := snappedf(drop, 0.05) if steps > 0 else 0.0
	var key := "%s|%.2f|%.2f" % [spec.key(), depth_q, drop_q]
	if _plinths.has(key):
		return _plinths[key]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var size := spec.size_m() + Vector2(PLINTH_OUT_M, PLINTH_OUT_M) * 2.0
	var hall := spec.hall()
	var hall_size := hall.size_m() + Vector2(PLINTH_OUT_M, PLINTH_OUT_M) * 2.0
	var hall_center := spec.hall_offset()
	var lip := FOUNDATION_UP_M + 0.01
	_box(tool, hall_center + Vector3(0.0, (lip - depth_q) * 0.5, 0.0), Vector3(hall_size.x, lip + depth_q, hall_size.y), UV_STONE)
	var front := -size.y * 0.5
	if spec.court_rows > 0:
		# o pátio é terraço de pedra no nível do piso, com o muro de arrimo em volta
		var court_back := hall_center.z - hall_size.y * 0.5
		_box(tool, Vector3(0.0, -depth_q * 0.5, (front + court_back) * 0.5), Vector3(size.x, depth_q, court_back - front), UV_STONE)
	if steps > 0:
		var door_x := door_position(spec).x
		var face := front if spec.court_rows > 0 else hall_center.z - hall_size.y * 0.5
		var top := lip if spec.court_rows == 0 else 0.0
		var rise := (drop_q + top) / (steps + 1)
		var width := minf(spec.size_m().x / spec.cells.x * 0.8, 1.4)
		for k: int in range(1, steps + 1):
			var step_top := top - rise * k
			var bottom := -drop_q - 0.25
			_box(tool, Vector3(door_x, (step_top + bottom) * 0.5, face - STEP_TREAD_M * (k - 0.5)),
					Vector3(width, step_top - bottom, STEP_TREAD_M), UV_STONE)
	tool.index()
	tool.generate_tangents()
	var mesh := tool.commit()
	_plinths[key] = mesh
	return mesh


## Quantos degraus pede a porta "drop" acima do chão da frente (até MAX_STEPS; o resto o chão engole).
static func steps_for(drop: float) -> int:
	if drop + FOUNDATION_UP_M < STEP_RISE_M * 1.6:
		return 0
	return clampi(ceili((drop + FOUNDATION_UP_M) / STEP_RISE_M) - 1, 1, MAX_STEPS)


static func _uv_point(along_x: bool, u: float, y: float, v: float) -> Vector3:
	return Vector3(u, y, v) if along_x else Vector3(v, y, u)


## Quadrilátero plano a, b, c, d (em volta), virado para "outward".
static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3, uv: Vector2) -> void:
	_triangle(tool, a, b, c, outward, uv)
	_triangle(tool, a, c, d, outward, uv)


## Triângulo virado para "outward" (o sentido dos vértices é acertado aqui). Triângulo sem área
## (a ponta do telhado de quatro águas quadrado) é pulado.
static func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3, uv: Vector2) -> void:
	var cross := (b - a).cross(c - a)
	if cross.length_squared() < 1e-8:
		return
	var normal := cross.normalized()
	var points: Array[Vector3] = [a, b, c]
	# o Godot desenha como frente o sentido horário visto de fora
	if normal.dot(outward) > 0.0:
		points = [a, c, b]
	else:
		normal = -normal
	for point: Vector3 in points:
		tool.set_normal(normal)
		tool.set_uv(uv)
		tool.add_vertex(point)


## Fase 95: haste redonda de from até to (raio radius, sides faces) com a normal de cada vértice para fora do eixo (o
## sombreado sai liso, redondo). Com half, só a metade de cima (a capa da cumeeira, que assenta nas duas águas).
static func _rod(tool: SurfaceTool, from: Vector3, to: Vector3, radius: float, sides: int, uv: Vector2, half: bool = false) -> void:
	var axis := to - from
	if axis.length_squared() < 1e-6:
		return
	var direction := axis.normalized()
	var side := direction.cross(Vector3.UP)
	if side.length_squared() < 1e-6:
		side = direction.cross(Vector3.RIGHT)
	side = side.normalized()
	var up := side.cross(direction).normalized()
	if up.y < 0.0:
		up = -up
		side = -side
	var arc := PI if half else TAU
	var normals: Array[Vector3] = []
	for i: int in sides + 1:
		var angle := arc * i / sides
		normals.append(side * cos(angle) + up * sin(angle))
	for i: int in sides:
		var n0 := normals[i]
		var n1 := normals[i + 1]
		var quad: Array[Vector3] = [from + n0 * radius, to + n0 * radius, to + n1 * radius, from + n1 * radius]
		var quad_normals: Array[Vector3] = [n0, n0, n1, n1]
		# o sentido dos vértices pela normal média (a face para fora do eixo)
		var outward := (n0 + n1).normalized()
		var order: Array[int] = [0, 1, 2, 0, 2, 3]
		if (quad[1] - quad[0]).cross(quad[2] - quad[0]).dot(outward) > 0.0:
			order = [0, 2, 1, 0, 3, 2]
		for index: int in order:
			tool.set_normal(quad_normals[index])
			tool.set_uv(uv)
			tool.add_vertex(quad[index])


## Fase 97: sólido de revolução em volta do eixo vertical que passa por center: o perfil em (raio, altura) de baixo para
## cima, em sides faces, com a normal de cada vértice pela média dos trechos vizinhos (a cúpula sai lisa).
static func _turned(tool: SurfaceTool, center: Vector3, profile: Array[Vector2], sides: int, uv: Vector2) -> void:
	var normals: Array[Vector2] = []
	for i: int in profile.size():
		var sum := Vector2.ZERO
		if i > 0:
			sum += _profile_normal(profile[i - 1], profile[i])
		if i < profile.size() - 1:
			sum += _profile_normal(profile[i], profile[i + 1])
		normals.append(sum.normalized())
	for i: int in profile.size() - 1:
		var low := profile[i]
		var high := profile[i + 1]
		if low.x < 0.0001 and high.x < 0.0001:
			continue
		for k: int in sides:
			var a0 := TAU * k / sides
			var a1 := TAU * (k + 1) / sides
			var quad: Array[Vector3] = [_ring_point(center, low, a0), _ring_point(center, low, a1),
					_ring_point(center, high, a1), _ring_point(center, high, a0)]
			var quad_normals: Array[Vector3] = [_ring_normal(normals[i], a0), _ring_normal(normals[i], a1),
					_ring_normal(normals[i + 1], a1), _ring_normal(normals[i + 1], a0)]
			var outward := (quad_normals[0] + quad_normals[2]).normalized()
			var order: Array[int] = [0, 1, 2, 0, 2, 3]
			if (quad[1] - quad[0]).cross(quad[2] - quad[0]).dot(outward) > 0.0:
				order = [0, 2, 1, 0, 3, 2]
			for index: int in order:
				tool.set_normal(quad_normals[index])
				tool.set_uv(uv)
				tool.add_vertex(quad[index])


## A normal de um trecho do perfil (raio, altura), para fora: subindo reto ela aponta para fora; fechando, para cima.
static func _profile_normal(a: Vector2, b: Vector2) -> Vector2:
	var along := b - a
	return Vector2(along.y, -along.x).normalized() if along.length_squared() > 1e-8 else Vector2(1.0, 0.0)


static func _ring_point(center: Vector3, point: Vector2, angle: float) -> Vector3:
	return center + Vector3(cos(angle) * point.x, point.y, sin(angle) * point.x)


static func _ring_normal(normal: Vector2, angle: float) -> Vector3:
	return Vector3(cos(angle) * normal.x, normal.y, sin(angle) * normal.x)


## Fase 97: a cúpula de cobre no meio do telhado de quatro águas: o tambor de pedra saindo do telhado até DRUM_M acima da
## cumeeira, com a cornija e os vãos escuros, a meia esfera de cobre (DOME_RISE do raio) e o lanternim com o remate.
static func _dome(tool: SurfaceTool, spec: Spec) -> void:
	var size := spec.size_m()
	var radius := minf(minf(size.x, size.y) * DOME_SHARE, DOME_MAX_M)
	var center := Vector3(0.0, 0.0, 0.0)
	var peak := spec.height_m + spec.roof_m
	var foot := spec.height_m + spec.roof_m * 0.4
	var drum_top := peak + DRUM_M
	_turned(tool, center, [Vector2(radius, foot), Vector2(radius, drum_top)], DOME_SIDES, UV_LIGHT_STONE)
	# a cornija do tambor e os vãos (o vidro escuro do kit)
	_turned(tool, center, [Vector2(radius, drum_top - 0.18), Vector2(radius + 0.16, drum_top - 0.1),
			Vector2(radius + 0.16, drum_top), Vector2(radius * 0.98, drum_top + 0.02)], DOME_SIDES, UV_LIGHT_STONE)
	for k: int in 8:
		var angle := TAU * (k + 0.5) / 8.0
		var at := Vector3(cos(angle) * (radius + 0.02), (peak + drum_top) * 0.5, sin(angle) * (radius + 0.02))
		var window := SurfaceTool.new()
		window.begin(Mesh.PRIMITIVE_TRIANGLES)
		_box(window, Vector3.ZERO, Vector3(0.06, DRUM_M * 0.45, radius * 0.35), UV_GLASS)
		tool.append_from(window.commit(), 0, Transform3D(Basis(Vector3.UP, -angle), at))
	# a meia esfera de cobre
	var profile: Array[Vector2] = []
	for step: int in 9:
		var angle := PI * 0.5 * step / 8.0
		profile.append(Vector2(cos(angle) * radius, drum_top + sin(angle) * radius * DOME_RISE))
	_turned(tool, center, profile, DOME_SIDES, UV_COPPER)
	# o lanternim: tambor pequeno de pedra, a capinha de cobre e o remate
	var crown := drum_top + radius * DOME_RISE
	var small := radius * 0.2
	_turned(tool, center, [Vector2(small, crown - 0.1), Vector2(small, crown + small * 1.6)], 8, UV_LIGHT_STONE)
	var cap: Array[Vector2] = []
	for step: int in 5:
		var angle := PI * 0.5 * step / 4.0
		cap.append(Vector2(cos(angle) * small * 1.15, crown + small * 1.6 + sin(angle) * small))
	_turned(tool, center, cap, 8, UV_COPPER)
	_rod(tool, Vector3(0.0, crown + small * 2.5, 0.0), Vector3(0.0, crown + small * 2.5 + 0.9, 0.0), 0.05, 6, UV_COPPER)


## Fase 97: o torreão redondo no canto da frente de +X (no referencial do corpo), em balanço do primeiro andar: o cone de
## pedra que o segura, o fuste na parede do prédio subindo TURRET_ABOVE de um andar acima do beiral, os vãos escuros por
## andar virados para a rua e o telhado cônico com o remate. O meio fica na linha da fachada: metade sai para a frente.
static func turret_center(spec: Spec) -> Vector3:
	var size := spec.size_m()
	return Vector3(size.x * 0.5 - TURRET_R, 0.0, -size.y * 0.5)


static func _turret(tool: SurfaceTool, spec: Spec, offset: Transform3D) -> void:
	var part := SurfaceTool.new()
	part.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := turret_center(spec)
	var bottom := spec.floor_m()
	var top := spec.height_m + spec.floor_m() * TURRET_ABOVE
	_turned(part, center, [Vector2(0.12, bottom - TURRET_CORBEL_M), Vector2(TURRET_R, bottom)], TURRET_SIDES, UV_LIGHT_STONE)
	_turned(part, center, [Vector2(TURRET_R, bottom), Vector2(TURRET_R, top)], TURRET_SIDES, UV_WALL)
	# a cornija no alto do fuste
	_turned(part, center, [Vector2(TURRET_R, top - 0.2), Vector2(TURRET_R + 0.12, top - 0.1), Vector2(TURRET_R + 0.12, top)],
			TURRET_SIDES, UV_LIGHT_STONE)
	# um vão por andar em cada um dos três lados que dão para fora (a frente, o canto e o lado)
	for level: int in range(1, spec.floors() + 1):
		var y := level * spec.floor_m() + spec.floor_m() * 0.5
		if y > top - 0.4:
			break
		for angle: float in [-PI * 0.5, -PI * 0.25, 0.0]:
			var at := center + Vector3(cos(angle) * (TURRET_R + 0.02), y, sin(angle) * (TURRET_R + 0.02))
			var window := SurfaceTool.new()
			window.begin(Mesh.PRIMITIVE_TRIANGLES)
			_box(window, Vector3.ZERO, Vector3(0.06, spec.floor_m() * 0.45, 0.42), UV_GLASS)
			part.append_from(window.commit(), 0, Transform3D(Basis(Vector3.UP, -angle), at))
	# o telhado cônico (na célula do acabamento: liso, sem as fileiras de telha) e o remate
	_turned(part, center, [Vector2(TURRET_R + 0.22, top), Vector2(0.0, top + TURRET_ROOF_M)], TURRET_SIDES, UV_ROOF_TRIM)
	_rod(part, center + Vector3(0.0, top + TURRET_ROOF_M - 0.1, 0.0), center + Vector3(0.0, top + TURRET_ROOF_M + 0.7, 0.0),
			0.05, 6, UV_IRON)
	tool.append_from(part.commit(), 0, offset)


static func _box(tool: SurfaceTool, center: Vector3, size: Vector3, uv: Vector2) -> void:
	var h := size * 0.5
	for axis: int in 3:
		for sign_value: float in [-1.0, 1.0]:
			var normal := Vector3.ZERO
			normal[axis] = sign_value
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = 1.0
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = 1.0
			var face := center + normal * h[axis]
			var du := u * h[(axis + 1) % 3]
			var dv := v * h[(axis + 2) % 3]
			_quad(tool, face - du - dv, face + du - dv, face + du + dv, face - du + dv, normal, uv)
