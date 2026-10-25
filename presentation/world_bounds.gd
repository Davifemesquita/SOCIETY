class_name WorldBounds
extends RefCounted
## Fase 32: a caixa fixa de tudo o que pode ser desenhado no arquipélago (a região da principal, as vizinhas onde o
## gerador põe as outras ilhas e as regiões tropicais), para qualquer semente. Vai no custom_aabb dos MultiMeshes que
## mudam a cada quadro (carroças, gaivotas, pilhas): sem ela, cada atualização percorre as instâncias na CPU para
## refazer a caixa. Também nos pedestres, que andam no shader e não têm caixa própria.

const FLOOR_M := -20.0
const CEILING_M := 80.0


static func of(config: GameConfig) -> AABB:
	var region := config.terrain_region_m
	var low := Vector2(-region, -region)
	var high := Vector2(2.0 * region, 2.0 * region)
	for tropical: Vector2i in config.tropical_regions:
		low = low.min(Vector2(tropical) * region)
		high = high.max(Vector2(tropical + Vector2i.ONE) * region)
	return AABB(Vector3(low.x, FLOOR_M, low.y), Vector3(high.x - low.x, CEILING_M - FLOOR_M, high.y - low.y))
