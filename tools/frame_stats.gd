class_name FrameStats
extends RefCounted
## Fase 32: o resumo de uma lista de tempos de quadro (ms), do jeito que se mede fluidez: média, percentis (p50, p95,
## p99), pior quadro e os lows de 1% e 0,1% — a média dos quadros mais lentos daquela fração, em FPS (é o número que
## o PresentMon e o FrameView dão, e o que se compara entre presets e drivers).


## {count, average_ms, average_fps, p50_ms, p95_ms, p99_ms, worst_ms, low_1_fps, low_01_fps}; lista vazia dá zeros.
static func summary(frames_ms: PackedFloat64Array) -> Dictionary:
	var result := {"count": frames_ms.size(), "average_ms": 0.0, "average_fps": 0.0, "p50_ms": 0.0, "p95_ms": 0.0,
			"p99_ms": 0.0, "worst_ms": 0.0, "low_1_fps": 0.0, "low_01_fps": 0.0}
	if frames_ms.is_empty():
		return result
	var sorted := frames_ms.duplicate()
	sorted.sort()
	var total := 0.0
	for ms: float in sorted:
		total += ms
	var average := total / sorted.size()
	result.average_ms = average
	result.average_fps = 1000.0 / average if average > 0.0 else 0.0
	result.p50_ms = percentile(sorted, 0.50)
	result.p95_ms = percentile(sorted, 0.95)
	result.p99_ms = percentile(sorted, 0.99)
	result.worst_ms = sorted[sorted.size() - 1]
	result.low_1_fps = _low(sorted, 0.01)
	result.low_01_fps = _low(sorted, 0.001)
	return result


## O valor no percentil (0 a 1) de uma lista já em ordem crescente, pelo vizinho mais perto.
static func percentile(sorted: PackedFloat64Array, fraction: float) -> float:
	if sorted.is_empty():
		return 0.0
	return sorted[clampi(ceili(fraction * sorted.size()) - 1, 0, sorted.size() - 1)]


## A média dos quadros mais lentos (pelo menos um) da fração, em FPS.
static func _low(sorted: PackedFloat64Array, fraction: float) -> float:
	var count := maxi(1, floori(sorted.size() * fraction))
	var total := 0.0
	for index: int in range(sorted.size() - count, sorted.size()):
		total += sorted[index]
	var average := total / count
	return 1000.0 / average if average > 0.0 else 0.0
