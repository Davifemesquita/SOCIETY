# Plano da Fase 76 — Fumaça do trem

**Estado: feita em 28/10/2026, a pedido do dono** ("pode ir para a proxima"; proposta deixada de fora na Fase 71). Só
apresentação: a simulação, o save e as assinaturas não mudam.

## O que entrou

- **A locomotiva solta fumaça pela chaminé** (`TrainView._chimney_smoke`, um `GPUParticles3D` filho da locomotiva na boca
  da chaminé, `TrainView.chimney_top`): a mesma fumaça cinza das fábricas (`SmokeView._process_material` e `_draw_mesh`,
  tipo SMOKE, agora estáticas), solta no mundo (`local_coords` desligado), então a baforada fica para trás quando o trem
  anda.
- **Forte andando, fraca na ponta**: `amount_ratio` 1,0 com o trem andando e 0,4 esperando no poço ou na usina
  (`TrainView.moving_at`, pelo mesmo vaivém do `head_at`); nada com o trem parado (poço ou usina pausados) ou com o jogo
  pausado.
- **Deita no vento** como a das fábricas (`SmokeView.drift` com o vento do `WeatherView`, num material de processo de
  todos os trens) e **segue o nível gráfico** (`GraphicsQuality.add_effect`: 24 partículas vezes a fração do nível, até
  450 m vezes a escala de distância; sem partículas no nível, sem fumaça).
- Conserto achado no teste: a `WeatherView` criada sem `setup` deixava a chuva órfã; agora ela sai junto.

## Números

- Benchmark: o mundo do benchmark não tem trilho nem trem; neutra (`docs/benchmark.md`). O material da fumaça é o mesmo
  das chaminés (nenhuma pipeline nova).

## Como testar

- `tests/presentation/test_phase76_train_smoke.gd`: a fumaça na boca da chaminé, filha da locomotiva e solta no mundo;
  fraca esperando, cheia andando, nada com o jogo pausado ou o poço pausado; `moving_at` igual ao vaivém; deitando no
  vento; o nível gráfico mudando as partículas e o alcance, e sem fumaça no nível sem partículas.
- Capturas: `tools/capture_phase76.tscn -- <pasta>` (no mundo plano, com o jogo andando a 1× e a câmera seguindo a
  locomotiva: esperando no poço, andando e de longe; em `F:\ferramentas\capturas\fase76`).
- **Correção (28/10/2026, depois do commit da fase):** a primeira versão destas notas dizia que a primeira fumaça da
  partida levava 7 a 10 s para aparecer por causa da compilação do shader. Estava errado. O Godot só simula as
  partículas que estão na tela, e o roteiro levava a câmera até o trem só 5 quadros antes de cada foto. Medido à parte:
  uma fumaça posta na tela aparece em 0,5 s, e pôr as partículas no `WarmUp` não mudou as pipelines compiladas na
  primeira baforada (2 com e 2 sem) nem o pior quadro (33 ms nos dois). A mudança no `WarmUp` foi desfeita sem commit, e
  o roteiro agora segue o trem com a câmera.

## Fica de fora (proposta à espera do dono)

- Apito e barulho do trem, vapor branco na partida, faísca à noite, o trem levar a carga de verdade e mais trens.
