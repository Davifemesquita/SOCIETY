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
		# sem montar um Array por célula: era o grosso do tempo do recálculo. Fase 29: cada vizinha é lida uma vez
		var x := index % width
		var has_left := x > 0
		var has_right := x < width - 1
		var up := index - width
		var down := index + width
		var road_left := has_left and roads[index - 1] != 0
		var road_right := has_right and roads[index + 1] != 0
		var road_up := up >= 0 and roads[up] != 0
		var road_down := down < count and roads[down] != 0
		var next := index - 1
		if road_left and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
		next = index + 1
		if road_right and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
		if road_up and distance[up] == -1:
			distance[up] = next_distance
			owner[up] = from
			queue.append(up)
		if road_down and distance[down] == -1:
			distance[down] = next_distance
			owner[down] = from
			queue.append(down)
		# diagonal pura (Fase 17): a célula do canto, sem estrada nas duas vizinhas em comum. Fase 29: numa rua reta
		# (ou num cruzamento) toda dupla de vizinhas perpendiculares tem estrada e nenhum canto liga: pula os quatro
		var free_up := not road_up and up >= 0
		var free_down := not road_down and down < count
		if not ((free_up or free_down) and (not road_left or not road_right)):
			continue
		next = up - 1
		if has_left and free_up and not road_left and roads[next] != 0 and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
		next = up + 1
		if has_right and free_up and not road_right and roads[next] != 0 and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
		next = down - 1
		if has_left and free_down and not road_left and roads[next] != 0 and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
		next = down + 1
		if has_right and free_down and not road_right and roads[next] != 0 and distance[next] == -1:
			distance[next] = next_distance
			owner[next] = from
			queue.append(next)
