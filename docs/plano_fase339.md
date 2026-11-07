# Plano da Fase 339 — Mourões na estrada

**Estado: feita em 07/11/2026**, a quinta e última do roteiro `docs/plano_fases_335_339.md` (estrada no jeito do Anno). Ao longo da
estrada do campo o Anno tem cercas e mourões de vez em quando; a nossa corria nua.

## O plano

- **Arquivos**: `presentation/road_fence_view.gd` (nova), `ui/screens/game_screen.gd`, o teste novo, `AGENTS.md` e o roteiro.
- **Risco**: cerca dentro da vila ou atravessando a vizinha; cerca torta na ladeira.
- **Como testar**: o teste novo (com estradas postas na grade) e a captura da estrada de campo (`tools/capture_phase237.tscn`).

## O que entrou

- **`RoadFenceView`** (`GameScreen.road_fence_view`), no molde do marco de légua (Fase 237): nas células de estrada de terra de trecho
  reto (`MilestoneView._straight_axis`) fora das vilas (`SignpostView._near_town`), a estrada se divide em blocos de `BLOCK_CELLS` (4)
  células ao longo dela; o bloco cercado (`FENCED_SHARE`, 35%, pelo `FireflyView.cell_hash` do bloco e da linha) ganha um lanço por
  célula na beira do lado sorteado, a `OFFSET_M` (0,9 m) do meio, se a vizinha desse lado estiver livre.
- **O lanço** (`fence_mesh`): um mourão em cada ponta e duas travessas de pau roliço, na madeira gasta, esticado e inclinado com o chão
  ao longo da estrada; sem cerca onde o chão sobe mais de `MAX_RISE_M` (0,8 m) no lanço (inclinada, parecia caída).
- **De quebra, no cascalho da Fase 336**: cada pedra com o seu tamanho e o tom um pouco mais escuro (iguais e claras, pareciam
  bolinhas brancas de perto).

## Medida

Benchmark (o fim do roteiro, com o cascalho, a rua larga, o capim da beira e as cercas): 63,4 FPS, GPU 14,7 ms, carregar 6.956 ms (a
334 na mesma sessão: 63,4 FPS, GPU 14,7 ms). Nada a mais no quadro do trajeto, que passa pela vila.

## Como testar

- `tests/world/test_phase339_road_fences.gd`: nas estradas de campo postas na grade, cercas em blocos (menos lanços que células), na
  beira livre da célula da estrada, com o lanço de 2 m pouco inclinado; nada na rua calçada nem na ilha plana; o lanço de 2 m.
- Captura: `tools/capture_phase237.tscn -- <pasta>` (`marco_0_longe.png` mostra a cerca na estrada de campo); em
  `F:\ferramentas\capturas\fase339\depois2\`.
