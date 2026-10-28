class_name BuildingDef
extends Resource
## Definição de um tipo de prédio: forma, função, custo e desbloqueio.

## PIER (Fase 6) e DECORATION (Fase 16) entram no fim: o número do tipo fica nos .tres.
enum Kind { RESIDENCE, PRODUCTION, SERVICE, MODULE, WAREHOUSE, PIER, DECORATION }
## Requisitos de terreno. Até a Fase 5 a ilha de teste cumpre todos, menos o litoral,
## que já é a borda da ilha. OIL (Fase 70): cobrir um campo de petróleo (IslandGrid.oil_spots), também na ilha plana.
enum Terrain { NONE, COAST, TREES, DEPOSIT, RIVER_OR_COAST, OIL }
## O que sai da chaminé enquanto o prédio produz (Fase 9): nada, vapor claro, fumaça ou fumaça
## pesada (com fuligem no chão em volta).
enum Smoke { NONE, STEAM, SMOKE, HEAVY }
## O que o serviço protege (riscos, seção 8): nada, incêndio (quartel de bombeiros) ou doença
## (hospital).
enum Hazard { NONE, FIRE, DISEASE }
## O que se reconhece de longe no prédio de modelo (Fase 13): moinho de vento, roda d'água, torre de
## mina, bancas na frente, guindaste, lanternim no telhado ou bandeiras na fachada; e, desde a Fase 18,
## o campanário com o sino e, desde a Fase 23, a varanda da casa de engenho (no fim: o número fica nos .tres).
enum Silhouette { NONE, WINDMILL, WATERWHEEL, HEADFRAME, STALLS, CRANE, CLERESTORY, BANNERS, BELFRY, VERANDA }
## A planta que a fazenda põe nos campos dela (Fase 14): cereal, tubérculo, lúpulo na estaca, parreira,
## cana, arbusto (café) ou folha larga (tabaco).
enum Crop { NONE, GRAIN, TUBER, HOPS, VINE, CANE, BUSH, BROADLEAF }

@export var id: StringName
## Chave de tradução do nome.
@export var name_key: String
@export var kind: Kind = Kind.PRODUCTION
## Largura (x) e profundidade (y) em células, com a frente voltada para −Z sem rotação.
@export var size: Vector2i = Vector2i(3, 3)
@export var height_m: float = 4.0
## Cor do placeholder enquanto não há modelo (na Fase 9, o tom que pinta a textura).
@export var color: Color = Color(0.6, 0.6, 0.6)
## Textura das paredes (Fase 9): camada de assets/materials/walls_* (BuildingMaterials.Wall).
@export var wall_material: int = 0
@export var smoke: Smoke = Smoke.NONE
## Som de trabalho enquanto produz (Fase 10): &"wood", &"metal" ou vazio (sem som).
@export var work_sound: StringName
@export var silhouette: Silhouette = Silhouette.NONE
@export var crop: Crop = Crop.NONE

@export_group("Custo")
@export var cost_money: int = 0
@export var cost_materials: Dictionary[StringName, int] = {}
## Manutenção em moedas por minuto enquanto o prédio existe (metade se pausado).
@export var upkeep_per_min: int = 0

@export_group("Desbloqueio")
## Classe e número mínimo de moradores dela para liberar o prédio. Vazio = livre.
@export var unlock_tier: StringName
@export var unlock_residents: int = 0

@export_group("Produção")
## Classe que trabalha aqui e quantos trabalhadores o prédio pede.
@export var workforce_tier: StringName
@export var workers: int = 0
## Cada ciclo consome 1 t de cada entrada e gera 1 t da saída.
@export var inputs: Array[StringName] = []
@export var output: StringName
@export var cycle_s: float = 30.0
## Módulos (campos, pastos) exigidos no raio da fazenda.
@export var module_id: StringName
@export var modules_required: int = 0
@export var module_radius_cells: int = 5
@export var terrain: Terrain = Terrain.NONE
## Cultura que precisa constar nas fertilidades da ilha.
@export var fertility: StringName
## Jazida exigida debaixo do prédio inteiro (minas: &"coal", &"iron_ore"); vazio = nenhuma.
@export var deposit: StringName

