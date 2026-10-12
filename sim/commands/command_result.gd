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


static func refused(why: StringName) -> CommandResult:
	var result := CommandResult.new()
	result.reason = why
	return result


func ok() -> bool:
	return reason == &""
