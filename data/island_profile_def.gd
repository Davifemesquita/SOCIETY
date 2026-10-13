class_name IslandProfileDef
extends Resource
## Perfil de uma ilha (seção 7): as culturas que ela aceita, as jazidas, a floresta, os rios e o
## relevo. O gerador do arquipélago lê daqui; nada disso é número no código.

@export var id: StringName
## Bens de fazenda que a ilha deixa plantar (ex.: &"wheat").
@export var fertilities: Array[StringName] = []
## Bens das jazidas da ilha (o que a mina extrai: &"coal", &"iron_ore").
@export var deposits: Array[StringName] = []
## Manchas de cada jazida (cada mancha cabe uma mina com folga).
@export var deposit_spots: int = 2
## Fração da terra coberta de floresta (0 a 1).
@export var forest_coverage: float = 0.3
## Rios (braços de mar que entram pela planície do litoral).
@export var rivers: int = 1
## Altura dos morros: 1 é o normal; ilha rochosa > 1, planície < 1.
@export var relief: float = 1.0
## Ilha plana de antes da Fase 5 (saves antigos e testes): sem relevo, sem água por dentro, e
## árvores, jazidas e rios valem como presentes; o litoral é a borda.
@export var flat: bool = false
