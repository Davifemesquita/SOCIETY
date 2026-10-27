class_name CoastRefine
extends RefCounted
## Fase 55: a malha do terreno mais fina só na linha d'água. Os quadrados da grade (2 m) que a costa atravessa (um canto
## abaixo do mar e outro acima) viram uma subgrade de N × N, com as alturas por Catmull-Rom nas alturas vizinhas: a costa
## sai curva em vez de reta de canto a canto. Os cantos da grade não mudam (a simulação continua mandando neles); o resto
## fica dentro das alturas dos cantos que pesam no ponto e a até max_m da interpolação linear.
## Toda conta parte das coordenadas absolutas da subgrade: o ponto na borda comum a dois quadrados sai igual dos dois
## lados (sem fresta). Na borda com um quadrado que não se divide, a altura é a linear (a mesma reta do vizinho).


## O quadrado de canto (x, y) atravessa a linha d'água.
static func crosses(heights: PackedFloat32Array, side: int, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= side - 1 or y >= side - 1:
		return false
	var a := heights[y * side + x]
	var b := heights[y * side + x + 1]
	var c := heights[(y + 1) * side + x]
	var d := heights[(y + 1) * side + x + 1]
	return minf(minf(a, b), minf(c, d)) < 0.0 and maxf(maxf(a, b), maxf(c, d)) > 0.0


## Altura no ponto (sx, sy) da subgrade de n por célula. linear: a borda encosta num quadrado que não se divide.
static func height(heights: PackedFloat32Array, side: int, sx: int, sy: int, n: int, max_m: float, linear: bool) -> float:
	var ix := mini(sx / n, side - 1)
	var iy := mini(sy / n, side - 1)
	var fx := float(sx - ix * n) / n
	var fy := float(sy - iy * n) / n
	var ix1 := mini(ix + 1, side - 1)
	var iy1 := mini(iy + 1, side - 1)
	var h00 := heights[iy * side + ix]
	var h10 := heights[iy * side + ix1]
	var h01 := heights[iy1 * side + ix]
	var h11 := heights[iy1 * side + ix1]
	var bilinear := lerpf(lerpf(h00, h10, fx), lerpf(h01, h11, fx), fy)
	if linear or (fx == 0.0 and fy == 0.0):
		return bilinear
	var wx := _weights(fx)
	var wy := _weights(fy)
	var value := 0.0
	for j: int in 4:
		if wy[j] == 0.0:
			continue
		var row := clampi(iy - 1 + j, 0, side - 1) * side
		var sum := 0.0
		for i: int in 4:
			sum += wx[i] * heights[row + clampi(ix - 1 + i, 0, side - 1)]
		value += wy[j] * sum
	# só os cantos que pesam no ponto limitam (na borda, os dois dela: os dois quadrados vizinhos dão o mesmo valor)
	var low := INF
	var high := -INF
	for corner: Vector3 in [Vector3(h00, 1.0 - fx, 1.0 - fy), Vector3(h10, fx, 1.0 - fy), Vector3(h01, 1.0 - fx, fy),
			Vector3(h11, fx, fy)]:
		if corner.y > 0.0 and corner.z > 0.0:
			low = minf(low, corner.x)
			high = maxf(high, corner.x)
	return clampf(clampf(value, low, high), bilinear - max_m, bilinear + max_m)


## Normal de um canto da grade pelas alturas vizinhas.
static func corner_normal(heights: PackedFloat32Array, side: int, gx: int, gy: int, spacing: float) -> Vector3:
	var left := heights[gy * side + maxi(gx - 1, 0)]
	var right := heights[gy * side + mini(gx + 1, side - 1)]
	var up := heights[maxi(gy - 1, 0) * side + gx]
	var down := heights[mini(gy + 1, side - 1) * side + gx]
	return Vector3(left - right, 2.0 * spacing, up - down).normalized()


## Pesos de Catmull-Rom dos quatro vizinhos (−1, 0, 1, 2) na fração t; em t = 0 só o do meio pesa, exato.
static func _weights(t: float) -> PackedFloat32Array:
	if t == 0.0:
		return PackedFloat32Array([0.0, 1.0, 0.0, 0.0])
	var t2 := t * t
	var t3 := t2 * t
	return PackedFloat32Array([
		0.5 * (-t3 + 2.0 * t2 - t),
		0.5 * (3.0 * t3 - 5.0 * t2 + 2.0),
		0.5 * (-3.0 * t3 + 4.0 * t2 + t),
		0.5 * (t3 - t2),
	])
