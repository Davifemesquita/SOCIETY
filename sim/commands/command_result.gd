class_name CommandResult
extends RefCounted
## O que um comando fez: o motivo da recusa (vazio se deu certo) e o que mudou no mundo.

var reason: StringName = &""
var island_id: int = 0
var placed: Array[int] = []
var removed: Array[int] = []
## Prédios que mudaram de estado sem sair do lugar (pausa, bloqueio de upgrade).
var changed: Array[int] = []
var roads_changed: bool = false
## Área onde a construção derrubou árvores (vazia se nenhuma).
var trees_cleared := Rect2i()
## Navios e rotas (Fase 6): mudou a frota (inclusive carga) ou as rotas; id do que foi criado.
var ships_changed: bool = false
var routes_changed: bool = false
var created_id: int = 0
## Um entreposto foi fundado numa ilha a partir de um navio.
var colonized: bool = false


static func refused(why: StringName) -> CommandResult:
	var result := CommandResult.new()
	result.reason = why
	return result


func ok() -> bool:
	return reason == &""
