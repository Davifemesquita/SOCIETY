class_name WarehouseField
extends RefCounted
## Distância de cada célula de estrada até o armazém mais próximo e qual é ele: uma busca em
## largura que sai de todos os armazéns ao mesmo tempo (a diagonal pura, Fase 17, conta um passo). Responde "este prédio tem armazém a
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
		# vizinhos na ordem esquerda, direita, cima, baixo (o desempate do dono depende dela),
		# sem montar um Array por célula: era o grosso do tempo do recálculo
		var x := index % width
		var next := index - 1
		if x > 0 and roads[next] != 0 and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
		next = index + 1
		if x < width - 1 and roads[next] != 0 and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
		next = index - width
		if next >= 0 and roads[next] != 0 and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
		next = index + width
		if next < count and roads[next] != 0 and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
		# diagonal pura (Fase 17): a célula do canto, sem estrada nas duas vizinhas em comum
		var road_left := x > 0 and roads[index - 1] != 0
		var road_right := x < width - 1 and roads[index + 1] != 0
		var road_up := index - width >= 0 and roads[index - width] != 0
		var road_down := index + width < count and roads[index + width] != 0
		next = index - width - 1
		if x > 0 and next >= 0 and next < count and not road_left and not road_up and roads[next] != 0 and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
		next = index - width + 1
		if x < width - 1 and next >= 0 and next < count and not road_right and not road_up and roads[next] != 0 and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
		next = index + width - 1
		if x > 0 and next >= 0 and next < count and not road_left and not road_down and roads[next] != 0 and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
		next = index + width + 1
		if x < width - 1 and next >= 0 and next < count and not road_right and not road_down and roads[next] != 0 and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
