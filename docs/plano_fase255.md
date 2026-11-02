# Plano da Fase 255 — Ar limpo e tom vivo

**Estado: feita em 01/11/2026**, primeira do roteiro `docs/plano_fases_255_259.md` (cor viva), a pedido do dono ("estou achando
muito morto, gostaria de algo mais vivo, parecido com o anno"). Só a ideia do Anno, pelas capturas guardadas; nenhum número dele.

## O que entrou

- **Laboratório de cor** (`tools/color_lab.tscn`): a vila do roteiro fotografada com várias combinações de névoa, curva de tom
  (AgX, ACES, Filmic), contraste, saturação, exposição e sol, lado a lado. Duas rodadas escolheram: **manter o AgX** (as luzes
  da noite, os fogos e a cor de época já foram afinados nele), com mais contraste, saturação e exposição, e o sol quente.
- **Cor viva** (`GraphicsQuality.apply_to_environment`, `GameConfig.vivid_exposure` 1,12, `vivid_agx_contrast` 1,4,
  `vivid_saturation` 1,25): o padrão com a "Cor de época" desligada. Com ela ligada, segue o LUT e o AgX da Fase 37.
- **Ar limpo**: a névoa volumétrica do alto e do ultra de 0,0018 para 0,0004 e a do domo do Sky3D de 0,0002 para 0,0001; a
  neblina e a chuva do clima continuam somando por cima.
- **Sol quente** (`GameConfig.sun_light_color` (1; 0,95; 0,86), `sun_light_energy` 1,15, postos no Sky3D pelo `SkyAdapter`): o
  Sky3D mistura a cor com a do horizonte pela altura do sol, então o fim de tarde segue laranja.

## Como testar

- `tests/world/test_phase255_vivid.gd`: névoa mais fina, a cor viva como padrão, a cor de época com a gradação dela e o sol
  quente no Sky3D. O `tests/world/test_phase37_light.gd` passou a esperar a cor viva com a cor de época desligada.
- Capturas: `tools/capture_phase255.tscn -- <pasta>` (a vila de cima e de perto, os campos, a enseada e a ilha; as mesmas vistas
  em todo o ciclo). Antes e depois em `F:\ferramentas\capturas\fase255\`.

## Fica para as próximas fases

As copas quase pretas (Fase 256) e a grama que, saturada, puxa para o amarelo-limão (Fase 257).
