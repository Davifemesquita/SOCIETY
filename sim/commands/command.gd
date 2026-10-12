class_name Command
extends RefCounted
## Ação do jogador validada pela simulação. Valida tudo antes de mudar qualquer coisa:
## comando recusado deixa o mundo intacto.


func execute(_world: WorldState, _catalog: BuildingCatalog) -> CommandResult:
	return CommandResult.refused(&"REASON_NOT_IMPLEMENTED")
