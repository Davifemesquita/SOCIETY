# Plano da Fase 78 — Tanques da usina a petróleo

**Estado: feita em 28/10/2026, a pedido do dono** ("pode seguir"; proposta deixada de fora nas Fases 70 e 73: "modelo da
usina a petróleo"). Só apresentação: a simulação, o save, o lote e as assinaturas não mudam.

## O que entrou

- **Silhueta nova** `BuildingDef.Silhouette.TANKFARM` (no fim do enum: os números dos `.tres` não mudam), na
  `oil_power_station.tres`. Até aqui a usina a petróleo tinha a mesma forma da usina a carvão (o galpão alto com o
  lanternim); agora as duas se distinguem de longe.
- **O pátio dos tanques** (`BuildingKit._tankfarm`, as duas fileiras da frente, `TANKFARM_ROWS`): dois tanques verticais
  de 12 faces (`_tank`, `tank_layout`: raio pelo pátio, até 5,5 m de costado) com o teto em cone baixo, dois anéis de
  ferro, a escada na frente e o tubo num suporte até a parede do galpão; um dique baixo de pedra em volta, com a
  passagem até a porta no meio da frente. O galpão fica nas fileiras de trás, com telhado de duas águas.
- A usina a carvão continua com o lanternim. A foto da usina a petróleo no menu foi refeita.

## Achado

- O `SurfaceTool` principal do `_build` recebe as peças do kit já indexadas; vértice solto posto nele depois fica fora
  do índice e não aparece (a primeira captura mostrou só os anéis e as escadas). Por isso os tanques vão no `extra`,
  como as outras peças geradas no código.

## Números

- Benchmark: o mundo do benchmark não tem usina a petróleo; neutra (`docs/benchmark.md`). O material é o do kit
  (nenhuma pipeline nova).

## Como testar

- `tests/presentation/test_phase78_tank_farm.gd`: a usina a petróleo com o pátio e a de carvão sem; os tanques dentro
  do pátio e do lote, o caminho da porta livre, mais altos que o dique e mais baixos que o galpão, iguais e simétricos;
  sem pátio, sem tanques.
- Capturas: `tools/capture_phase78.tscn -- <pasta>` (no mundo plano, a usina a petróleo ao lado da de carvão, de perto e
  de longe; em `F:\ferramentas\capturas\fase78`).

## Fica de fora (proposta à espera do dono)

- O tanque ao lado do poço, o nível do óleo nos tanques pelo estoque, o barulho da bomba e da usina.
