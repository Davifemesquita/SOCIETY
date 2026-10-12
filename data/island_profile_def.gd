class_name IslandProfileDef
extends Resource
## Perfil de uma ilha: as culturas que ela aceita. Jazidas, florestas e rios entram na
## Fase 5, com o terreno.

@export var id: StringName
## Bens de fazenda que a ilha deixa plantar (ex.: &"wheat").
@export var fertilities: Array[StringName] = []