@export_group("Armazém")
## O entreposto: primeiro prédio da ilha, no litoral; funciona como armazém e porto.
@export var is_trading_post: bool = false
## Níveis do armazém ou entreposto (rampas, estoque, custo do upgrade). Vazio = não melhora.
@export var levels: Array[BuildingLevelDef] = []

@export_group("Serviço")
## Raio do serviço medido por estrada; 0 usa GameConfig.service_radius_cells.
@export var service_radius_cells: int = 0
## Prefeitura (Fase 66): a política escolhida vale para os prédios a até este raio (em células, pela distância entre
## os lotes). 0 = não é prefeitura.
@export var policy_radius_cells: int = 0
## Zoológico e museu (Fase 67): quantas peças cabem e de que tipo (ExhibitDef.Kind). 0 vagas = não expõe nada.
@export var exhibit_slots: int = 0
@export var exhibit_kind: int = 0

@export_group("Eletricidade")
## Usina (Fase 11): queima as entradas sem gerar bem e, enquanto produz, eletrifica as fábricas
## (prédio de produção com entrada) a até este raio, em células. 0 = não é usina.
@export var power_radius_cells: int = 0

@export_group("Estaleiro")
## Estaleiro: produção sem bem, que constrói estes navios por encomenda (um por vez). Vazio = não é.
@export var shipyard_ships: Array[StringName] = []

@export_group("Riscos")
## Multiplica a chance de incêndio do prédio (casa e produção); 0 = não pega fogo.
@export var fire_risk: float = 1.0
## Serviço que protege contra um risco no raio dele (bombeiros: casas e produção; hospital: casas).
@export var protects: Hazard = Hazard.NONE

@export_group("Beleza")
## Decoração (Fase 16): quanto ela embeleza as casas a até beauty_radius_cells (cai linear com a distância;
## a soma por casa vai até 1). 0 = não embeleza.
@export var beauty: float = 0.0
@export var beauty_radius_cells: int = 0

@export_group("Poluição")
@export var pollution_radius_cells: int = 0
## Fração da penalidade máxima de felicidade que a poluição deste prédio aplica.
@export var pollution_strength: float = 0.0


## Decoração (Fase 16): não produz nem atende necessidade; embeleza as casas em volta e não pede estrada.
func is_decoration() -> bool:
	return kind == Kind.DECORATION


func is_production() -> bool:
	return kind == Kind.PRODUCTION


## Prefeitura (Fase 66): escolhe uma política que vale em volta dela.
func is_town_hall() -> bool:
	return policy_radius_cells > 0


## Zoológico ou museu (Fase 67): tem vagas para peças de coleção.
func is_exhibit_hall() -> bool:
	return exhibit_slots > 0


func is_warehouse() -> bool:
	return kind == Kind.WAREHOUSE


## Píer (Fase 6): uma vaga a mais no porto da ilha, ligado por estrada ao entreposto.
func is_pier() -> bool:
	return kind == Kind.PIER


## Onde atraca navio: o entreposto e os píeres.
func is_berth() -> bool:
	return is_trading_post or kind == Kind.PIER


## Estaleiro: produção sem bem que constrói navio por encomenda.
func is_shipyard() -> bool:
	return is_production() and not shipyard_ships.is_empty()


## Usina elétrica (Fase 11): produção sem bem de saída.
func is_power_plant() -> bool:
	return is_production() and power_radius_cells > 0


## Fábrica que a usina acelera: produção com entrada. Extração, fazenda e a própria usina, não.
func is_electrifiable() -> bool:
	return is_production() and not inputs.is_empty() and power_radius_cells <= 0


## Pode pegar fogo: casa e prédio de produção com risco acima de zero.
func can_burn() -> bool:
	return fire_risk > 0.0 and (kind == Kind.RESIDENCE or kind == Kind.PRODUCTION)


func level(index: int) -> BuildingLevelDef:
	return levels[clampi(index, 0, levels.size() - 1)] if not levels.is_empty() else null


## t/min gerado a 100% de produtividade.
func output_per_min() -> float:
	return 60.0 / cycle_s if is_production() and output != &"" else 0.0
