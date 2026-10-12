class_name WarehouseField
extends RefCounted
## Distância de cada célula de estrada até o armazém mais próximo e qual é ele: uma busca em
## largura que sai de todos os armazéns ao mesmo tempo. Responde "este prédio tem armazém a
## até 40 células de estrada?" sem calcular uma rota por prédio. Anda por índice da grade (sem
## Vector2i), porque roda a cada estrada nova sobre a ilha inteira.

## Por célula: passos até o armazém mais próximo (-1 = nenhum alcançável).
var distance: PackedInt32Array = PackedInt32Array()
## Por célula: id do armazém mais próximo (0 = nenhum).
var owner: PackedInt32Array = PackedInt32Array()


## sources: pares [índice da célula de estrada, id do armazém], em ordem de id.
func _init(grid: IslandGrid, sources: Array[Vector2i]) -> void:
	distance.resize(grid.roads.size())
	distance.fill(-1)
	owner.resize(grid.roads.size())
	var queue := PackedInt32Array()
	for source: Vector2i in sources:
		if distance[source.x] == -1:
			distance[source.x] = 0
			owner[source.x] = source.y
			queue.append(source.x)
	var roads := grid.roads
	var width := grid.size.x
	var count := roads.size()
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var next_distance := distance[index] + 1
		var from := owner[index]
		var x := index % width
		for next: int in [index - 1 if x > 0 else -1, index + 1 if x < width - 1 else -1, index - width, index + width]:
			if next >= 0 and next < count and roads[next] != 0 and distance[next] == -1:
				distance[next] = next_distance
				owner[next] = from
				queue.append(next)
