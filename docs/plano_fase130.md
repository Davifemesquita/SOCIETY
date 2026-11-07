# Plano da Fase 130 — Telhado de sapê

**Estado: feita em 31/10/2026**, primeira do roteiro `docs/plano_fases_130_134.md` (sapê, bueiro e ardósia, olhando o Anno
do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem** (`BuildingView.thatched`): as casas da classe com o quintal cercado (`HouseTrim.YARD`, os camponeses). A
  `BuildingView` põe o parâmetro de instância `thatch` no corpo da casa; os prédios de produção de madeira, que também usam
  o telhado de tábuas, ficam como eram.
- **O sapê** (`shaders/building_kit.gdshader`, `thatch_shade`): nas águas do telhado, no lugar das telhas da Fase 95,
  fiadas grossas de `thatch_course_m` com a borda de baixo ondulada e mais escura, os fios de palha descendo a água (ruído
  fino esticado, `thatch_strand_m`) e o tom de palha velha (`thatch_color` puxando para `thatch_old`); de longe só o tom; a
  capa da cumeeira, o beiral e o telhado plano ficam em palha escura e lisa. Ruído com hash sem seno (a lição da Fase 125).
- **No caminho**: as casas de telhado plano dos camponeses ganham o mesmo tom de palha, liso.

## Como testar

- `tests/presentation/test_phase130_thatch.gd`: só as casas dos camponeses têm sapê (as outras classes e o lenhador, de
  madeira, não); com tela, o shader do kit compila com os parâmetros novos.
- Captura: `tools/capture_phase130.tscn` (ilha plana: uma rua de casas dos camponeses e outra dos operários para comparar;
  `sape.png`, `sape_de_perto.png` e `sape_de_tras.png`).
