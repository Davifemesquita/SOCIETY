# Plano da Fase 123 — Borrifo nas falésias

**Estado: feita em 30/10/2026**, quarta do roteiro `docs/plano_fases_120_124.md` (fios, riacho e mansarda, olhando o Anno
do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`RockView.spray_sites`): os pontos onde o mar bate na rocha são as rochas dos rochedos e das falésias da Fase
  56 (todas encostam no mar), guardadas com o raio delas ao montar o mundo.
- **Quando** (`SurfSprayView`): a cada `delay` (entre `INTERVAL_S`, pelo número do jato), com a câmera perto do chão (até
  `CAMERA_M` do ponto que ela olha), um dos `NEAREST` pontos mais perto dela, até `RANGE_M` (`pick`), ganha um jato na beira
  da rocha do lado do mar (`spot`: dos `SIDES` lados, o de chão mais baixo; do lado da terra o jato subia na grama).
- **O jato**: partículas `one_shot` de espuma branca (a textura da fumaça) que sobem, se abrem e caem, desenhadas depois da
  água (`ShipView.ABOVE_WATER`); `POOL` jatos reaproveitados, menos partículas nos níveis gráficos baixos
  (`GraphicsQuality.add_effect`), parados na pausa (o `speed_scale` segue o relógio).

## Como testar

- `tests/world/test_phase123_surf_spray.gd`: os pontos vêm das rochas do mar; a escolha fica perto do foco e dentro do
  alcance; o jato sobe na beira da rocha, na água, e do lado do mar; o intervalo fica na faixa; os jatos se revezam.
- Captura: `tools/capture_phase123.tscn` (semente 1840: a falésia mais perto do meio da ilha principal com o jogo a 1x;
  `borrifo_0.png` a `borrifo_2.png` e `borrifo_de_perto.png`).
