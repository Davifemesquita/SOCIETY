# Plano da Fase 110 — Brilho do sol no mar

**Estado: feita em 30/10/2026**, primeira do roteiro `docs/plano_fases_110_114.md` (sol, trópico e avenida, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **A direção do sol** (global de shader `sun_direction`, no `project.godot`): a `GameScreen` a atualiza a cada quadro com o
  sol da tela (`SkyAdapter.sun()`, o do Sky3D ou o simples).
- **A cintilação** (`shaders/water.gdshader`, grupo `Glints`): o reflexo da vista contra a direção do sol (no espaço da
  câmera) num lobo de `glint_sharpness`, vezes um ponto redondo por célula de `glint_cell_m` que acende numa fração
  `glint_share` das vezes e troca `glint_rate` vezes por segundo (cada célula desencontrada), somado à emissão. Só no mar
  aberto (a partir de `glint_open_m` da costa, pelo campo da costa da Fase 35), some com a distância (`glint_fade_m`), de
  noite e na água poluída.
- Fisicamente o brilho só aparece com a câmera virada para o sol; de costas para ele o mar fica como antes.

## No caminho

- Com o lobo largo o mar inteiro saía salpicado de quadradinhos (a célula inteira acendia). O lobo estreitou e o brilho
  virou um ponto redondo no meio da célula.

## Como testar

- `tests/presentation/test_phase110_sun_glints.gd`: o shader da água compila com os uniformes da cintilação (com janela) e o
  global do sol está no projeto.
- Captura: `tools/capture_phase110.tscn` (semente 1840: o mar ao lado do farol às 9h e às 16h, a câmera virada para cada
  lado; o brilho aparece em `mar_09h_3.png` e `mar_16h_1.png`, de frente para o sol).
