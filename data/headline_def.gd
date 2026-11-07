class_name HeadlineDef
extends Resource
## Manchete do jornal (Fase 63): a cada edição sai uma, sorteada pela semente entre as de notícia; a de propaganda o
## jogador compra para trocar a da edição. Vale até a próxima edição e soma happiness pontos ao alvo de felicidade das
## casas de todas as ilhas (negativo tira). Título HEADLINE_<ID>, texto HEADLINE_<ID>_DESC.

@export var id: StringName
## Pontos de felicidade no alvo das casas (o arquipélago todo).
@export var happiness: float = 0.0
## Peso no sorteio entre as manchetes de notícia liberadas (a de propaganda não entra no sorteio).
@export var weight: int = 1
## Manchete comprada pelo jogador, não sorteada.
@export var propaganda: bool = false
## Só sai (ou se compra) depois de tantos marcos de população.
@export var after_milestone: int = 0


func title_key() -> String:
	return "HEADLINE_" + String(id).to_upper()


func description_key() -> String:
	return title_key() + "_DESC"
