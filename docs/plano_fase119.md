# Plano da Fase 119 — Poças de luz à noite

**Estado: feita em 30/10/2026**, a última do roteiro `docs/plano_fases_115_119.md` (fazenda, taverna e estaleiro, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **As poças** (`LightPoolView.pools`): debaixo de cada poste (`LampView.lamp_points`, `LAMP_RADIUS_M`), em volta de cada
  fogueira (`fire_points`, `FIRE_RADIUS_M`, alaranjada) e diante da porta de cada casa com morador (`RoadMask.doors`,
  `DOOR_OUT_M` para a rua, `DOOR_RADIUS_M`, mais fraca), um disco de luz deitado no chão e inclinado com o relevo, `LIFT_M`
  acima dele; nada no mar.
- **O shader** (`shaders/light_pool.gdshader`): soma à cena (`blend_add`, sem luz, sem profundidade, sem sombra) um disco
  mais forte no meio, na cor da instância com a força no alfa, aceso pelo global `night_light`. Não é luz de verdade: o
  OmniLight3D continua só nos postes perto da câmera (Fase 13), e o custo é o de um MultiMesh de quadrados.
- **A vista** (`GameScreen.light_pool_view`) fica escondida de dia (`SHOW_AT`) e é refeita quando os postes mudam (o
  sinal novo `LampView.rebuilt`), na obra e na demolição, e quando muda o número de casas com morador (`lit_houses`,
  conferido a cada `CHECK_S` de noite).

## Como testar

- `tests/world/test_phase119_light_pools.gd`: uma poça por poste e por fogueira, logo acima do chão e deitada; a casa vazia
  fica escura e a com morador ganha a poça diante da porta, fora dela; a vista desenha as portas acesas.
- Captura: `tools/capture_phase119.tscn` (semente 1840: uma rua calçada com casas de operários às 22h; `pocas.png`,
  `pocas_de_perto.png`, e `pocas_de_cima.png` com `sem_pocas_de_cima.png` para comparar).
