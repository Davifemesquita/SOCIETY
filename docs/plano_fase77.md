# Plano da Fase 77 — Chão e bebedouro no cercado

**Estado: feita em 28/10/2026, a pedido do dono** ("pode seguir"; proposta deixada de fora nas Fases 74 e 75). Só
apresentação: a simulação, o save, o lote, as vagas e as assinaturas não mudam.

## Antes desta fase: a ideia descartada

A primeira escolha para a Fase 77 era pôr as partículas (a fumaça das chaminés e do trem, e o fogo) no rascunho da
primeira vez (`WarmUp`, Fase 32), por um achado da Fase 76 de que a primeira fumaça levava 7 a 10 s para aparecer.
Medindo, o achado estava errado: o Godot só simula as partículas que estão na tela, e a captura levava a câmera até o
trem 5 quadros antes da foto. Uma fumaça posta na tela aparece em 0,5 s, e com as partículas no `WarmUp` a primeira
baforada compilou as mesmas 2 pipelines e teve o mesmo pior quadro (33 ms). A mudança foi desfeita sem commit; o plano
e a captura da Fase 76 foram corrigidos (commit `2e323f0`).

## O que entrou

- **O chão do bicho em cada cercado ocupado** (`ExhibitModels.pen_dressing`, com cor por vértice, o mesmo material dos
  bichos): areia da savana para o elefante, o leão e o tigre, capim seco para a girafa e as zebras, capim verde para as
  araras; em ladrilhos de tom variado, 3 cm acima do pátio. Feito uma vez por bicho e tamanho de cercado.
- **O bebedouro**: um cocho de madeira com a água rente à borda, encostado na cerca de trás, do lado direito
  (`trough_center`, `trough_rect`).
- **O bicho desvia do bebedouro** (`PenWalk.blocked`): toda pose é conferida também contra o retângulo do bebedouro
  (teste dos eixos separadores entre o corpo girado e o retângulo, com a folga da cerca), e o caminho reto pelo corpo
  varrido (`path_clear`: o fecho dos cantos de saída e de chegada, com o eixo paralelo ao caminho). Os tamanhos da Fase 75
  não mudam (o bebedouro não tira uma faixa do cercado).
- O museu não ganha nada disso.
- **Conserto achado na captura**: a vaga do cercado (`BuildingKit.exhibit_spots`) ficava em y = 0, mas o piso do pátio
  fica em `FOUNDATION_UP_M` (0,15 m) — desde a Fase 74 as patas dos bichos e o pé das cercas ficavam dentro do piso, e o
  chão novo sumia embaixo dele. A vaga agora fica em cima do piso; a cerca, os bichos, o chão e o bebedouro sobem juntos.

## Números

- Benchmark: o mundo do benchmark não tem zoológico; neutra (`docs/benchmark.md`). Uma malha a mais por cercado
  ocupado, com o material que já existia (nenhuma pipeline nova).

## Como testar

- `tests/presentation/test_phase77_pen_floor.gd`: o chão e o bebedouro dentro da cerca, o chão virado para cima na
  altura certa, a areia diferente do capim, a malha guardada; cinco minutos de passeio de cada bicho sem tocar o
  bebedouro; o teste dos eixos (corpo em cima bate, longe não, caminho que cruza bate); no `BuildingView`, o chão nos
  cercados ocupados, o passeio com o bebedouro e nada no museu.
- Capturas: `tools/capture_phase77.tscn -- <pasta>` (no mundo plano, o zoológico cheio de perto em três momentos do
  passeio e de longe; em `F:\ferramentas\capturas\fase77`).

## Fica de fora (proposta à espera do dono)

- Bicho indo beber no bebedouro, pedras e uma árvore no cercado dos grandes, lago no do elefante, feno para as zebras.
