class_name GoodDef
extends Resource
## Um bem: o que se produz, se guarda no estoque da ilha e se consome.

## Peça da carga: nenhuma (o porco anda), saco, barril, caixote, toras e barras, ou monte.
enum Pile { NONE, SACK, BARREL, CRATE, LOGS, HEAP }

@export var id: StringName
@export var name_key: String
## Preço base por tonelada; o comerciante (Fase 6) varia em torno dele.
@export var base_price: int = 10
## Consumo de cada morador que tem este bem como opção de necessidade, em t/min.
@export var consumption_per_resident_t_min: float = 0.0
## Cor do placeholder enquanto não há ícone.
@export var color: Color = Color(0.6, 0.6, 0.6)
## Forma da carga (Fase 13): a peça da pilha diante do prédio e da carga da carroça (CargoKit).
@export var pile: Pile = Pile.SACK
## Ferrovia (Fase 70): o bem só anda por trilho, do poço à usina (petróleo): carroça não leva e ele não vai ao estoque.
@export var rail_only: bool = false
