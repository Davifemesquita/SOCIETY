class_name BuildingDef
extends Resource
## Definição de um tipo de prédio: forma, função, custo e desbloqueio.

## PIER (Fase 6) entra no fim: o número do tipo fica nos .tres.
enum Kind { RESIDENCE, PRODUCTION, SERVICE, MODULE, WAREHOUSE, PIER }
## Requisitos de terreno. Até a Fase 5 a ilha de teste cumpre todos, menos o litoral,
## que já é a borda da ilha.
enum Terrain { NONE, COAST, TREES, DEPOSIT, RIVER_OR_COAST }
## O que sai da chaminé enquanto o prédio produz (Fase 9): nada, vapor claro, fumaça ou fumaça
## pesada (com fuligem no chão em volta).
enum Smoke { NONE, STEAM, SMOKE, HEAVY }
## O que o serviço protege (riscos, seção 8): nada, incêndio (quartel de bombeiros) ou doença
## (hospital).
enum Hazard { NONE, FIRE, DISEASE }

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

@export_group("Eletricidade")
## Usina (Fase 11): queima as entradas sem gerar bem e, enquanto produz, eletrifica as fábricas
## (prédio de produção com entrada) a até este raio, em células. 0 = não é usina.
@export var power_radius_cells: int = 0

@export_group("Riscos")
## Multiplica a chance de incêndio do prédio (casa e produção); 0 = não pega fogo.
@export var fire_risk: float = 1.0
## Serviço que protege contra um risco no raio dele (bombeiros: casas e produção; hospital: casas).
@export var protects: Hazard = Hazard.NONE

@export_group("Poluição")
@export var pollution_radius_cells: int = 0
## Fração da penalidade máxima de felicidade que a poluição deste prédio aplica.
@export var pollution_strength: float = 0.0


func is_production() -> bool:
	return kind == Kind.PRODUCTION


func is_warehouse() -> bool:
	return kind == Kind.WAREHOUSE


## Píer (Fase 6): uma vaga a mais no porto da ilha, ligado por estrada ao entreposto.
func is_pier() -> bool:
	return kind == Kind.PIER


## Onde atraca navio: o entreposto e os píeres.
func is_berth() -> bool:
	return is_trading_post or kind == Kind.PIER


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
